import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The semantic icon tokens.
///
/// A widget asks for *meaning* — `icons.close`, `icons.warning` — never for a
/// glyph, so the whole icon language swaps by constructing one of these with
/// different [IconData]. Every parameter defaults to the Lucide glyph, which
/// makes `Icons()` the default set and a custom theme a list of only the
/// icons it changes; [copyWith] does the same to an existing set.
///
/// The vocabulary is deliberately UI chrome, not domain objects: the names
/// here are the ones controls and patterns need to exist. An app's own
/// iconography stays the app's.
@immutable
class Icons {
  const Icons({
    // Navigation.
    this.back = LucideIcons.arrowLeft,
    this.forward = LucideIcons.arrowRight,
    this.up = LucideIcons.arrowUp,
    this.down = LucideIcons.arrowDown,
    this.chevronLeft = LucideIcons.chevronLeft,
    this.chevronRight = LucideIcons.chevronRight,
    this.chevronUp = LucideIcons.chevronUp,
    this.chevronDown = LucideIcons.chevronDown,
    this.menu = LucideIcons.menu,
    this.close = LucideIcons.x,
    this.more = LucideIcons.ellipsis,
    this.moreVertical = LucideIcons.ellipsisVertical,
    this.externalLink = LucideIcons.externalLink,
    // Actions.
    this.add = LucideIcons.plus,
    this.remove = LucideIcons.minus,
    this.edit = LucideIcons.pencil,
    this.delete = LucideIcons.trash2,
    this.copy = LucideIcons.copy,
    this.paste = LucideIcons.clipboardPaste,
    this.search = LucideIcons.search,
    this.filter = LucideIcons.funnel,
    this.sort = LucideIcons.arrowUpDown,
    this.refresh = LucideIcons.refreshCw,
    this.settings = LucideIcons.settings,
    this.share = LucideIcons.share2,
    this.download = LucideIcons.download,
    this.upload = LucideIcons.upload,
    this.send = LucideIcons.send,
    this.confirm = LucideIcons.check,
    this.link = LucideIcons.link,
    this.drag = LucideIcons.gripVertical,
    // Status.
    this.info = LucideIcons.info,
    this.success = LucideIcons.circleCheck,
    this.warning = LucideIcons.triangleAlert,
    this.error = LucideIcons.circleAlert,
    this.help = LucideIcons.circleHelp,
    this.busy = LucideIcons.loaderCircle,
    // Visibility and security.
    this.visible = LucideIcons.eye,
    this.hidden = LucideIcons.eyeOff,
    this.locked = LucideIcons.lock,
    this.unlocked = LucideIcons.lockOpen,
    // Appearance modes.
    this.lightMode = LucideIcons.sun,
    this.darkMode = LucideIcons.moon,
    this.systemMode = LucideIcons.monitor,
    // The common objects UI chrome itself refers to.
    this.user = LucideIcons.user,
    this.group = LucideIcons.users,
    this.home = LucideIcons.house,
    this.calendar = LucideIcons.calendar,
    this.clock = LucideIcons.clock,
    this.folder = LucideIcons.folder,
    this.file = LucideIcons.file,
    this.image = LucideIcons.image,
    this.favorite = LucideIcons.star,
  });

  /// Go back — a directional arrow, not a chevron.
  final IconData back;
  final IconData forward;
  final IconData up;
  final IconData down;

  /// Disclosure and stepping — chevrons, where [back]/[forward] would
  /// overpromise.
  final IconData chevronLeft;
  final IconData chevronRight;
  final IconData chevronUp;
  final IconData chevronDown;

  final IconData menu;
  final IconData close;

  /// The overflow menu, horizontal.
  final IconData more;
  final IconData moreVertical;

  /// Leaves the app — warn the reader before the tap.
  final IconData externalLink;

  final IconData add;
  final IconData remove;
  final IconData edit;
  final IconData delete;
  final IconData copy;
  final IconData paste;
  final IconData search;
  final IconData filter;
  final IconData sort;
  final IconData refresh;
  final IconData settings;
  final IconData share;
  final IconData download;
  final IconData upload;
  final IconData send;

  /// A bare affirmative: the tick on the selected row, the confirm action.
  final IconData confirm;
  final IconData link;

  /// The handle on a reorderable row.
  final IconData drag;

  final IconData info;
  final IconData success;
  final IconData warning;
  final IconData error;
  final IconData help;

  /// Work in flight. Spin it; the glyph is drawn mid-turn.
  final IconData busy;

  final IconData visible;
  final IconData hidden;
  final IconData locked;
  final IconData unlocked;

  final IconData lightMode;
  final IconData darkMode;

  /// Follow-the-platform, in a theme switcher's third position.
  final IconData systemMode;

  final IconData user;
  final IconData group;
  final IconData home;
  final IconData calendar;
  final IconData clock;
  final IconData folder;
  final IconData file;
  final IconData image;
  final IconData favorite;

  Icons copyWith({
    IconData? back,
    IconData? forward,
    IconData? up,
    IconData? down,
    IconData? chevronLeft,
    IconData? chevronRight,
    IconData? chevronUp,
    IconData? chevronDown,
    IconData? menu,
    IconData? close,
    IconData? more,
    IconData? moreVertical,
    IconData? externalLink,
    IconData? add,
    IconData? remove,
    IconData? edit,
    IconData? delete,
    IconData? copy,
    IconData? paste,
    IconData? search,
    IconData? filter,
    IconData? sort,
    IconData? refresh,
    IconData? settings,
    IconData? share,
    IconData? download,
    IconData? upload,
    IconData? send,
    IconData? confirm,
    IconData? link,
    IconData? drag,
    IconData? info,
    IconData? success,
    IconData? warning,
    IconData? error,
    IconData? help,
    IconData? busy,
    IconData? visible,
    IconData? hidden,
    IconData? locked,
    IconData? unlocked,
    IconData? lightMode,
    IconData? darkMode,
    IconData? systemMode,
    IconData? user,
    IconData? group,
    IconData? home,
    IconData? calendar,
    IconData? clock,
    IconData? folder,
    IconData? file,
    IconData? image,
    IconData? favorite,
  }) => Icons(
    back: back ?? this.back,
    forward: forward ?? this.forward,
    up: up ?? this.up,
    down: down ?? this.down,
    chevronLeft: chevronLeft ?? this.chevronLeft,
    chevronRight: chevronRight ?? this.chevronRight,
    chevronUp: chevronUp ?? this.chevronUp,
    chevronDown: chevronDown ?? this.chevronDown,
    menu: menu ?? this.menu,
    close: close ?? this.close,
    more: more ?? this.more,
    moreVertical: moreVertical ?? this.moreVertical,
    externalLink: externalLink ?? this.externalLink,
    add: add ?? this.add,
    remove: remove ?? this.remove,
    edit: edit ?? this.edit,
    delete: delete ?? this.delete,
    copy: copy ?? this.copy,
    paste: paste ?? this.paste,
    search: search ?? this.search,
    filter: filter ?? this.filter,
    sort: sort ?? this.sort,
    refresh: refresh ?? this.refresh,
    settings: settings ?? this.settings,
    share: share ?? this.share,
    download: download ?? this.download,
    upload: upload ?? this.upload,
    send: send ?? this.send,
    confirm: confirm ?? this.confirm,
    link: link ?? this.link,
    drag: drag ?? this.drag,
    info: info ?? this.info,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    error: error ?? this.error,
    help: help ?? this.help,
    busy: busy ?? this.busy,
    visible: visible ?? this.visible,
    hidden: hidden ?? this.hidden,
    locked: locked ?? this.locked,
    unlocked: unlocked ?? this.unlocked,
    lightMode: lightMode ?? this.lightMode,
    darkMode: darkMode ?? this.darkMode,
    systemMode: systemMode ?? this.systemMode,
    user: user ?? this.user,
    group: group ?? this.group,
    home: home ?? this.home,
    calendar: calendar ?? this.calendar,
    clock: clock ?? this.clock,
    folder: folder ?? this.folder,
    file: file ?? this.file,
    image: image ?? this.image,
    favorite: favorite ?? this.favorite,
  );

  /// The default set — every token wearing its Lucide glyph.
  static const Icons lucide = Icons();
}
