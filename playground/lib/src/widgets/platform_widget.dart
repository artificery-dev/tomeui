import 'dart:io';

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

    if (Platform.isIOS || Platform.isMacOS) {
      widget = cupertino(context);
    } else {
      widget = material(context);
    }

    return widget;
  }
}
