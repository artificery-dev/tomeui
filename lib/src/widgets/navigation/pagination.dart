import 'package:tomeui/tomeui.dart';

/// Pages of something long, and the way between them.
///
/// A run of numbers with the ends always shown and the middle elided —
/// `‹ 1 … 7 8 9 … 42 ›` — so the trail is the same width whichever page
/// you're on. [siblings] says how many neighbours flank the current page.
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
    this.variant = SurfaceVariant.ghost,
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
  /// [SurfaceVariant.solid] — it's the answer, not an offer.
  final SurfaceVariant variant;

  final SemanticSwatch swatch;

  /// The page numbers to draw, with nulls where a run was elided.
  ///
  /// The first and last page are always there, and so is every page within
  /// [siblings] of [page]. A gap of exactly one page is drawn as that page
  /// rather than as an ellipsis, since an ellipsis hiding one number is
  /// wider than the number.
  List<int?> get _slots {
    final shown = <int>{
      1,
      pageCount,
      for (var i = page - siblings; i <= page + siblings; i++)
        if (i >= 1 && i <= pageCount) i,
    };
    final sorted = shown.toList()..sort();

    final slots = <int?>[];
    for (final (index, number) in sorted.indexed) {
      if (index > 0) {
        final gap = number - sorted[index - 1];
        if (gap == 2) {
          slots.add(number - 1);
        } else if (gap > 2) {
          slots.add(null);
        }
      }
      slots.add(number);
    }
    return slots;
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

    Widget arrow({required bool back}) {
      final target = back ? page - 1 : page + 1;
      final live = enabled && target >= 1 && target <= pageCount;
      return Button(
        onPressed: live ? () => onChanged!(target) : null,
        variant: variant,
        swatch: swatch,
        center: Icon(
          back ? theme.icons.chevronLeft : theme.icons.chevronRight,
          size: theme.sizes.iconSmall,
        ),
      );
    }

    return Semantics(
      container: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          arrow(back: true),
          for (final slot in _slots) ...[
            SizedBox(width: theme.space.x1),
            if (slot == null)
              // The elision isn't a place you can go, so it isn't a button.
              Padding(
                padding: EdgeInsets.symmetric(horizontal: theme.space.x1),
                child: DefaultTextStyle.merge(
                  style: theme.widgets.text.resolve(
                    TextRole.body,
                    emphasis: TextEmphasis.tertiary,
                  ),
                  child: const Text('…'),
                ),
              )
            else
              Semantics(
                selected: slot == page,
                child: Button(
                  onPressed: enabled && slot != page
                      ? () => onChanged!(slot)
                      : null,
                  variant: slot == page ? SurfaceVariant.solid : variant,
                  swatch: swatch,
                  center: Text('$slot'),
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
