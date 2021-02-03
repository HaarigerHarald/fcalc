import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tex_span.dart';
import 'evaluator.dart';
import 'model.dart';

class CalcButton extends StatelessWidget {
  const CalcButton(
      {Key key,
      this.symbol,
      this.tokens,
      this.requiresArg2 = false,
      this.arg2Title,
      this.arg2Min = double.negativeInfinity,
      this.arg2Max = double.infinity,
      this.arg2Placeholder = 'x',
      this.textStyle = const TextStyle(fontSize: 28, height: 1.2),
      this.buttonIcon,
      this.expressionModel,
      this.onPressed,
      this.tooltip})
      : super(key: key);

  final String symbol;
  final List<Token> tokens;
  final bool requiresArg2;
  final String arg2Title;
  final double arg2Min;
  final double arg2Max;
  final String arg2Placeholder;

  final TextStyle textStyle;
  final IconData buttonIcon;
  final ExpressionModel expressionModel;
  final Function onPressed;
  final String tooltip;

  Future<void> _showExtraArgumentDialog(BuildContext context) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return _Arg2Dialog(
              expressionModel: expressionModel,
              tokens: tokens,
              arg2Title: arg2Title,
              arg2Min: arg2Min,
              arg2Max: arg2Max,
              arg2Placeholder: arg2Placeholder);
        });
  }

  Widget _buildButton(BuildContext context) {
    Color foregroundColor = Theme.of(context).textTheme.button.color;
    return Container(
        padding: EdgeInsets.all(math.min(MediaQuery.of(context).size.width * 0.007, 7)),
        height: double.infinity,
        child: RawMaterialButton(
            elevation: 1,
            fillColor: Theme.of(context).buttonColor,
            child: buttonIcon == null
                ? RichText(
                    text: TexSpan(
                        symbol ?? tokens[0].symbol, textStyle.copyWith(color: foregroundColor)))
                : Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Icon(buttonIcon, size: 29, color: foregroundColor)),
            onPressed: () {
              if (onPressed != null) {
                onPressed();
              } else {
                if (requiresArg2) {
                  _showExtraArgumentDialog(context);
                } else {
                  expressionModel.add(tokens);
                }
              }
            },
            shape: RoundedRectangleBorder(
                side: Theme.of(context).brightness == Brightness.dark
                    ? BorderSide(color: Colors.grey[200], width: 1.5, style: BorderStyle.solid)
                    : BorderSide(color: Colors.grey[400], width: 0.5, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(
                    math.min(MediaQuery.of(context).size.width * 0.03, 20)))));
  }

  @override
  Widget build(BuildContext context) {
    if (tooltip == null) {
      return Expanded(child: _buildButton(context));
    } else {
      return Expanded(
          child: Tooltip(
              message: tooltip,
              preferBelow: false,
              verticalOffset: 40,
              padding: const EdgeInsets.all(10),
              textStyle: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black
                      : Colors.white),
              child: _buildButton(context)));
    }
  }
}

class _Arg2Dialog extends StatefulWidget {
  final ExpressionModel expressionModel;

  final List<Token> tokens;
  final String arg2Title;
  final double arg2Min;
  final double arg2Max;
  final String arg2Placeholder;

  const _Arg2Dialog(
      {Key key,
      @required this.expressionModel,
      this.tokens,
      this.arg2Title,
      this.arg2Min,
      this.arg2Max,
      this.arg2Placeholder})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _Arg2DialogState();
}

class _Arg2DialogState extends State<_Arg2Dialog> {
  TextEditingController _textController;
  bool _invalidArgument = false;

  @override
  void initState() {
    _textController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _textController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
      title: Text(widget.arg2Title),
      content: TextField(
          controller: _textController,
          maxLines: 1,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
          style: const TextStyle(fontSize: 21),
          decoration: InputDecoration(
            errorText: _invalidArgument ? 'Invalid argument' : null,
            errorStyle: const TextStyle(fontSize: 16),
          )),
      actions: [
        TextButton(
            child:
                Text('CANCEL', style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 15)),
            onPressed: () => Navigator.pop(context)),
        TextButton(
          child: Text('OK', style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 15)),
          onPressed: () {
            double arg2 = double.tryParse(_textController.text);
            if (arg2 == null || arg2 < widget.arg2Min || arg2 > widget.arg2Max) {
              setState(() {
                _invalidArgument = true;
              });
              return;
            }

            List<Token> tokens = [...widget.tokens];
            tokens[0] = Token.function(
                tokens[0].symbol.replaceAll(widget.arg2Placeholder, _textController.text),
                tokens[0].mathFunc,
                arg2: arg2);

            widget.expressionModel.add(tokens);

            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
