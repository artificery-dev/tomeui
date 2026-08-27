import 'package:flutter/services.dart';
import 'package:tomeui/tomeui.dart';

import '../foundation/list_walk.dart';
import '../foundation/overlay_dress.dart';

/// One thing a [CommandPalette] can do.
class Command {
  const Command({
    required this.name,
    required this.onInvoke,
    this.icon,
    this.hint,
    this.section,
    this.keywords = const [],
    this.enabled = true,
  });

  /// What the command is called — plain text, because the palette matches
  /// against it.
  final String name;

  /// Running it. The palette closes first, so a command is free to push a
  /// route or open a dialog of its own.
  final VoidCallback onInvoke;

  final IconData? icon;

  /// The keystroke that does this without the palette — `⌘S`.
  final String? hint;

  /// What it's one of: Edit, View, Go. Shown as a section label above the
  /// first command in the run.
  final String? section;

  /// Other words that should find it — an old name, a synonym, the thing
  /// people actually call it.
  final List<String> keywords;

  final bool enabled;
}

/// Everything the app can do, one keystroke away.
///
/// A field over a list: type, and the commands narrow to what matches;
/// the arrows walk them, Enter runs the one you're on, Escape gives up —
/// the last of those belonging to [CommandPaletteRoute], which is what
/// [showCommandPalette] puts it on.
/// [showCommandPalette] is the usual way in — bound to ⌘K or ⌃K — and the
/// widget is public for a shell that would rather place it itself.
///
/// ```dart
/// CallbackShortcuts(
///   bindings: {
///     const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
///         showCommandPalette(context, commands: commands),
///   },
///   child: ...,
/// )
/// ```
///
/// Matching is on the command's [Command.name] and its
/// [Command.keywords]: what starts with the query comes before what merely
/// contains it, and everything else falls away.
class CommandPalette extends StatefulWidget {
  const CommandPalette({
    required this.commands,
    this.onDismiss,
    this.placeholder,
    this.style,
    super.key,
  });

  final List<Command> commands;

  /// Escape, or a tap outside. [showCommandPalette] passes the closing.
  final VoidCallback? onDismiss;

  /// What the empty field says. Null takes the theme's [Labels.commands].
  final String? placeholder;

  /// The style to paint, bypassing the theme.
  final CommandPaletteStyle? style;

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// The commands worth showing, best match first. An empty query shows
  /// everything, in the order it was given — the palette is a menu until
  /// it's a search.
  List<Command> get _matches {
    final query = _query.text.trim().toLowerCase();
    if (query.isEmpty) return widget.commands;

    final leading = <Command>[];
    final rest = <Command>[];
    for (final command in widget.commands) {
      final name = command.name.toLowerCase();
      if (name.startsWith(query)) {
        leading.add(command);
      } else if (name.contains(query) ||
          command.keywords.any((word) => word.toLowerCase().contains(query))) {
        rest.add(command);
      }
    }
    return [...leading, ...rest];
  }

  void _invoke(Command command) {
    if (!command.enabled) return;
    // Out of the way first: a command that opens something of its own
    // shouldn't have to do it behind the palette.
    widget.onDismiss?.call();
    command.onInvoke();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = widget.style ?? theme.widgets.commandPalette.resolve();
    final matches = _matches;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: style.width,
        maxHeight: style.maxHeight,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: style.surface.radius,
          boxShadow: style.shadow,
        ),
        child: Surface.custom(
          style: style.surface,
          child: ListWalk(
            length: matches.length,
            enabledAt: (index) => matches[index].enabled,
            onActivate: (index) => _invoke(matches[index]),
            // The field has the keyboard; the walk only wants what the
            // field doesn't use — the arrows and Enter.
            autofocus: false,
            builder: (context, highlight, highlightTo) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _query,
                  autofocus: true,
                  style: style.field,
                  leading: Icon(theme.icons.search),
                  placeholder: Text(
                    widget.placeholder ?? theme.labels.commands,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                Divider(style: DividerStyle(color: style.menu.separator)),
                if (matches.isEmpty)
                  Padding(
                    padding: style.padding,
                    child: DefaultTextStyle.merge(
                      style: style.emptyStyle,
                      child: Text(theme.labels.noMatches),
                    ),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: style.padding,
                      children: [
                        for (final (index, command) in matches.indexed)
                          _Row(
                            command: command,
                            style: style,
                            // A section label goes above the first command
                            // of each run, and nowhere else.
                            section:
                                command.section != null &&
                                    (index == 0 ||
                                        matches[index - 1].section !=
                                            command.section)
                                ? command.section
                                : null,
                            highlighted: index == highlight,
                            onHover: () => highlightTo(index),
                            onTap: () => _invoke(command),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.command,
    required this.style,
    required this.section,
    required this.highlighted,
    required this.onHover,
    required this.onTap,
  });

  final Command command;
  final CommandPaletteStyle style;
  final String? section;
  final bool highlighted;
  final VoidCallback onHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final menu = style.menu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (section != null)
          Padding(
            padding: menu.itemPadding,
            child: DefaultTextStyle.merge(
              style: style.hintStyle,
              child: Text(section!),
            ),
          ),
        ListWalkRow(
          enabled: command.enabled,
          background: highlighted ? menu.highlight : null,
          radius: menu.itemRadius,
          padding: menu.itemPadding,
          onHover: onHover,
          onTap: onTap,
          child: Row(
            children: [
              if (command.icon != null) ...[
                Icon(command.icon),
                SizedBox(width: menu.itemGap),
              ],
              Expanded(
                child: Text(
                  command.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (command.hint != null) ...[
                SizedBox(width: menu.itemGap),
                DefaultTextStyle.merge(
                  style: menu.trailingStyle,
                  child: Text(command.hint!),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The route a [CommandPalette] arrives on: near the top of the window,
/// over a scrim.
///
/// A route for the same reasons a [DialogRoute] is one — the keyboard
/// trapped inside it, the focus handed back on the way out, the back
/// gesture understood.
class CommandPaletteRoute<T> extends PopupRoute<T> {
  CommandPaletteRoute({
    required this.builder,
    required Theme theme,
    CommandPaletteStyle? style,
    super.settings,
  }) : _theme = theme,
       _motion = theme.motion,
       _style = style ?? theme.widgets.commandPalette.resolve();

  final WidgetBuilder builder;

  /// The theme in scope where the palette was summoned — see
  /// [dressForOverlay].
  final Theme _theme;

  final Motion _motion;
  final CommandPaletteStyle _style;

  @override
  bool get barrierDismissible => true;

  @override
  Color get barrierColor => _style.scrim;

  @override
  String get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => _motion.fast;

  @override
  bool get opaque => false;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => dressForOverlay(
    theme: _theme,
    child: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: _style.topInset),
          child: Align(
            alignment: Alignment.topCenter,
            child: Builder(builder: builder),
          ),
        ),
      ),
    ),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final eased = CurvedAnimation(
      parent: animation,
      curve: _motion.enter,
      // Flipped: see the note on `SheetRoute`.
      reverseCurve: _motion.exit.flipped,
    );
    return FadeTransition(
      opacity: eased,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, -0.02),
          end: Offset.zero,
        ).animate(eased),
        child: child,
      ),
    );
  }
}

/// Puts a [CommandPalette] over the page until something dismisses it.
///
/// The future completes when the palette closes — by Escape, by a tap on
/// the scrim, or by a command being run. The command runs *after* the
/// palette is gone, so what it opens isn't opened behind it.
Future<void> showCommandPalette(
  BuildContext context, {
  required List<Command> commands,
  String? placeholder,
  CommandPaletteStyle? style,
}) {
  final theme = ThemeProvider.maybeOf(context) ?? const Theme();
  final navigator = Navigator.of(context, rootNavigator: true);
  return navigator.push(
    CommandPaletteRoute<void>(
      theme: theme,
      style: style,
      builder: (context) => CommandPalette(
        commands: commands,
        placeholder: placeholder,
        style: style,
        onDismiss: () => Navigator.of(context).maybePop(),
      ),
    ),
  );
}
