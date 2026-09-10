"""Release automation tests: no network access or real uploads."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import Mock, patch
from urllib.error import HTTPError

import release


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for package, directory in release.PACKAGES.items():
            path = self.root / directory
            path.mkdir(exist_ok=True)
            (path / "pubspec.yaml").write_text(f"name: {package}\nversion: 0.1.0\n")
            (path / "CHANGELOG.md").write_text("# Changelog\n\n## 0.1.0\n\n- Release.\n")

    def bump(self, package, version):
        path = self.root / release.PACKAGES[package]
        (path / "pubspec.yaml").write_text(f"name: {package}\nversion: {version}\n")
        (path / "CHANGELOG.md").write_text(f"## {version}\n\n- Release.\n")

    def test_existing_versions_are_skipped(self):
        self.assertEqual(release.release_plan(self.root, lambda _: {"0.1.0"}), [])

    def test_pending_releases_preserve_dependency_order(self):
        for package in release.PACKAGES:
            self.bump(package, "0.1.1")
        plan = release.release_plan(self.root, lambda _: {"0.1.0"})
        self.assertEqual(plan, [{"version": "0.1.1", "tag": "v0.1.1", "packages": list(release.PACKAGES)}])

    def test_mismatched_versions_fail_before_network_access(self):
        self.bump("tomeui_clickwheel", "0.1.1")
        fetch = Mock()
        with self.assertRaisesRegex(ValueError, "same version"):
            release.release_plan(self.root, fetch)
        fetch.assert_not_called()

    def test_partial_release_retains_shared_tag(self):
        plan = release.release_plan(self.root, lambda p: {"0.1.0"} if p == "tomeui" else {"0.0.1"})
        self.assertEqual(plan, [{"version": "0.1.0", "tag": "v0.1.0", "packages": ["tomeui_desktop", "tomeui_clickwheel"]}])

    def test_numeric_version_order(self):
        for package in release.PACKAGES:
            self.bump(package, "0.10.0")
        self.assertEqual(release.release_plan(self.root, lambda _: {"0.9.0"})[0]["version"], "0.10.0")

    def test_downgrade_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "older"):
            release.release_plan(self.root, lambda _: {"0.2.0"})

    def test_prerelease_or_malformed_version_is_rejected(self):
        for value in ["0.1.1-dev.1", "v0.1.0", "01.0.0", "1.0", "1.0.0+1", "$(echo bad)"]:
            with self.subTest(version=value), self.assertRaises(ValueError):
                release.stable_version(value)

    def test_quoted_pubspec_values_and_comments(self):
        text = "name: 'tomeui'\nversion: \"0.1.1\" # release\n"
        self.assertEqual(release.scalar(text, "version"), "0.1.1")
        self.assertEqual(release.scalar(text, "name"), "tomeui")

    def test_duplicate_or_indented_version_is_rejected(self):
        for text in ["version: 0.1.0\nversion: 0.1.1\n", "  version: 0.1.0\n"]:
            with self.assertRaises(ValueError):
                release.scalar(text, "version")

    def test_missing_release_notes_are_rejected(self):
        (self.root / "CHANGELOG.md").write_text("## Unreleased\n")
        with self.assertRaisesRegex(ValueError, "CHANGELOG"):
            release.release_plan(self.root, lambda _: {"0.0.1"})

    def test_wrong_package_identity_is_rejected(self):
        (self.root / "pubspec.yaml").write_text("name: other\nversion: 0.1.0\n")
        with self.assertRaisesRegex(ValueError, "Unexpected package"):
            release.package_version("tomeui", self.root)

    def test_network_failure_does_not_become_a_release(self):
        fetch = Mock(side_effect=HTTPError("https://pub.dev", 503, "Unavailable", {}, None))
        with self.assertRaises(HTTPError):
            release.release_plan(self.root, fetch)

    def test_new_package_requires_manual_bootstrap(self):
        with patch.object(release, "request_json", side_effect=HTTPError("https://pub.dev", 404, "Not found", {}, None)):
            with self.assertRaisesRegex(ValueError, "first version manually"):
                release.published_versions("tomeui")

    def test_tag_must_match_manifest(self):
        self.assertEqual(release.resolve_tag("v0.1.0", self.root), "0.1.0")
        for tag in ["main", "tomeui-v0.1.0", "v0.1.1", "tomeui_playground-v1.0.0", "v0.1.0/evil"]:
            with self.subTest(tag=tag), self.assertRaises(ValueError):
                release.resolve_tag(tag, self.root)

    def test_dispatch_creates_tag_then_explicitly_starts_workflow(self):
        api = Mock(side_effect=[HTTPError("https://github.com", 404, "Not found", {}, None), {}, None])
        release.dispatch_release({"package": "tomeui", "version": "0.1.1", "tag": "v0.1.1"}, "abc", api)
        self.assertEqual(api.call_args_list[1].kwargs["body"], {"ref": "refs/tags/v0.1.1", "sha": "abc"})
        self.assertEqual(api.call_args_list[2].kwargs["body"], {"ref": "v0.1.1"})

    def test_dispatch_reuses_matching_tag_for_retry(self):
        api = Mock(side_effect=[{"object": {"type": "commit", "sha": "abc"}}, None])
        release.dispatch_release({"package": "tomeui", "version": "0.1.1", "tag": "v0.1.1"}, "abc", api)
        self.assertEqual(api.call_count, 2)
        self.assertIn("dispatches", api.call_args.args[0])

    def test_dispatch_rejects_tag_collision_without_mutating(self):
        api = Mock(return_value={"object": {"type": "commit", "sha": "different"}})
        with self.assertRaisesRegex(ValueError, "Refusing to move"):
            release.dispatch_release({"package": "tomeui", "version": "0.1.1", "tag": "v0.1.1"}, "abc", api)
        self.assertEqual(api.call_count, 1)

    def test_dispatch_handles_annotated_tags(self):
        api = Mock(side_effect=[{"object": {"type": "tag", "sha": "annotation"}}, {"object": {"type": "commit", "sha": "abc"}}, None])
        release.dispatch_release({"package": "tomeui", "version": "0.1.1", "tag": "v0.1.1"}, "abc", api)
        self.assertEqual(api.call_args_list[1].args[0], "git/tags/annotation")

    def test_waits_for_dependency_propagation(self):
        fetch = Mock(side_effect=[{"0.1.0"}, {"0.1.0", "0.1.1"}])
        sleep = Mock()
        release.wait_for_version("tomeui", "0.1.1", fetch=fetch, sleep=sleep)
        sleep.assert_called_once_with(10)

    def test_dependency_wait_is_bounded(self):
        with self.assertRaises(TimeoutError):
            release.wait_for_version("tomeui", "0.1.1", timeout=0, fetch=lambda _: {"0.1.0"})

    def test_multiline_workflow_output_is_rejected(self):
        with self.assertRaises(ValueError):
            release.output("package", "tomeui\npending=true")

    def test_stage_uses_committed_files_and_isolates_resolution(self):
        for args in [["init", "-q"], ["add", "."], ["-c", "user.name=Test", "-c", "user.email=test@example.com", "commit", "-qm", "Fixture"]]:
            subprocess.run(["git", *args], cwd=self.root, check=True)
        self.bump("tomeui_desktop", "0.9.0")
        with patch.dict(os.environ, {"RUNNER_TEMP": str(self.root)}):
            staged = release.stage_package("tomeui_desktop", self.root)
        self.assertIn("version: 0.1.0", (staged / "pubspec.yaml").read_text())
        self.assertEqual((staged / "pubspec_overrides.yaml").read_text(), "resolution:\nworkspace: []\n")
        self.assertFalse((staged.parent / ".git").exists())

    def test_dependency_resolution_retries_propagation_failure(self):
        run = Mock(side_effect=[subprocess.CalledProcessError(1, "pub get"), None])
        sleep = Mock()
        release.resolve_dependencies(self.root, run=run, sleep=sleep)
        self.assertEqual(run.call_count, 2)
        sleep.assert_called_once_with(10)
        self.assertEqual(run.call_args.args[0], ["flutter", "pub", "get"])
        self.assertNotIn("PUB_TOKEN", run.call_args.kwargs["env"])

    def test_only_the_upload_carries_the_pub_credential(self):
        directory = self.root / "stage"
        directory.mkdir()
        calls = []
        def run(command, **kwargs):
            calls.append((command[-1], kwargs.get("env")))
        with patch.dict(os.environ, {"PUB_TOKEN": "secret"}):
            release.publish_release(self.root, lambda p: {"0.0.1"} if p == "tomeui" else {"0.1.0"}, Mock(return_value=directory), run, Mock())
        self.assertEqual([c[0] for c in calls], ["get", "--dry-run", "--force"])
        self.assertNotIn("PUB_TOKEN", calls[0][1])
        self.assertNotIn("PUB_TOKEN", calls[1][1])
        self.assertIsNone(calls[2][1])

    def test_anonymous_environment_hides_the_pub_token_store(self):
        with patch.dict(os.environ, {"PUB_TOKEN": "secret", "XDG_CONFIG_HOME": "/home/runner/.config"}):
            env = release.unauthenticated_environment()
        self.assertNotIn("PUB_TOKEN", env)
        config = Path(env["XDG_CONFIG_HOME"])
        self.assertNotEqual(str(config), "/home/runner/.config")
        self.assertTrue(config.is_dir())
        self.assertEqual(list(config.iterdir()), [])

    def test_dependency_resolution_failure_is_bounded(self):
        run = Mock(side_effect=subprocess.CalledProcessError(1, "pub get"))
        sleep = Mock()
        with self.assertRaises(subprocess.CalledProcessError):
            release.resolve_dependencies(self.root, run=run, timeout=0, sleep=sleep)
        run.assert_called_once()
        sleep.assert_not_called()

    def test_publication_order_waits_and_skips_existing_packages(self):
        events = []
        def stage(package, root):
            directory = self.root / ("stage-" + package)
            directory.mkdir()
            return directory if package == "tomeui" else directory / release.PACKAGES[package]
        def run(command, **kwargs):
            events.append(command[-1])
        def wait(package, version):
            events.append(package)
        release.publish_release(self.root, lambda p: {"0.1.0"} if p == "tomeui" else {"0.0.1"}, stage, run, wait)
        self.assertEqual(events, ["get", "--dry-run", "--force", "tomeui_desktop", "get", "--dry-run", "--force", "tomeui_clickwheel"])
        self.assertFalse(list(self.root.glob("stage-*")))

    def test_failed_upload_stops_release_and_cleans_staging(self):
        directory = self.root / "stage"
        directory.mkdir()
        stage = Mock(return_value=directory)
        wait = Mock()
        run = Mock(side_effect=[None, None, subprocess.CalledProcessError(1, "publish")])
        with self.assertRaises(subprocess.CalledProcessError):
            release.publish_release(self.root, lambda _: {"0.0.1"}, stage, run, wait)
        stage.assert_called_once_with("tomeui", self.root)
        wait.assert_not_called()
        self.assertFalse(directory.exists())

    def test_workflow_outputs_are_written(self):
        output = self.root / "output"
        with patch.dict(os.environ, {"GITHUB_OUTPUT": str(output)}):
            release.output("pending", "false")
        self.assertEqual(output.read_text(), "pending=false\n")

    def test_manual_publish_on_a_branch_is_rejected(self):
        env = {"GITHUB_REPOSITORY": release.REPOSITORY, "GITHUB_REF_TYPE": "branch"}
        with patch.dict(os.environ, env), patch("sys.argv", ["release.py", "validate-tag"]):
            with patch.object(release.subprocess, "run") as run:
                with self.assertRaisesRegex(ValueError, "version tag"):
                    release.main()
                run.assert_not_called()

    def test_tag_outside_main_is_rejected_before_publication_lookup(self):
        env = {"GITHUB_REPOSITORY": release.REPOSITORY, "GITHUB_REF_TYPE": "tag"}
        with patch.dict(os.environ, env), patch("sys.argv", ["release.py", "validate-tag"]):
            with patch.object(release.subprocess, "run", side_effect=subprocess.CalledProcessError(1, "git")):
                with patch.object(release, "published_versions") as fetch:
                    with self.assertRaises(subprocess.CalledProcessError):
                        release.main()
                    fetch.assert_not_called()

    def test_stale_main_run_does_not_create_tags(self):
        env = {"GITHUB_REPOSITORY": release.REPOSITORY, "GITHUB_REF": "refs/heads/main", "GITHUB_SHA": "old"}
        with patch.dict(os.environ, env), patch("sys.argv", ["release.py", "dispatch"]):
            with patch.object(release.subprocess, "check_output", return_value="old\n"):
                with patch.object(release, "github", return_value={"object": {"sha": "new"}}):
                    with patch.object(release, "dispatch_release") as dispatch:
                        release.main()
                        dispatch.assert_not_called()

    def test_github_api_failure_does_not_create_tags(self):
        api = Mock(side_effect=HTTPError("https://github.com", 403, "Forbidden", {}, None))
        with self.assertRaises(HTTPError):
            release.dispatch_release({"package": "tomeui", "version": "0.1.1", "tag": "v0.1.1"}, "abc", api)
        self.assertEqual(api.call_count, 1)


if __name__ == "__main__":
    unittest.main()
