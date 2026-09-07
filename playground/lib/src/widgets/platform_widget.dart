import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class PlatformWidget extends StatelessWidget {
  const PlatformWidget({
    super.key,
    required this.cupertino,
    required this.material,
  });

  final WidgetBuilder cupertino;
  final WidgetBuilder material;

  @override
  Widget build(BuildContext context) {
    Widget widget;

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      widget = cupertino(context);
    } else {
      widget = material(context);
    }

    return widget;
  }
}
