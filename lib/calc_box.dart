import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:provider/provider.dart';

import 'cursor_text.dart';
import 'evaluator.dart';
import 'model.dart';
import 'tex_span.dart';

class CalcBoxContainer extends StatelessWidget {
  final CalculatorModel model;
  const CalcBoxContainer({Key key, @required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        height: math.min(MediaQuery.of(context).size.height * 0.25, 350),
        padding: const EdgeInsets.only(top: 6, bottom: 3, left: 3, right: 3),
        child: Container(
            decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[600]
                      : Colors.grey[500],
                ),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.10)),
                  BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[900]
                          : const Color(0xFFFBFBFB),
                      spreadRadius: -3.0,
                      blurRadius: 7.0,
                      offset: const Offset(0, -1)),
                ]),
            child: Material(
              color: Colors.transparent,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              child: Consumer<ExpressionModel>(builder: (context, expressionModel, child) {
                return _CalcBox(expressionModel: expressionModel, model: model);
              }),
            )));
  }
}

class _CalcBox extends StatefulWidget {
  final ExpressionModel expressionModel;
  final CalculatorModel model;

  const _CalcBox({Key key, this.expressionModel, this.model}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CalcBoxState();
}

class _CalcBoxState extends State<_CalcBox> {
  TextSpanEditingController _textController;

  static const double _defaultResultFontSize = 34;

  @override
  void initState() {
    _textController = TextSpanEditingController();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _textController.dispose();
  }

  TexSpan _evaluate() {
    if (widget.expressionModel.isEmpty) {
      return TexSpan('', const TextStyle(fontSize: _defaultResultFontSize));
    }

    try {
      num result = evaluate(widget.expressionModel.expression, widget.model.angleUnit);
      return TexSpan(
          ' = ' +
              format(result,
                  format: widget.model.format,
                  significantDigits: widget.model.significantDigits,
                  scientificLimit: math.pow(10, widget.model.scientificNotationExponent).toDouble(),
                  thousandSeparator: widget.model.thousandSeparator),
          const TextStyle(fontSize: _defaultResultFontSize));
    } catch (e) {
      if (e is EvaluationException) {
        return TexSpan(e.toString(), TextStyle(fontSize: 24, color: Colors.red[800]));
      } else if (e is FormatException) {
        return TexSpan('Invalid number format', TextStyle(fontSize: 24, color: Colors.red[800]));
      }

      return TexSpan('Error', TextStyle(fontSize: 32, color: Colors.red[800]));
    }
  }

  Future _showAngleUnitDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Angle units'),
          children: [
            RadioListTile<AngleUnit>(
                title: const Text('Radian'),
                value: AngleUnit.radian,
                groupValue: widget.model.angleUnit,
                activeColor: Theme.of(context).accentColor,
                onChanged: (AngleUnit value) {
                  Navigator.pop(context);
                  widget.model.angleUnit = value;
                }),
            RadioListTile<AngleUnit>(
              title: const Text('Degree'),
              value: AngleUnit.degree,
              groupValue: widget.model.angleUnit,
              activeColor: Theme.of(context).accentColor,
              onChanged: (AngleUnit value) {
                Navigator.pop(context);
                widget.model.angleUnit = value;
              },
            ),
          ],
        );
      },
    );
  }

  Future _showFormatDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Display format'),
          children: [
            RadioListTile<Format>(
                title: const Text('Decimal'),
                value: Format.decimal,
                groupValue: widget.model.format,
                activeColor: Theme.of(context).accentColor,
                onChanged: (Format value) {
                  Navigator.of(context).pop();
                  widget.model.format = value;
                }),
            RadioListTile<Format>(
              title: const Text('Fraction'),
              value: Format.fraction,
              groupValue: widget.model.format,
              activeColor: Theme.of(context).accentColor,
              onChanged: (Format value) {
                widget.model.format = value;
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<Format>(
              title: const Text('Mixed'),
              value: Format.mixedFraction,
              groupValue: widget.model.format,
              activeColor: Theme.of(context).accentColor,
              onChanged: (Format value) {
                widget.model.format = value;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _getFormatLabel() {
    switch (widget.model.format) {
      case Format.decimal:
        return 'DECIMAL';
      case Format.fraction:
        return 'FRACTION';
      case Format.mixedFraction:
        return 'MIXED';
    }
    return '';
  }

  void _syncCursorPos() {
    if (_textController.selection.start == 0) {
      widget.expressionModel.componentPos = 0;
      return;
    }

    int textPos = 0;
    int compPos = 0;
    for (final String comp in widget.expressionModel.textComponents) {
      int curLen = TexSpan.calcRenderedTextLength(comp);
      textPos += curLen;
      compPos++;
      if (textPos > _textController.selection.start) {
        if (curLen > 2 && textPos - curLen + 1 == _textController.selection.start) {
          widget.expressionModel.componentPos = compPos - 1;
          _textController.selection = TextSelection.collapsed(offset: textPos - curLen);
        } else {
          widget.expressionModel.componentPos = compPos;
          _textController.selection = TextSelection.collapsed(offset: textPos);
        }
        break;
      } else if (textPos == _textController.selection.start) {
        widget.expressionModel.componentPos = compPos;
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<TexSpan> spanComponents = [];
    List<String> textComponents = widget.expressionModel.textComponents;
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    TextStyle effectiveTextStyle = defaultTextStyle.style
        .merge(const TextStyle(fontSize: 26.0, height: 1.6, letterSpacing: 1.1));

    for (int i = 0; i < textComponents.length; i++) {
      if (widget.expressionModel[i][0].type == TokenType.operator) {
        spanComponents.add(TexSpan(textComponents[i],
            effectiveTextStyle.copyWith(color: Theme.of(context).accentTextTheme.bodyText1.color)));
      } else {
        spanComponents.add(TexSpan(textComponents[i], effectiveTextStyle));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
            flex: 8,
            child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    width: double.infinity,
                    child: CursorText(
                      spanComponents: spanComponents,
                      style: effectiveTextStyle,
                      autofocus: true,
                      cursorWidth: 3,
                      cursorColor: Theme.of(context).primaryColor,
                      controller: _textController,
                      componentPos: widget.expressionModel.componentPos,
                      onTap: () => _syncCursorPos(),
                    )))),
        Flexible(
            flex: 10,
            child: Consumer<CalculatorModel>(builder: (context, model, child) {
              return Stack(children: [
                Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                        padding: const EdgeInsets.only(left: 6, bottom: 24, right: 6),
                        child: AutoSizeText.rich(_evaluate(), maxLines: 1, minFontSize: 10))),
                Align(
                    alignment: Alignment.bottomLeft,
                    child: InkWell(
                      borderRadius: const BorderRadius.all(Radius.circular(7)),
                      onTap: () => _showAngleUnitDialog(),
                      child: Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10, top: 7, bottom: 7),
                          child: Text(
                            'ANGLE ' + (model.angleUnit == AngleUnit.radian ? 'RAD' : 'DEG'),
                            style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[800]),
                          )),
                    )),
                Align(
                    alignment: Alignment.bottomRight,
                    child: InkWell(
                        borderRadius: const BorderRadius.all(Radius.circular(7)),
                        onTap: () => _showFormatDialog(),
                        child: Padding(
                            padding: const EdgeInsets.only(left: 10, bottom: 7, top: 7, right: 10),
                            child: Text(_getFormatLabel(),
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey[400]
                                        : Colors.grey[800]))))),
              ]);
            })),
      ],
    );
  }
}
