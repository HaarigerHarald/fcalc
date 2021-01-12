import 'package:test/test.dart';

import 'package:fcalc/evaluator.dart';

void main() {
  test('Math evaluation test', () {
    expect(evaluate([Token.one, Token.add, Token.one]), 2);

    expect(
        evaluate(
            [Token.subtract, Token.leftParenthesis, Token.one, Token.one, Token.add, Token.one]),
        -12);

    expect(
        evaluate([
          Token.subtract,
          Token.sin,
          Token.leftParenthesis,
          Token.subtract,
          Token.leftParenthesis,
          Token.four,
          Token.pi
        ]),
        0);
  });
}
