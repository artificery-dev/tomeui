import 'package:re_highlight/re_highlight.dart';
import 'package:tomeui/tomeui.dart';

/// The languages [CodeText.block] knows how to colour.
///
/// The registry starts **empty**, on purpose. Grammars are not small — the
/// Swift one alone is a few hundred kilobytes of generated Dart — and a
/// toolkit has no business deciding which of them every app that links it
/// pays for. An app registers what it actually shows:
///
/// ```dart
/// import 'package:re_highlight/languages/dart.dart';
/// import 'package:re_highlight/languages/json.dart';
///
/// void main() {
///   CodeSyntax.register('dart', langDart);
///   CodeSyntax.register('json', langJson);
///   runApp(const MyApp());
/// }
/// ```
///
/// A block asking for a language nobody registered isn't an error: it
/// renders as plain monospace, still numbered and still copyable. Colour is
/// the part that degrades, which is the right part.
///
/// Aliases come with the grammar — registering `javascript` answers to `js`
/// as well — because that's what the grammars themselves declare.
abstract final class CodeSyntax {
  static final Highlight _engine = Highlight();

  /// Teach the registry one language. [language] is a `re_highlight`
  /// grammar: `import 'package:re_highlight/languages/dart.dart'` gives
  /// you `langDart`.
  static void register(String name, Mode language) =>
      _engine.registerLanguage(name, language);

  /// The same, in bulk — `builtinAllLanguages` registers the lot, at the
  /// weight that implies.
  static void registerAll(Map<String, Mode> languages) =>
      _engine.registerLanguages(languages);

  static void unregister(String name) => _engine.unregisterLanguage(name);

  /// Whether a block naming [language] would come out coloured. Null and
  /// unknown names both answer false, which is how a caller can decide to
  /// say so.
  static bool knows(String? language) =>
      language != null && _engine.getLanguage(language) != null;

  /// Every name registered, aliases included.
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
