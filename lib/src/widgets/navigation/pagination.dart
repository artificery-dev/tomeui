import 'package:tomeui/tomeui.dart';

/// Pages of something long, and the way between them.
///
/// A run of numbers with the ends always shown and the middle elided —
/// `‹ 1 … 7 8 9 … 42 ›` — so the trail is the same width whichever page
/// you're on. [siblings] says how many neighbors flank the current page.
///
/// Same width means *exactly* the same: every slot is a square the size of
/// a control, the elision included, and the run always holds the same
/// number of them. A pager that reflowed as you walked it would move the
/// next page out from under the pointer that was going to press it.
///
/// ```dart
/// Pagination(
///   page: page,
///   pageCount: 42,
///   onChanged: (value) => setState(() => page = value),
/// )
/// ```
///
/// Pages are counted from one, the way people count them. A [pageCount] of
/// one draws the single page and two dead arrows — a control that vanishes
/// when the list gets short would move everything else on the page.
class Pagination extends StatelessWidget {
  const Pagination({
    required this.page,
    required this.pageCount,
    required this.onChanged,
    this.siblings = 1,
    this.variant = SurfaceVariant.subtle,
    this.swatch = SemanticSwatch.primary,
    super.key,
  });

  /// The page you're on, counted from one.
  final int page;

  final int pageCount;

  /// Called with the page to go to. Null disables the whole run.
  final ValueChanged<int>? onChanged;

  /// How many pages either side of the current one stay on show.
  final int siblings;

  /// What the pages that aren't current wear. The current one is always
  /// [SurfaceVariant.solid] — it's the answer, not an offer, and it stays
  /// at full voice rather than dimming, because it isn't disabled so much
  /// as already chosen.
  final SurfaceVariant variant;

  final SemanticSwatch swatch;

  /// The page numbers to draw, with nulls where a run was elided.
  ///
  /// Always the same number of slots — the two ends, the current page and
  /// its [siblings], and two elisions — so the run keeps its width as it's
  /// walked. Near either end the window opens out along that end instead of
  /// eliding two pages nobody would have to skip.
  ///
  /// Every elision hides at least two pages: the near-end windows are sized
  /// so an ellipsis never stands in for a single number, which would be
  /// wider than the number it hid.
  List<int?> get _slots {
    // The ends, the current page and its siblings, and the two elisions.
    final window = 2 * siblings + 5;
    if (pageCount <= window) {
      return [for (var page = 1; page <= pageCount; page++) page];
    }

    // How many pages a run of numbers takes when it starts or finishes at
    // an end: everything the middle window holds, minus the elision and
    // the far end it replaces.
    final run = 2 * siblings + 3;

    if (page <= siblings + 3) {
      return [for (var i = 1; i <= run; i++) i, null, pageCount];
    }
    if (page >= pageCount - siblings - 2) {
      return [
        1,
        null,
        for (var i = pageCount - run + 1; i <= pageCount; i++) i,
      ];
    }
    return [
      1,
      null,
      for (var i = page - siblings; i <= page + siblings; i++) i,
      null,
      pageCount,
    ];
  }

  @override
  Widget build(BuildContext context) {
    assert(pageCount > 0, 'A run of pages needs pages.');
    assert(
      page >= 1 && page <= pageCount,
      'The current page is off the end of the run.',
    );
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final enabled = onChanged != null;

    // Squares: the padding a button would keep around its label is what
    // makes a `1` narrower than a `42`, and a run that changes width is a
    // run that moves under the pointer.
    final buttons = theme.widgets.button;
    final rest = buttons
        .resolve(swatch, variant)
        .copyWith(padding: EdgeInsets.zero);
    final current = buttons
        .resolve(swatch, SurfaceVariant.solid)
        .copyWith(
          padding: EdgeInsets.zero,
          // The page you're on isn't disabled, it's answered: it stays at full
          // voice unless the whole run is dead.
          disabledOpacity: enabled ? 1 : theme.opacities.disabled,
        );
    final side = rest.height;

    Widget slot(Widget child) => SizedBox.square(dimension: side, child: child);

    Widget label(String text) =>
        // Four digits fit a square; five would spill out of one.
        FittedBox(fit: BoxFit.scaleDown, child: Text(text));

    Widget arrow({required bool back}) {
      final target = back ? page - 1 : page + 1;
      final live = enabled && target >= 1 && target <= pageCount;
      return slot(
        Button.custom(
          onPressed: live ? () => onChanged!(target) : null,
          style: rest,
          child: Icon(
            back ? theme.icons.chevronLeft : theme.icons.chevronRight,
            size: theme.sizes.iconSmall,
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          arrow(back: true),
          for (final page in _slots) ...[
            SizedBox(width: theme.space.x1),
            if (page == null)
              // The elision isn't a place you can go, so it isn't a button
              // — but it keeps a place the size of one.
              slot(
                Center(
                  child: DefaultTextStyle.merge(
                    style: theme.widgets.text.resolve(
                      TextRole.body,
                      emphasis: TextEmphasis.tertiary,
                    ),
                    child: const Text('…'),
                  ),
                ),
              )
            else
              slot(
                Semantics(
                  selected: page == this.page,
                  child: Button.custom(
                    onPressed: enabled && page != this.page
                        ? () => onChanged!(page)
                        : null,
                    style: page == this.page ? current : rest,
                    child: label('$page'),
                  ),
                ),
              ),
          ],
          SizedBox(width: theme.space.x1),
          arrow(back: false),
        ],
      ),
    );
  }
}
