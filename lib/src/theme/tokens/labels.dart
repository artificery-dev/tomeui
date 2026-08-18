import 'package:flutter/widgets.dart';

/// The words the toolkit itself says.
///
/// Every string a Tome widget puts on screen without being handed one — the
/// selection menu's verbs, the copy affordance's confirmation. They live
/// here for the same reason [Icons] does: a widget asks for *meaning* and
/// the theme decides what that looks like, so an app that speaks another
/// language swaps the set instead of passing strings down through every
/// field it builds.
///
/// The defaults are English, because a toolkit that ships translations ships
/// a translation policy with them. An app with localizations of its own
/// builds a theme per locale:
///
/// ```dart
/// theme.copyWith(labels: Labels(cut: l10n.cut, copy: l10n.copy, ...))
/// ```
@immutable
class Labels {
  const Labels({
    this.cut = 'Cut',
    this.copy = 'Copy',
    this.paste = 'Paste',
    this.selectAll = 'Select all',
    this.delete = 'Delete',
    this.lookUp = 'Look up',
    this.searchWeb = 'Search web',
    this.share = 'Share',
    this.scanText = 'Scan text',
    this.copied = 'Copied',
  });

  // The selection menu, in the order it usually reads.
  final String cut;
  final String copy;
  final String paste;
  final String selectAll;
  final String delete;

  /// Ask the platform what the selected words mean.
  final String lookUp;

  final String searchWeb;
  final String share;

  /// Live Text: pull text off the camera into the field.
  final String scanText;

  /// What a copy affordance says once it has copied.
  final String copied;

  Labels copyWith({
    String? cut,
    String? copy,
    String? paste,
    String? selectAll,
    String? delete,
    String? lookUp,
    String? searchWeb,
    String? share,
    String? scanText,
    String? copied,
  }) => Labels(
    cut: cut ?? this.cut,
    copy: copy ?? this.copy,
    paste: paste ?? this.paste,
    selectAll: selectAll ?? this.selectAll,
    delete: delete ?? this.delete,
    lookUp: lookUp ?? this.lookUp,
    searchWeb: searchWeb ?? this.searchWeb,
    share: share ?? this.share,
    scanText: scanText ?? this.scanText,
    copied: copied ?? this.copied,
  );

  @override
  bool operator ==(Object other) =>
      other is Labels &&
      other.cut == cut &&
      other.copy == copy &&
      other.paste == paste &&
      other.selectAll == selectAll &&
      other.delete == delete &&
      other.lookUp == lookUp &&
      other.searchWeb == searchWeb &&
      other.share == share &&
      other.scanText == scanText &&
      other.copied == copied;

  @override
  int get hashCode => Object.hash(
    cut,
    copy,
    paste,
    selectAll,
    delete,
    lookUp,
    searchWeb,
    share,
    scanText,
    copied,
  );
}
