import 'package:re_highlight/languages/all.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:tomeui/tomeui.dart';

/// The languages [CodeText.block] knows how to colour.
///
/// Every grammar `re_highlight` ships is registered — the whole
/// highlight.js set, community languages included — so naming a language
/// is all a block has to do:
///
/// ```dart
/// CodeText.block(source, language: 'dart'),
/// CodeText.block(config, language: 'yml'),   // an alias, and it answers
/// ```
///
/// Aliases come with the grammars, which is how `js`, `yml`, and `sh`
/// resolve without being registered separately.
///
/// That breadth is not free: the grammars are generated Dart, a couple of
/// megabytes of it across the set, and referencing them all here means an
/// app that links Tome links the lot. It buys never having to think about
/// it, which is the trade this toolkit makes elsewhere too.
///
/// [register] adds a grammar the set doesn't have, or replaces one with
/// your own reading of it; [unregister] takes a name back out. A block
/// asking for a language nobody knows isn't an error — it renders as plain
/// monospace, still numbered and still copyable. Colour is the part that
/// degrades, which is the right part.
abstract final class CodeSyntax {
  static final Highlight _engine = Highlight()
    ..registerLanguages(builtinAllLanguages);

  /// Teach the registry one more language, or override one it has.
  /// [language] is a `re_highlight` grammar:
  /// `import 'package:re_highlight/languages/dart.dart'` gives you
  /// `langDart`.
  static void register(String name, Mode language) =>
      _engine.registerLanguage(name, language);

  /// The same, in bulk.
  static void registerAll(Map<String, Mode> languages) =>
      _engine.registerLanguages(languages);

  /// Take a name back out — for a language an app would rather not offer,
  /// or to undo a [register] in a test.
  static void unregister(String name) => _engine.unregisterLanguage(name);

  /// Whether a block naming [language] would come out coloured. Null and
  /// unknown names both answer false, which is how a caller can decide to
  /// say so.
  static bool knows(String? language) =>
      language != null && _engine.getLanguage(language) != null;

  /// Every name known, aliases included.
  static List<String> get languages => _engine.listLanguages();

  /// [code] as one span tree, each scope wearing what [syntax] says and
  /// everything else wearing [base]. Null when [language] isn't registered
  /// — the caller falls back to plain text.
  static TextSpan? highlight(
    String code, {
    required String? language,
    required TextStyle base,
    required Map<String, TextStyle> syntax,
  }) {
    if (!knows(language)) return null;
    final renderer = TextSpanRenderer(base, syntax);
    _engine.highlight(code: code, language: language!).render(renderer);
    return renderer.span;
  }
}
