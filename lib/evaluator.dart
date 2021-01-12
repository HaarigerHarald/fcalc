import 'dart:math' as math;

typedef MathFunction = num Function(num arg1, [num arg2]);

enum FunctionArgumentPos { prefix, suffix, none }

enum OperatorAssociativity { left, right, none }

enum _TokenType { numeric, operator, leftParenthesis, rightParenthesis, function, constant }

/// Represents a token within a given mathematical expression.
class Token {
  final String symbol;
  final _TokenType _type;
  final num value;
  final MathFunction mathFunc;
  final FunctionArgumentPos funcArgPos;
  final int presedence;
  final OperatorAssociativity associativity;
  final double arg2;

  /// Whether to pass the angle conversion factor to the [MathFunction] as [arg2].
  final bool isTrignometricFunction;

  const Token._(this.symbol, this._type,
      {this.value,
      this.mathFunc,
      this.funcArgPos = FunctionArgumentPos.none,
      this.presedence = 0,
      this.associativity = OperatorAssociativity.none,
      this.isTrignometricFunction = false,
      this.arg2});

  const Token.numeric(this.symbol, [this.value])
      : _type = _TokenType.numeric,
        mathFunc = null,
        funcArgPos = FunctionArgumentPos.none,
        presedence = 0,
        associativity = OperatorAssociativity.none,
        isTrignometricFunction = false,
        arg2 = null;

  const Token.operation(this.symbol, this.presedence,
      [this.associativity = OperatorAssociativity.left])
      : _type = _TokenType.operator,
        value = null,
        mathFunc = null,
        funcArgPos = FunctionArgumentPos.none,
        isTrignometricFunction = false,
        arg2 = null;

  const Token.function(this.symbol, this.mathFunc,
      {this.funcArgPos = FunctionArgumentPos.suffix,
      this.arg2,
      this.isTrignometricFunction = false})
      : _type = _TokenType.function,
        value = null,
        presedence = 5,
        associativity = OperatorAssociativity.none;

  const Token.constant(this.symbol, this.value)
      : _type = _TokenType.constant,
        mathFunc = null,
        funcArgPos = FunctionArgumentPos.none,
        presedence = 0,
        associativity = OperatorAssociativity.none,
        isTrignometricFunction = false,
        arg2 = null;

  static const Token zero = Token.numeric('0', 0);
  static const Token one = Token.numeric('1', 1);
  static const Token two = Token.numeric('2', 2);
  static const Token three = Token.numeric('3', 3);
  static const Token four = Token.numeric('4', 4);
  static const Token five = Token.numeric('5', 5);
  static const Token six = Token.numeric('6', 6);
  static const Token seven = Token.numeric('7', 7);
  static const Token eight = Token.numeric('8', 8);
  static const Token nine = Token.numeric('9', 9);
  static const Token dot = Token.numeric('.');
  static const Token scientificExp = Token.numeric('E');

  static const Token add = Token.operation('+', 1);
  static const Token subtract = Token.operation('-', 1);
  static const Token multiply = Token.operation('×', 2);
  static const Token divide = Token.operation('÷', 2);
  static const Token exponentiate = Token.operation('^', 3, OperatorAssociativity.right);

  static const Token leftParenthesis = Token._('(', _TokenType.leftParenthesis);
  static const Token rightParenthesis = Token._(')', _TokenType.rightParenthesis);

  // There should be a way to define lambda functions as const, but currently there is none :/
  // see: https://github.com/dart-lang/language/issues/1048
  static Token sqrtFunc = Token.function('√', (num arg1, [num arg2]) => math.sqrt(arg1));

  static Token cubertFunc =
      Token.function('{}^3√', (num arg1, [num arg2]) => math.pow(arg1, 1 / 3));

  static Token rootFunc =
      Token.function('{}^{x}√', (num arg1, [num arg2]) => math.pow(arg1, 1 / arg2));

  static Token ln = Token.function('ln', (num arg1, [num arg2]) {
    if (arg1 <= 0) throw EvaluationException('Invalid argument: ln');
    return math.log(arg1);
  });

  static Token sin = Token.function('sin', (num arg1, [num arg2 = 1]) {
    double radAngle = arg1 / arg2;
    double piMultiple = radAngle / math.pi;
    double remainder = piMultiple - piMultiple.truncate();
    if (remainder.abs() < 1E-12) return 0;
    return math.sin(radAngle);
  }, isTrignometricFunction: true);

  static Token cos = Token.function('cos', (num arg1, [num arg2 = 1]) {
    double radAngle = arg1 / arg2;
    double piMultiple = radAngle / math.pi;
    double remainder = (piMultiple - piMultiple.truncate()).abs() - 0.5;
    if (remainder.abs() < 1E-12) return 0;
    return math.cos(radAngle);
  }, isTrignometricFunction: true);

  static Token tan = Token.function(
      'tan', (num arg1, [num arg2 = 1]) => sin.mathFunc(arg1, arg2) / cos.mathFunc(arg1, arg2),
      isTrignometricFunction: true);

  static Token log10 = Token.function('log_{10}', (num arg1, [num arg2]) {
    if (arg1 <= 0) throw EvaluationException('Invalid argument: log_{10}');
    return math.log(arg1) / math.ln10;
  });

  static Token arcsin = Token.function('sin^{-1}', (num arg1, [num arg2 = 1]) {
    if (arg1 < -1 || arg1 > 1) throw EvaluationException('Invalid argument: sin^{-1}');
    return math.asin(arg1) * arg2;
  }, isTrignometricFunction: true);

  static Token arccos = Token.function('cos^{-1}', (num arg1, [num arg2 = 1]) {
    if (arg1 < -1 || arg1 > 1) throw EvaluationException('Invalid argument: cos^{-1}');
    return math.acos(arg1) * arg2;
  }, isTrignometricFunction: true);

  static Token arctan = Token.function(
      'tan^{-1}', (num arg1, [num arg2 = 1]) => math.atan(arg1) * arg2,
      isTrignometricFunction: true);

  static Token log = Token.function('log_{x}', (num arg1, [num arg2]) {
    if (arg1 <= 0 || arg2 <= 0) throw EvaluationException('Invalid argument: log_{$arg2}');
    return math.log(arg1) / math.log(arg2);
  });

  static Token sinh =
      Token.function('sinh', (num arg1, [num arg2]) => (math.exp(arg1) - math.exp(-arg1)) / 2);

  static Token cosh =
      Token.function('cosh', (num arg1, [num arg2]) => (math.exp(arg1) + math.exp(-arg1)) / 2);

  static Token tanh =
      Token.function('tanh', (num arg1, [num arg2]) => 1 - 2 / (math.exp(2 * arg1) + 1));

  static Token abs = Token.function('abs', (num arg1, [num arg2]) => arg1.abs());

  static Token arsinh = Token.function(
      'sinh^{-1}', (num arg1, [num arg2]) => math.log(arg1 + math.sqrt(math.pow(arg1, 2) + 1)));

  static Token arcosh = Token.function('cosh^{-1}', (num arg1, [num arg2]) {
    if (arg1 < 1) throw EvaluationException('Invalid argument: cosh^{-1}');
    return math.log(arg1 + math.sqrt(math.pow(arg1, 2) - 1));
  });

  static Token artanh = Token.function('tanh^{-1}', (num arg1, [num arg2]) {
    if (arg1 <= -1 || arg1 >= 1) throw EvaluationException('Invalid argument: tanh^{-1}');
    return math.log((1 + arg1) / (1 - arg1)) / 2;
  });

  static Token factorial = Token.function('!', (num arg1, [num arg2]) {
    if (arg1 >= 0 && (arg1 - arg1.truncateToDouble()) == 0 && arg1.isFinite) {
      double result = 1;
      for (; arg1 > 1; arg1--) {
        result = result * arg1;
        if (result.isInfinite) break;
      }

      return result;
    }
    throw EvaluationException('Invalid argument: x!');
  }, funcArgPos: FunctionArgumentPos.prefix);

  static const Token pi = Token.constant('π', math.pi);
  static const Token e = Token.constant('e', math.e);

  // Physics constants from CODATA in SI units: https://physics.nist.gov/cuu/Constants/Table/allascii.txt
  static const Token protonMass = Token.constant('m_p', 1.67262192369e-27);
  static const Token neutronMass = Token.constant('m_n', 1.67492749804e-27);
  static const Token electronMass = Token.constant('m_e', 9.1093837015e-31);
  static const Token unifiedAtomicMass = Token.constant('m_u', 1.66053906660e-27);

  static const Token planckConst = Token.constant('h', 6.62607015e-34);
  static const Token reducedPlanckConst = Token.constant('ħ', 1.054571817e-34);
  static const Token fineStructureConst = Token.constant('α_f', 7.2973525693e-3);
  static const Token bohrMagneton = Token.constant('μ_B', 9.2740100783e-24);
  static const Token nuclearMagneton = Token.constant('μ_N', 5.0507837461e-27);

  static const Token comptonWavelength = Token.constant('λ_c', 2.42631023867e-12);
  static const Token rydbergConst = Token.constant('R_∞', 10973731.568160);

  static const Token elementaryCharge = Token.constant('q_e', 1.602176634e-19);
  static const Token vacuumPermitivity = Token.constant('ε_0', 8.8541878128e-12);
  static const Token vacuumPermeability = Token.constant('μ_0', 1.25663706212e-6);
  static const Token speedOfLight = Token.constant('c_0', 299792458);

  static const Token boltzmannConst = Token.constant('k_B', 1.380649e-23);
  static const Token avogadroConst = Token.constant('N_A', 6.02214076e23);
  static const Token gasConst = Token.constant('R', 8.31446261815324);

  static const Token gravitationConst = Token.constant('G', 6.67430e-11);
  static const Token earthGravity = Token.constant('g', 9.78033);

  static const Token standardAtmosphere = Token.constant('atm', 101325);
  static const Token radiusEarth = Token.constant('R_E', 6.3781e6);
  static const Token astronomicalUnit = Token.constant('au', 1.495978707e11);
  static const Token parsec = Token.constant('pc', 3.08567758128e16);
  static const Token lightYear = Token.constant('ly', 9.4607304725808e15);
}

enum AngleUnit { degree, radian }

const double _radianToDegreeFact = 360 / (2 * math.pi);

/// Collapses neighbouring numeric tokens into one numeric token and parses the value.
List<Token> _collapseNumerics(List<Token> tokenInputList) {
  List<Token> tokenOutputList = [];
  String collapsedSymbol = '';
  for (final Token token in tokenInputList) {
    if (token._type == _TokenType.numeric) {
      collapsedSymbol += token.symbol;
    } else {
      if (token._type == _TokenType.constant && collapsedSymbol == '-') {
        tokenOutputList.add(Token.constant(token.symbol, -token.value));
        collapsedSymbol = '';
        continue;
      }

      if (token == Token.subtract && collapsedSymbol.endsWith('E')) {
        collapsedSymbol += '-';
        continue;
      }

      if (collapsedSymbol == '-') {
        tokenOutputList.add(Token.subtract);
        collapsedSymbol = '';
      }

      if (collapsedSymbol.isNotEmpty) {
        num value = double.parse(collapsedSymbol);
        tokenOutputList.add(Token.numeric(collapsedSymbol, value));
        collapsedSymbol = '';
      }

      if (token == Token.subtract &&
          (tokenOutputList.isEmpty ||
              (tokenOutputList.last._type != _TokenType.numeric &&
                  tokenOutputList.last._type != _TokenType.constant &&
                  tokenOutputList.last._type != _TokenType.rightParenthesis &&
                  tokenOutputList.last.funcArgPos != FunctionArgumentPos.prefix))) {
        collapsedSymbol = '-';
        continue;
      }

      tokenOutputList.add(token);
    }
  }

  if (collapsedSymbol.isNotEmpty) {
    double value = double.parse(collapsedSymbol);
    tokenOutputList.add(Token.numeric(collapsedSymbol, value));
  }
  return tokenOutputList;
}

List<Token> _convertToRPN(List<Token> tokenList) {
  tokenList = _collapseNumerics(tokenList);

  Token lastNonParenthesis;
  for (final Token token in tokenList.reversed) {
    if (token._type != _TokenType.leftParenthesis && token._type != _TokenType.rightParenthesis) {
      lastNonParenthesis = token;
      break;
    }
  }

  if (lastNonParenthesis != null &&
      lastNonParenthesis._type == _TokenType.function &&
      lastNonParenthesis.funcArgPos == FunctionArgumentPos.suffix) {
    throw EvaluationException('Missing argument: ' + lastNonParenthesis.symbol);
  }

  if (tokenList.first == Token.subtract) {
    tokenList.insert(0, Token.zero);
  }

  // Shunting-yard algorithm to transform infix notation into Reverse Polish notation (RPN)
  // see: https://en.wikipedia.org/wiki/Shunting-yard_algorithm
  List<Token> stack = [];
  List<Token> output = [];
  Token prevToken;
  for (final Token token in tokenList) {
    switch (token._type) {
      case _TokenType.numeric:
        if (output.isNotEmpty) {
          if (prevToken._type == _TokenType.numeric ||
              prevToken._type == _TokenType.constant ||
              prevToken._type == _TokenType.rightParenthesis) {
            throw EvaluationException('Missing operator');
          }
        }
        output.add(token);
        break;
      case _TokenType.constant:
        if (output.isNotEmpty) {
          if (prevToken._type == _TokenType.numeric ||
              prevToken._type == _TokenType.constant ||
              prevToken._type == _TokenType.rightParenthesis) {
            stack.add(Token.multiply);
          }
        }
        output.add(token);
        break;
      case _TokenType.function:
        if (token.funcArgPos == FunctionArgumentPos.prefix) {
          output.add(token);
        } else {
          if (output.isNotEmpty) {
            if (prevToken._type == _TokenType.numeric ||
                prevToken._type == _TokenType.constant ||
                prevToken._type == _TokenType.rightParenthesis) {
              stack.add(Token.multiply);
            }
          }
          stack.add(token);
        }
        break;
      case _TokenType.operator:
        if (token == Token.subtract &&
            prevToken._type != _TokenType.numeric &&
            prevToken._type != _TokenType.constant &&
            prevToken._type != _TokenType.rightParenthesis &&
            prevToken.funcArgPos != FunctionArgumentPos.prefix) {
          output.add(const Token.numeric('-1', -1));
          stack.add(Token.multiply);
          break;
        }
        while (stack.isNotEmpty &&
            stack.last._type == _TokenType.operator &&
            (stack.last.associativity == OperatorAssociativity.left ||
                token.associativity == OperatorAssociativity.left) &&
            token.presedence <= stack.last.presedence) {
          output.add(stack.removeLast());
        }
        stack.add(token);
        break;
      case _TokenType.leftParenthesis:
        if (output.isNotEmpty) {
          if (prevToken._type == _TokenType.numeric ||
              prevToken._type == _TokenType.constant ||
              prevToken._type == _TokenType.rightParenthesis) {
            stack.add(Token.multiply);
          }
        }
        stack.add(token);
        break;
      case _TokenType.rightParenthesis:
        while (stack.isNotEmpty && stack.last._type != _TokenType.leftParenthesis) {
          output.add(stack.removeLast());
        }
        if (stack.isEmpty || stack.removeLast()._type != _TokenType.leftParenthesis) {
          throw EvaluationException('Missing opening parenthesis');
        }
        if (stack.isNotEmpty && stack.last._type == _TokenType.function) {
          output.add(stack.removeLast());
        }
        break;
    }

    prevToken = token;
  }

  while (stack.isNotEmpty) {
    if (stack.last._type != _TokenType.leftParenthesis) {
      output.add(stack.removeLast());
    } else {
      // We ignore too many opening parenthesis here.
      stack.removeLast();
    }
  }

  return output; // This is now in Reverse Polish notation. Hurray!
}

/// Evaluates the given [tokenList] and returns the result. If the [tokenList] is
/// malformated or errors happen during number collapsing, evaluation or executing
/// operations an appropriat [Exception] will be thrown.
num evaluate(List<Token> tokenList, [AngleUnit angleUnit = AngleUnit.radian]) {
  List<Token> rpnList = _convertToRPN(tokenList);

  // Evaluate the RPN output list.
  List<num> stack = [];
  for (final Token token in rpnList) {
    switch (token._type) {
      case _TokenType.function:
        if (token.isTrignometricFunction) {
          stack.add(token.mathFunc(
              stack.removeLast(), angleUnit == AngleUnit.degree ? _radianToDegreeFact : 1));
        } else {
          stack.add(token.mathFunc(stack.removeLast(), token.arg2));
        }
        break;
      case _TokenType.constant:
      case _TokenType.numeric:
        stack.add(token.value);
        break;
      case _TokenType.operator:
        if (stack.length < 2) {
          throw EvaluationException('Missing operand' + (stack.isEmpty ? 's' : ''));
        }
        switch (token) {
          case Token.add:
            stack.add(stack.removeLast() + stack.removeLast());
            break;
          case Token.subtract:
            num right = stack.removeLast();
            num left = stack.removeLast();
            stack.add(left - right);
            break;
          case Token.multiply:
            stack.add(stack.removeLast() * stack.removeLast());
            break;
          case Token.divide:
            num right = stack.removeLast();
            num left = stack.removeLast();
            stack.add(left / right);
            break;
          case Token.exponentiate:
            num right = stack.removeLast();
            num left = stack.removeLast();
            stack.add(math.pow(left, right));
            break;
        }
        break;
      case _TokenType.leftParenthesis:
      case _TokenType.rightParenthesis:
        // These tokens have been removed.
        break;
    }
  }

  if (stack.length > 1) {
    throw EvaluationException('Error');
  }

  return stack.removeLast();
}

enum Format { decimal, fraction, mixedFraction }

String _formatThousandSeparator(String input, String thousandSeparator) {
  int idx = input.indexOf('.');
  String out = idx == -1 ? '' : input.substring(idx);
  idx = idx == -1 ? input.length : idx;
  idx -= 3;
  for (; idx > 0; idx -= 3) {
    out = thousandSeparator + input.substring(idx, idx + 3) + out;
  }
  return input.substring(0, idx + 3) + out;
}

String _formatScientfic(num value, int significantDigits) {
  String retString = value
      .toStringAsExponential(significantDigits - 1)
      .replaceFirst('e', 'E')
      .replaceFirst('+', '');
  int idx = retString.indexOf('E') - 1;
  while (retString[idx] == '0') {
    idx--;
  }
  if (retString[idx] == '.') {
    idx--;
  }
  return retString.substring(0, idx + 1) + retString.substring(retString.indexOf('E'));
}

String _formatFixed(num value, int fractionDigits) {
  String retString = value.toStringAsFixed(math.max(fractionDigits, 0));

  int idx = retString.length - 1;
  while (retString[idx] == '0') {
    idx--;
  }
  if (retString[idx] == '.') {
    idx--;
  }
  return retString.substring(0, idx + 1);
}

String format(num value,
    {Format format = Format.decimal,
    double scientificLimit = 1E9,
    int significantDigits = 12,
    double maxFractionError = 1E-12,
    double maxDenominator = 1E5,
    String thousandSeparator = ' '}) {
  num abs = value.abs();

  if (abs.isInfinite) {
    throw EvaluationException('Overflow');
  }

  if ((abs - abs.truncateToDouble()) == 0) {
    // integer value
    if (abs >= scientificLimit) {
      return _formatScientfic(value, significantDigits);
    }
    return _formatThousandSeparator(value.truncate().toString(), thousandSeparator);
  }

  if (format != Format.decimal) {
    if ((abs < 1E3 || (format == Format.mixedFraction && abs < scientificLimit)) &&
        abs > 1 / maxDenominator) {
      return _formatFraction(value, format == Format.mixedFraction, maxFractionError,
          maxDenominator, thousandSeparator);
    }
  }

  if (abs >= scientificLimit) {
    return _formatScientfic(value, significantDigits);
  } else {
    if (abs < 1 / (scientificLimit)) {
      return _formatScientfic(value, significantDigits);
    } else {
      int nDigits = (math.log(abs) / math.ln10).truncate();
      if (nDigits >= 0) {
        return _formatThousandSeparator(
            _formatFixed(value, significantDigits - nDigits - 1), thousandSeparator);
      } else {
        // Scale up and add something in the order of double's mantissa precision to counter precision errors
        double scaled =
            abs * math.pow(10, significantDigits) + math.pow(10, significantDigits - 15);

        int remainder = scaled.truncate() % 10;
        if (remainder > 0) {
          return _formatScientfic(value, significantDigits);
        } else {
          return _formatThousandSeparator(
              _formatFixed(value, significantDigits - 1), thousandSeparator);
        }
      }
    }
  }
}

String _formatFraction(num value, bool mixed, double maxFractionError, double maxDenominator,
    String thousandSeparator) {
  // Richard's algorithm, modified from:  https://stackoverflow.com/a/42085412
  num sign = value.sign.toInt();

  num abs = value.abs();
  int n = abs.floor();
  abs -= n;

  double z = abs;
  int previousDenominator = 0;
  int denominator = 1;
  int numerator;

  do {
    z = 1 / (z - z.truncateToDouble());
    int temp = denominator;
    denominator = denominator * z.truncate() + previousDenominator;
    previousDenominator = temp;
    numerator = (abs * denominator).round();
  } while ((abs - numerator.toDouble() / denominator).abs() > maxFractionError &&
      z != z.truncateToDouble());

  if (denominator >= maxDenominator || denominator == 1) {
    return format(value, format: Format.decimal);
  }

  if (mixed) {
    int whole = n * sign;
    if (whole != 0) {
      return _formatThousandSeparator(whole.toString(), thousandSeparator) +
          ' {}^{$numerator}/{}_{$denominator}';
    }
    return '{}^{$numerator}/{}_{$denominator}';
  } else {
    numerator = (n * denominator + numerator) * sign;
    return '{}^{$numerator}/{}_{$denominator}';
  }
}

class EvaluationException implements Exception {
  final String message;

  EvaluationException([this.message]);

  @override
  String toString() {
    return message;
  }
}
