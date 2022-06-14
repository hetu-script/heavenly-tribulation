import 'dart:ui';

import 'package:samsara/samsara.dart';

abstract class GlobalConfig {
  static bool desktopMode = false;
  static Size screenSize = Size.zero;
}

final SamsaraEngine engine = SamsaraEngine();
