#!/usr/bin/env python3
"""Tag, stage, and verify the three stable pub.dev package releases.

Uses only Python's standard library. Network errors stop releases; an existing
version is never overwritten, and a version tag is never moved.
"""

from __future__ import annotations

import argparse
import io
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tarfile
import tempfile
import time
from urllib.error import HTTPError
from urllib.parse import quote
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent.parent
REPOSITORY = "artificery-dev/tomeui"
PACKAGES = {
    "tomeui": ".",
    "tomeui_desktop": "desktop",
    "tomeui_clickwheel": "clickwheel",
}
STABLE_VERSION = re.compile(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)")


def stable_version(value: str) -> tuple[int, int, int]:
    match = STABLE_VERSION.fullmatch(value)
    if not match:
        raise ValueError(f"Expected a stable major.minor.patch version, got {value!r}")
    return tuple(int(part) for part in match.groups())


def scalar(text: str, key: str) -> str:
    """Read an unindented pubspec scalar; reject duplicates and complex YAML."""
    matches = re.findall(rf"^{re.escape(key)}:[ \t]*(.*)$", text, re.MULTILINE)
    if len(matches) != 1:
        raise ValueError(f"Expected exactly one top-level {key} in pubspec.yaml")
    value = matches[0].split(" #", 1)[0].strip()
    if value.startswith(("'", '"')) and value[-1:] == value[:1]:
        value = value[1:-1]
    if not value or re.search(r"\s", value):
        raise ValueError(f"Expected a simple {key} in pubspec.yaml")
    return value


def package_version(package: str, root: Path = ROOT) -> str:
    pubspec = (root / PACKAGES[package] / "pubspec.yaml").read_text()
    if scalar(pubspec, "name") != package:
        raise ValueError(f"Unexpected package name in {PACKAGES[package]}/pubspec.yaml")
    version = scalar(pubspec, "version")
    stable_version(version)
    return version


def require_changelog(package: str, version: str, root: Path = ROOT) -> None:
    changelog = (root / PACKAGES[package] / "CHANGELOG.md").read_text()
    if not re.search(rf"^##\s+{re.escape(version)}(?:\s|$)", changelog, re.MULTILINE):
        raise ValueError(f"{package}: add a CHANGELOG.md section for {version}")


def request_json(url: str, *, method: str = "GET", body=None, token=None):
    headers = {"Accept": "application/json", "User-Agent": "tomeui-release"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = None
    if body is not None:
        data = json.dumps(body).encode()
        headers["Content-Type"] = "application/json"
    request = Request(url, data=data, headers=headers, method=method)
    with urlopen(request, timeout=30) as response:
        data = response.read()
        return json.loads(data) if data else None


def published_versions(package: str) -> set[str]:
    try:
        data = request_json(f"https://pub.dev/api/packages/{package}")
    except HTTPError as error:
        if error.code == 404:
            raise ValueError(f"{package}: publish its first version manually before enabling OIDC") from error
        raise
    return {item["version"] for item in data["versions"]}


def release_plan(root: Path = ROOT, fetch=published_versions) -> list[dict[str, str]]:
    pending = []
    for package in PACKAGES:
        version = package_version(package, root)
        require_changelog(package, version, root)
        existing = fetch(package)
        if version in existing:
            continue
        stable = [stable_version(v) for v in existing if STABLE_VERSION.fullmatch(v)]
        if stable and stable_version(version) <= max(stable):
            raise ValueError(f"{package}: {version} is older than its latest stable release")
        pending.append({"package": package, "version": version, "tag": f"{package}-v{version}"})
    return pending


def github(path: str, *, method="GET", body=None):
    token = os.environ.get("GH_TOKEN")
    if not token:
        raise ValueError("GH_TOKEN is required for GitHub release dispatch")
    return request_json(
        f"https://api.github.com/repos/{REPOSITORY}/{path}",
        method=method, body=body, token=token,
    )


def dispatch_release(release: dict[str, str], sha: str, api=github) -> None:
    tag = release["tag"]
    try:
        existing = api(f"git/ref/tags/{quote(tag, safe='')}")
    except HTTPError as error:
        if error.code != 404:
            raise
        api("git/refs", method="POST", body={"ref": f"refs/tags/{tag}", "sha": sha})
    else:
        target = existing["object"]
        # Resolve annotated tags as well as the lightweight tags CI creates.
        for _ in range(10):
            if target["type"] != "tag":
                break
            target = api(f"git/tags/{target['sha']}")["object"]
        if target["type"] != "commit" or target["sha"] != sha:
            raise ValueError(f"Refusing to move {tag}; it already points to a different commit")
    api("actions/workflows/publish.yml/dispatches", method="POST", body={"ref": tag})
    print(f"Dispatched {release['package']} {release['version']} at {sha}", flush=True)


def output(key: str, value: str) -> None:
    if "\n" in value or "\r" in value:
        raise ValueError("Multiline workflow outputs are not supported")
    print(f"{key}={value}", flush=True)
    if path := os.environ.get("GITHUB_OUTPUT"):
        with open(path, "a") as stream:
            stream.write(f"{key}={value}\n")


def resolve_tag(tag: str, root: Path = ROOT) -> tuple[str, str]:
    for package in PACKAGES:
        prefix = f"{package}-v"
        if tag.startswith(prefix):
            version = tag[len(prefix):]
            stable_version(version)
            if package_version(package, root) != version:
                raise ValueError(f"Tag {tag} does not match {package}'s pubspec version")
            require_changelog(package, version, root)
            return package, version
    raise ValueError(f"Not a TomeUI package release tag: {tag!r}")


def wait_for_version(package: str, version: str, *, timeout=600, fetch=published_versions,
                     sleep=time.sleep, now=time.monotonic) -> None:
    deadline = now() + timeout
    while True:
        if version in fetch(package):
            print(f"Available on pub.dev: {package} {version}", flush=True)
            return
        if now() >= deadline:
            raise TimeoutError(f"Timed out waiting for {package} {version} on pub.dev")
        print(f"Waiting for {package} {version} on pub.dev...", flush=True)
        sleep(10)


def stage_package(package: str, root: Path = ROOT) -> Path:
    release_dir = Path(tempfile.mkdtemp(prefix="tomeui-release-", dir=os.environ.get("RUNNER_TEMP")))
    archive = subprocess.check_output(["git", "archive", "HEAD"], cwd=root)
    with tarfile.open(fileobj=io.BytesIO(archive)) as bundle:
        bundle.extractall(release_dir, filter="data")
    directory = release_dir / PACKAGES[package]
    # Validate against hosted dependencies, not sibling workspace sources. Pub
    # always excludes this override from the uploaded package archive.
    (directory / "pubspec_overrides.yaml").write_text("resolution:\nworkspace: []\n")
    return directory


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["plan", "dispatch", "validate-tag", "stage", "wait-core", "wait-version"])
    parser.add_argument("package", nargs="?", choices=PACKAGES)
    args = parser.parse_args()
    if args.command in {"stage", "wait-core", "wait-version"} and not args.package:
        parser.error("this command requires a package name")
    if args.command == "plan":
        print(json.dumps(release_plan(), indent=2))
    elif args.command == "dispatch":
        if os.environ.get("GITHUB_REPOSITORY") != REPOSITORY or os.environ.get("GITHUB_REF") != "refs/heads/main":
            raise ValueError("Release dispatch must run on this repository's main branch")
        sha = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
        if sha != os.environ.get("GITHUB_SHA"):
            raise ValueError("Checkout does not match the checked workflow commit")
        if github("git/ref/heads/main")["object"]["sha"] != sha:
            print("main has advanced; the newer CI run will dispatch releases")
            return
        pending = release_plan()
        if not pending:
            print("All package versions are already published; no releases needed")
        for release in pending:
            dispatch_release(release, sha)
    elif args.command == "validate-tag":
        if os.environ.get("GITHUB_REPOSITORY") != REPOSITORY or os.environ.get("GITHUB_REF_TYPE") != "tag":
            raise ValueError("Publishing requires a version tag in this repository")
        subprocess.run(["git", "merge-base", "--is-ancestor", "HEAD", "origin/main"], cwd=ROOT, check=True)
        package, version = resolve_tag(os.environ["GITHUB_REF_NAME"])
        output("package", package)
        output("version", version)
        output("pending", str(version not in published_versions(package)).lower())
    elif args.command == "stage":
        output("directory", str(stage_package(args.package)))
    elif args.command == "wait-core":
        if args.package != "tomeui":
            wait_for_version("tomeui", package_version("tomeui"))
    elif args.command == "wait-version":
        wait_for_version(args.package, package_version(args.package))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f"Release failed: {error}", file=sys.stderr)
        sys.exit(1)
