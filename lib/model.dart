import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'evaluator.dart';
import 'tex_span.dart';

class CalculatorModel extends ChangeNotifier {
  static const String _themePref = 'theme';
  static const String _signDitisPref = 'signDigits';
  static const String _thousandSeparatorPref = 'separator';
  static const String _scientificExponentPref = 'scientificLimit';
  static const String _angleUnitPref = 'angleUnit';
  static const String _formatPref = 'resultFormat';

  static const String _stoAPref = 'stoA';
  static const String _stoBPref = 'stoB';
  static const String _stoCPref = 'stoC';
  static const String _stoDPref = 'stoD';

  CalculatorModel._();

  factory CalculatorModel() {
    CalculatorModel model = CalculatorModel._();
    model._initModel();
    return model;
  }

  // Default values
  final ValueNotifier<ThemeMode> _theme = ValueNotifier(ThemeMode.system);
  int _significantDigits = 10;
  int _scientificNotationExponent = 9;
  String _thousandSeparator = ' ';
  AngleUnit _angleUnit = AngleUnit.radian;
  Format _format = Format.decimal;

  double _stoA = 0;
  double _stoB = 0;
  double _stoC = 0;
  double _stoD = 0;

  SharedPreferences _preferences;
  final ValueNotifier<bool> _initialized = ValueNotifier(false);

  void _initModel() async {
    _preferences = await SharedPreferences.getInstance();
    if (_preferences.containsKey(_themePref)) {
      _theme.value = ThemeMode.values[_preferences.getInt(_themePref)];
    }

    if (_preferences.containsKey(_signDitisPref)) {
      _significantDigits = _preferences.getInt(_signDitisPref);
    }

    if (_preferences.containsKey(_scientificExponentPref)) {
      _scientificNotationExponent = _preferences.getInt(_scientificExponentPref);
    }

    if (_preferences.containsKey(_thousandSeparatorPref)) {
      _thousandSeparator = _preferences.getString(_thousandSeparatorPref);
    }

    if (_preferences.containsKey(_angleUnitPref)) {
      _angleUnit = AngleUnit.values[_preferences.getInt(_angleUnitPref)];
    }

    if (_preferences.containsKey(_formatPref)) {
      _format = Format.values[_preferences.getInt(_formatPref)];
    }

    if (_preferences.containsKey(_stoAPref)) {
      _stoA = _preferences.getDouble(_stoAPref);
    }

    if (_preferences.containsKey(_stoBPref)) {
      _stoB = _preferences.getDouble(_stoBPref);
    }

    if (_preferences.containsKey(_stoCPref)) {
      _stoC = _preferences.getDouble(_stoCPref);
    }

    if (_preferences.containsKey(_stoDPref)) {
      _stoD = _preferences.getDouble(_stoDPref);
    }

    notifyListeners();
    _initialized.value = true;
  }

  set theme(ThemeMode theme) {
    if (theme != _theme.value) {
      _theme.value = theme;
      _preferences?.setInt(_themePref, theme.index);
    }
  }

  set significantDigits(int digits) {
    if (digits != _significantDigits) {
      _significantDigits = digits;
      _preferences?.setInt(_signDitisPref, digits);
      notifyListeners();
    }
  }

  set scientificNotationExponent(int exponent) {
    if (exponent != _scientificNotationExponent) {
      _scientificNotationExponent = exponent;
      _preferences?.setInt(_scientificExponentPref, exponent);
      notifyListeners();
    }
  }

  set thousandSeparator(String separator) {
    if (separator != _thousandSeparator) {
      _thousandSeparator = separator;
      _preferences?.setString(_thousandSeparatorPref, separator);
      notifyListeners();
    }
  }

  set angleUnit(AngleUnit unit) {
    if (unit != _angleUnit) {
      _angleUnit = unit;
      _preferences?.setInt(_angleUnitPref, unit.index);
      notifyListeners();
    }
  }

  set format(Format format) {
    if (_format != format) {
      _format = format;
      _preferences?.setInt(_formatPref, format.index);
      notifyListeners();
    }
  }

  set stoA(double value) {
    _stoA = value;
    _preferences?.setDouble(_stoAPref, value);
  }

  set stoB(double value) {
    _stoB = value;
    _preferences?.setDouble(_stoBPref, value);
  }

  set stoC(double value) {
    _stoC = value;
    _preferences?.setDouble(_stoCPref, value);
  }

  set stoD(double value) {
    _stoD = value;
    _preferences?.setDouble(_stoDPref, value);
  }

  ValueListenable<bool> get initialized => _initialized;
  ValueListenable<ThemeMode> get themeListenable => _theme;

  ThemeMode get theme => _theme.value;
  int get significantDigits => _significantDigits;
  int get scientificNotationExponent => _scientificNotationExponent;
  String get thousandSeparator => _thousandSeparator;

  AngleUnit get angleUnit => _angleUnit;
  Format get format => _format;

  double get stoA => _stoA;
  double get stoB => _stoB;
  double get stoC => _stoC;
  double get stoD => _stoD;
}

class ExpressionModel extends ChangeNotifier {
  final List<List<Token>> _expression;
  int _componentPos;

  ExpressionModel()
      : _expression = [],
        _componentPos = 0;

  set componentPos(int position) {
    _componentPos = position;
  }

  void clear() {
    if (_expression.isNotEmpty) {
      _expression.clear();
      _componentPos = 0;
      notifyListeners();
    }
  }

  void add(List<Token> tokens) {
    if (tokens != null && tokens.isNotEmpty) {
      _expression.insert(_componentPos, tokens);
      _componentPos++;
      notifyListeners();
    }
  }

  void remove() {
    if (_expression.isNotEmpty && _componentPos > 0) {
      _componentPos--;
      _expression.removeAt(_componentPos);
      notifyListeners();
    }
  }

  bool get isEmpty => _expression.isEmpty;
  bool get isNotEmpty => _expression.isNotEmpty;

  List<Token> get expression => _expression.expand((e) => e).toList();

  List<String> get textComponents {
    List<String> components = [];
    for (final List<Token> tokens in _expression) {
      String component = '';
      for (final Token token in tokens) {
        component += token.symbol;
      }
      components.add(component);
    }
    return components;
  }

  int get componentPos => _componentPos;

  int get cursorPos {
    int textPos = 0;
    int pos = 0;
    for (final String component in textComponents) {
      textPos += TexSpan.calcRenderedTextLength(component);
      pos++;
      if (pos == _componentPos) {
        break;
      }
    }
    return textPos;
  }
}
