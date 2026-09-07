import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tomeui/tomeui.dart';

import '../foundation/focus_ring.dart';

/// A place to type.
///
/// Built straight on [EditableText] — the widgets layer's editor — dressed
/// as a [Surface] and wired the way the rest of the toolkit is: a
/// [SemanticSwatch] in a [SurfaceVariant], a focus ring in the swatch's full
/// voice, hover, and a disabled state.
///
/// Three pieces of words come with it, because a field without them is a
/// field an app has to rebuild anyway: [label] above, [helper] below, and
/// [error] — which replaces the helper *and* turns the whole box, caret and
/// ring included, to [SemanticSwatch.error]. Between them, [leading] and
/// [trailing] hold an icon or a small button.
///
/// Uncontrolled by default: with no [controller] it keeps one of its own and
/// reports through [onChanged]. Pass a controller to own the text yourself.
///
/// ```dart
/// TextField(
///   label: const Text('Port of call'),
///   placeholder: const Text('Valparaíso'),
///   helper: const Text('Where the cargo leaves the ship.'),
///   onChanged: (value) => setState(() => port = value),
/// )
/// ```
///
/// Selection is wired end to end. A pointer selects — click, drag,
/// double-click a word — and so does the keyboard. On a touch screen the
/// selection wears [TextSelectionHandles] and a long press raises a bar of
/// verbs; on a desktop a right-click raises the same verbs as a menu. Both
/// come from one list — see [TextSelectionMenu] — and [contextMenuBuilder]
/// is where an app adds to it or replaces it.
class TextField extends StatefulWidget {
  const TextField({
    this.controller,
    this.focusNode,
    this.placeholder,
    this.label,
    this.helper,
    this.error,
    this.leading,
    this.trailing,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.inputFormatters,
    this.autofillHints,
    this.maxLines = 1,
    this.minLines,
    this.contextMenuBuilder,
    this.variant = SurfaceVariant.outline,
    this.swatch = SemanticSwatch.primary,
    this.style,
    super.key,
  });

  /// Who owns the text. Null keeps one internally.
  final TextEditingController? controller;

  /// Who owns the focus. Null keeps one internally.
  final FocusNode? focusNode;

  /// What stands in the box while it's empty.
  final Widget? placeholder;

  /// The words above the box.
  final Widget? label;

  /// The words below it: what to type, or why.
  final Widget? helper;

  /// What's wrong. Takes the place of [helper] and dresses the whole field
  /// in [SemanticSwatch.error] — one thing to set, not two.
  final Widget? error;

  /// An icon at the start of the box, and one at the end. A trailing
  /// [Button] is how a field grows a clear or reveal affordance.
  final Widget? leading;
  final Widget? trailing;

  final ValueChanged<String>? onChanged;

  /// The keyboard's done or enter key.
  final ValueChanged<String>? onSubmitted;

  /// False dims the field, ignores the pointer, and takes it out of the
  /// focus order.
  final bool enabled;

  /// Shown and selectable, but not editable.
  final bool readOnly;

  final bool obscureText;
  final bool autofocus;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;

  /// One line by default. More than one — or null for no limit — grows the
  /// box instead of scrolling the text through it.
  final int? maxLines;
  final int? minLines;

  /// What a selection can be acted on with, and how that's presented.
  /// Defaults to [TextSelectionMenu]; null strips the field of a selection
  /// menu altogether.
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  final SurfaceVariant variant;

  /// The meaning the chrome wears. An [error] overrides it.
  final SemanticSwatch swatch;

  /// The style to paint, bypassing the theme.
  final TextFieldStyle? style;

  @override
  State<TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<TextField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  /// Force press is an iOS pressure gesture; nothing in the toolkit reads
  /// pressure yet.
  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => !widget.obscureText;

  late final TextSelectionGestureDetectorBuilder _gestures =
      TextSelectionGestureDetectorBuilder(delegate: this);

  /// Ours when the caller didn't bring one — and then ours to dispose.
  TextEditingController? _ownController;
  FocusNode? _ownFocus;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  bool _hovered = false;

  /// Whether the drag grips are showing. Theirs is a touch affordance, so
  /// what raises them is a touch gesture — never the keyboard.
  bool _showHandles = false;

  /// Rebuilt only when its inputs move, so the selection overlay isn't torn
  /// down and rebuilt on every keystroke.
  TextSelectionHandles? _handles;

  /// Whether this platform drags its selection about with grips at all.
  static bool get _handlesOnThisPlatform => switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.fuchsia => true,
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => false,
  };

  TextSelectionHandles _handlesWearing(double size, Color color) {
    if (_handles?.size != size || _handles?.color != color) {
      _handles = TextSelectionHandles(size: size, color: color);
    }
    return _handles!;
  }

  void _selectionChanged(
    TextSelection selection,
    SelectionChangedCause? cause,
  ) {
    final showing = _shouldShowHandles(cause);
    if (showing != _showHandles) setState(() => _showHandles = showing);
  }

  /// The grips follow the selection *toolbar's* rules: they belong to the
  /// gestures that put them there, and a field driven from the keyboard
  /// shouldn't sprout them.
  bool _shouldShowHandles(SelectionChangedCause? cause) {
    if (!_handlesOnThisPlatform) return false;
    if (!widget.enabled || !selectionEnabled) return false;
    if (!_gestures.shouldShowSelectionToolbar) return false;
    if (cause == SelectionChangedCause.keyboard) return false;
    if (widget.readOnly && _controller.selection.isCollapsed) return false;
    if (cause == SelectionChangedCause.longPress ||
        cause == SelectionChangedCause.stylusHandwriting) {
      return true;
    }
    return _controller.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_contentChanged);
    _focus.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(TextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_contentChanged);
      if (widget.controller != null) {
        _ownController?.dispose();
        _ownController = null;
      }
      _controller.addListener(_contentChanged);
      // A new controller, possibly with text of its own already in it.
      _empty = _controller.text.isEmpty;
    }
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _ownFocus)?.removeListener(_focusChanged);
      if (widget.focusNode != null) {
        _ownFocus?.dispose();
        _ownFocus = null;
      }
      _focus.addListener(_focusChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_contentChanged);
    _focus.removeListener(_focusChanged);
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  /// Only the empty-to-not-empty crossing matters here: it's what shows and
  /// hides the placeholder. Every other keystroke redraws inside
  /// [EditableText] without this widget rebuilding at all.
  ///
  /// Read off the controller rather than assumed: a field handed a
  /// controller that already has text in it starts full, and a placeholder
  /// over that text is two strings on top of each other.
  late bool _empty = _controller.text.isEmpty;
  void _contentChanged() {
    final empty = _controller.text.isEmpty;
    if (empty != _empty) setState(() => _empty = empty);
  }

  void _focusChanged() => setState(() {});

  // Keep the builder's identity stable when focus redraws the field so the
  // selection overlay is not recreated while its context menu is opening.
  static Widget _contextMenu(BuildContext context, EditableTextState state) =>
      TextSelectionMenu(editableTextState: state);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    // One thing turns the whole field: an error resolves the chrome against
    // the error swatch, border, caret, ring, and all.
    final swatch = widget.error != null ? SemanticSwatch.error : widget.swatch;
    final style =
        widget.style ?? theme.widgets.textField.resolve(swatch, widget.variant);
    final enabled = widget.enabled;
    final singleLine = widget.maxLines == 1;
    final focused = _focus.hasFocus && enabled;

    // A disabled field can't be reached by tab either.
    _focus.canRequestFocus = enabled;

    final editable = EditableText(
      key: editableTextKey,
      controller: _controller,
      focusNode: _focus,
      readOnly: widget.readOnly || !enabled,
      obscureText: widget.obscureText,
      style: style.textStyle,
      cursorColor: style.cursor,
      // The iOS floating cursor's shadow, which only shows while dragging.
      backgroundCursorColor: theme.palette.divider,
      selectionColor: focused ? style.selection : null,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      autofocus: widget.autofocus,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      textAlign: widget.textAlign,
      inputFormatters: widget.inputFormatters,
      autofillHints: widget.autofillHints,
      enableInteractiveSelection: selectionEnabled,
      selectionControls: _handlesOnThisPlatform
          ? _handlesWearing(style.handleSize, style.cursor)
          : null,
      showSelectionHandles: _showHandles,
      onSelectionChanged: _selectionChanged,
      contextMenuBuilder:
          widget.contextMenuBuilder ?? _contextMenu,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      // The gesture detector below owns the pointer; the renderer taking it
      // too would mean two things fighting over one tap.
      rendererIgnoresPointer: true,
    );

    Widget content = _gestures.buildGestureDetector(
      behavior: HitTestBehavior.translucent,
      child: editable,
    );

    if (_empty && widget.placeholder != null) {
      content = Stack(
        children: [
          content,
          // Never takes the pointer: a tap on the placeholder is a tap on
          // the field.
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: singleLine
                    ? AlignmentDirectional.centerStart
                    : AlignmentDirectional.topStart,
                child: DefaultTextStyle.merge(
                  style: style.placeholderStyle,
                  child: widget.placeholder!,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final surface = style.surface;
    final wash = enabled && _hovered ? style.hover : null;

    Widget box = Surface.custom(
      style: SurfaceStyle(
        foreground: surface.foreground,
        // Washes land on the fill, so a fill-less variant grows one the
        // moment the pointer arrives.
        fill: wash == null
            ? surface.fill
            : surface.fill == null
            ? wash
            : Color.alphaBlend(wash, surface.fill!),
        border: surface.border,
        dashed: surface.dashed,
        striped: surface.striped,
        radius: surface.radius,
      ),
      padding: singleLine ? style.padding : style.multilinePadding,
      child: Row(
        crossAxisAlignment: singleLine
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          if (widget.leading != null) ...[
            IconTheme.merge(
              data: IconThemeData(size: style.iconSize),
              child: widget.leading!,
            ),
            SizedBox(width: style.gap),
          ],
          Expanded(child: content),
          if (widget.trailing != null) ...[
            SizedBox(width: style.gap),
            IconTheme.merge(
              data: IconThemeData(size: style.iconSize),
              child: widget.trailing!,
            ),
          ],
        ],
      ),
    );

    if (singleLine) box = SizedBox(height: style.height, child: box);

    box = FocusRing(
      visible: focused,
      color: style.ring,
      radius: surface.radius,
      child: box,
    );

    box = MouseRegion(
      cursor: enabled ? SystemMouseCursors.text : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: box,
    );

    final message = widget.error ?? widget.helper;

    return AnimatedOpacity(
      opacity: enabled ? 1 : style.disabledOpacity,
      duration: theme.motion.fast,
      curve: theme.motion.move,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.label != null) ...[
              DefaultTextStyle.merge(
                style: style.labelStyle,
                child: widget.label!,
              ),
              SizedBox(height: style.labelGap),
            ],
            box,
            if (message != null) ...[
              SizedBox(height: style.helperGap),
              DefaultTextStyle.merge(
                style: widget.error != null
                    ? style.errorStyle
                    : style.helperStyle,
                child: message,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
