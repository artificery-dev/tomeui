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
    this.showSidebar = 'Show sidebar',
    this.hideSidebar = 'Hide sidebar',
    this.more = 'More',
    this.minimizeWindow = 'Minimize',
    this.maximizeWindow = 'Maximize',
    this.restoreWindow = 'Restore',
    this.closeWindow = 'Close window',
    this.back = 'Back',
    this.commands = 'Search commands',
    this.noMatches = 'No matches',
    this.dismiss = 'Dismiss',
    this.loading = 'Loading',
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

  /// What a `ScaffoldSidebarToggle` announces itself as, either way
  /// round. The button is a bare glyph, so this is the only name a
  /// screen reader has for it.
  final String showSidebar;
  final String hideSidebar;

  /// What a `Dock` calls the destinations it hadn't room for.
  final String more;

  /// What a `TitleBar`'s window buttons announce themselves as. Bare
  /// glyphs, so this is the only name a screen reader has for them.
  final String minimizeWindow;
  final String maximizeWindow;
  final String restoreWindow;
  final String closeWindow;

  /// What a `BackButton` announces itself as — a bare chevron otherwise.
  final String back;

  /// The `CommandPalette`'s prompt, and what it says when nothing matches.
  final String commands;
  final String noMatches;

  /// What a `Toast`'s or a `Callout`'s close button announces itself as.
  final String dismiss;

  /// What a `Progress` or a `Skeleton` says it is doing, for a screen
  /// reader that can't see it doing it.
  final String loading;

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
    String? showSidebar,
    String? hideSidebar,
    String? more,
    String? minimizeWindow,
    String? maximizeWindow,
    String? restoreWindow,
    String? closeWindow,
    String? back,
    String? commands,
    String? noMatches,
    String? dismiss,
    String? loading,
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
    showSidebar: showSidebar ?? this.showSidebar,
    hideSidebar: hideSidebar ?? this.hideSidebar,
    more: more ?? this.more,
    minimizeWindow: minimizeWindow ?? this.minimizeWindow,
    maximizeWindow: maximizeWindow ?? this.maximizeWindow,
    restoreWindow: restoreWindow ?? this.restoreWindow,
    closeWindow: closeWindow ?? this.closeWindow,
    back: back ?? this.back,
    commands: commands ?? this.commands,
    noMatches: noMatches ?? this.noMatches,
    dismiss: dismiss ?? this.dismiss,
    loading: loading ?? this.loading,
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
      other.copied == copied &&
      other.showSidebar == showSidebar &&
      other.hideSidebar == hideSidebar &&
      other.more == more &&
      other.minimizeWindow == minimizeWindow &&
      other.maximizeWindow == maximizeWindow &&
      other.restoreWindow == restoreWindow &&
      other.closeWindow == closeWindow &&
      other.back == back &&
      other.commands == commands &&
      other.noMatches == noMatches &&
      other.dismiss == dismiss &&
      other.loading == loading;

  // Past twenty, `Object.hash` runs out of parameters, and the set only
  // grows as widgets learn new things to say.
  @override
  int get hashCode => Object.hashAll([
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
    showSidebar,
    hideSidebar,
    more,
    minimizeWindow,
    maximizeWindow,
    restoreWindow,
    closeWindow,
    back,
    commands,
    noMatches,
    dismiss,
    loading,
  ]);
}
