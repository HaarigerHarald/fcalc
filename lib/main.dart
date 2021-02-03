import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'main_page.dart';
import 'model.dart';

void main() {
  runApp(FCalcApp());
}

class FCalcApp extends StatefulWidget {
  static const String title = 'Calculator';

  @override
  State<StatefulWidget> createState() => _FCalcAppState();
}

class _FCalcAppState extends State<FCalcApp> {
  CalculatorModel _model;

  @override
  void initState() {
    _model = CalculatorModel();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _model.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    Typography typography = Typography.material2014(platform: defaultTargetPlatform);
    return ValueListenableBuilder<ThemeMode>(
        valueListenable: _model.themeListenable,
        builder: (context, value, child) {
          return MaterialApp(
            title: FCalcApp.title,
            theme: ThemeData(
                primaryColor: const Color(0xff1259a9),
                accentColor: const Color(0xffd07c25),
                buttonColor: Colors.grey[100],
                visualDensity: VisualDensity.adaptivePlatformDensity,
                brightness: Brightness.light,
                textTheme:
                    typography.black.copyWith(button: const TextStyle(color: Color(0xff0E447F))),
                accentTextTheme:
                    typography.black.copyWith(bodyText1: const TextStyle(color: Color(0xff236DBC))),
                fontFamily: 'RobotoRegular'),
            darkTheme: ThemeData(
                primaryColor: const Color(0xff1259a9),
                accentColor: const Color(0xffd07c25),
                buttonColor: const Color(0xff406895),
                visualDensity: VisualDensity.adaptivePlatformDensity,
                textTheme: typography.white.copyWith(button: const TextStyle(color: Colors.white)),
                accentTextTheme:
                    typography.white.copyWith(bodyText1: const TextStyle(color: Color(0xffE2A56C))),
                brightness: Brightness.dark,
                fontFamily: 'RobotoRegular'),
            themeMode: _model.theme,
            home: MainPage(title: FCalcApp.title, model: _model),
          );
        });
  }
}
