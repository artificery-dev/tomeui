import 'package:tomeui/tomeui.dart';

/// Where a run of text sits on the type scale.
///
/// A role is the *meaning* — a headline, a caption, the label on a control —
/// and [Typography] says what that means in size, weight, and leading. Text
/// widgets name roles; nothing in an app names a font size.
enum TextRole {
  display,
  headline,
  title,
  subtitle,
  body,
  bodySmall,
  label,
  caption,
  code,

  /// A section kicker: [label], uppercased by the widget and tracked wider.
  /// Derived rather than tokenised — it *is* the label style, spaced out.
  kicker,
}

/// How loudly text speaks against its surface.
///
/// Emphasis grades the inherited foreground with [Opacities] instead of
/// reaching for a greyer colour, so the same steps read correctly on every
/// surface in every brightness — which is the whole reason [Palette] has one
/// text colour and not five.
enum TextEmphasis { full, secondary, tertiary, disabled }

/// The configuration text resolves against: which stop tinted text and links
/// wear, and how far a kicker's letters stand apart.
///
/// Plural, like [SurfaceStyles], because this is the *input* side. The output
/// side is a plain Flutter [TextStyle] rather than a class of our own — for
/// text, that is exactly what resolved paint looks like.
@immutable
class TextStyles {
  const TextStyles({
    this.tinted = const Shade(light: 700, dark: 300),
    this.link = const Shade(light: 600, dark: 400),
    this.linkHover = const Shade(light: 700, dark: 300),
    this.kickerTracking = 0.8,
    this.underline = LinkUnderline.hover,
  });

  /// The stop text wears when given a swatch of its own — the same
  /// deep-enough-to-read stop a ghost surface's foreground takes.
  final Shade tinted;

  /// The stop a [Link] wears at rest — loud enough to be findable inside a
  /// paragraph without shouting.
  final Shade link;

  /// The stop a [Link] wears under the pointer: a step toward more contrast
  /// in *both* directions — deeper in light, brighter in dark — since
  /// "louder" runs opposite ways along the ramp.
  final Shade linkHover;

  /// Letter spacing added to [TextRole.kicker] on top of the label style's.
  final double kickerTracking;

  /// When links draw their underline.
  final LinkUnderline underline;

  TextStyles copyWith({
    Shade? tinted,
    Shade? link,
    Shade? linkHover,
    double? kickerTracking,
    LinkUnderline? underline,
  }) => TextStyles(
    tinted: tinted ?? this.tinted,
    link: link ?? this.link,
    linkHover: linkHover ?? this.linkHover,
    kickerTracking: kickerTracking ?? this.kickerTracking,
    underline: underline ?? this.underline,
  );

  @override
  bool operator ==(Object other) =>
      other is TextStyles &&
      other.tinted == tinted &&
      other.link == link &&
      other.linkHover == linkHover &&
      other.kickerTracking == kickerTracking &&
      other.underline == underline;

  @override
  int get hashCode =>
      Object.hash(tinted, link, linkHover, kickerTracking, underline);
}
