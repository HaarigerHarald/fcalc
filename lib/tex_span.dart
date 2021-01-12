import 'package:flutter/material.dart';

enum _ScriptPos { normal, subscript, superscript }

/// A TextSpan rendering TeX style sub and superscripts via different fonts.
class TexSpan extends TextSpan {
  static const String _superScriptChar = '^';
  static const String _subScriptChar = '_';
  static const String _oBrace = '{';
  static const String _cBrace = '}';

  static InlineSpan getScriptSpan(String text, TextStyle style, _ScriptPos scriptPos) {
    return TextSpan(
        text: text,
        style: style.copyWith(
            fontFamily: scriptPos == _ScriptPos.subscript ? 'RobotoSub' : 'RobotoSuper',
            letterSpacing: 1.0));
  }

  static List<InlineSpan> createChildren(String text, TextStyle style) {
    final RuneIterator iter = text.runes.iterator;
    int lastKeyPos = 0;

    List<InlineSpan> children = [];
    int revertToNormalScriptPos = -1;
    _ScriptPos curPos = _ScriptPos.normal;

    for (int i = 0; iter.moveNext(); i++) {
      switch (iter.currentAsString) {
        case _oBrace:
          if (i > lastKeyPos) {
            children.add(TextSpan(text: text.substring(lastKeyPos, i), style: style));
          }
          revertToNormalScriptPos = -1;
          lastKeyPos = i + 1;
          break;
        case _cBrace:
          if (curPos != _ScriptPos.normal && lastKeyPos < i) {
            children.add(getScriptSpan(text.substring(lastKeyPos, i), style, curPos));
          }
          revertToNormalScriptPos = -1;
          lastKeyPos = i + 1;
          curPos = _ScriptPos.normal;
          break;
        case _subScriptChar:
          if (lastKeyPos < i) {
            children.add(TextSpan(text: text.substring(lastKeyPos, i), style: style));
          }
          curPos = _ScriptPos.subscript;
          lastKeyPos = i + 1;
          revertToNormalScriptPos = i + 2;
          break;
        case _superScriptChar:
          if (lastKeyPos < i) {
            children.add(TextSpan(text: text.substring(lastKeyPos, i), style: style));
          }
          curPos = _ScriptPos.superscript;
          lastKeyPos = i + 1;
          revertToNormalScriptPos = i + 2;
          break;
        default:
          if (curPos != _ScriptPos.normal) {
            if (revertToNormalScriptPos == i) {
              children.add(getScriptSpan(text.substring(lastKeyPos, i), style, curPos));
              revertToNormalScriptPos = -1;
              lastKeyPos = i;
              curPos = _ScriptPos.normal;
            }
          }
      }
    }

    if (lastKeyPos < text.length) {
      if (curPos == _ScriptPos.normal) {
        children.add(TextSpan(text: text.substring(lastKeyPos), style: style));
      } else {
        children.add(getScriptSpan(text.substring(lastKeyPos), style, curPos));
      }
    }
    return children;
  }

  factory TexSpan(String text, TextStyle style,
      {double scriptFontSize, double scriptOffset, bool scriptDisabled = false}) {
    if (text.length <= 1 ||
        (!text.contains(_superScriptChar) &&
            !text.contains(_subScriptChar) &&
            !text.contains(_oBrace) &&
            !text.contains(_cBrace))) {
      return TexSpan._(text: text, style: style);
    }

    return TexSpan._(children: createChildren(text, style), style: style);
  }

  const TexSpan._({String text, List<InlineSpan> children, TextStyle style})
      : super(text: text, children: children, style: style);

  static int calcRenderedTextLength(String text) {
    if (text.length > 1) {
      return text
          .replaceAll(_cBrace, '')
          .replaceAll(_oBrace, '')
          .replaceAll(_subScriptChar, '')
          .replaceAll(_superScriptChar, '')
          .length;
    }
    return text.length;
  }

  TexSpan merge(TexSpan other) {
    List<InlineSpan> combinedChildren = children ?? [];
    if (text != null) {
      combinedChildren.add(TextSpan(text: text, style: style));
    }
    if (other.text != null || other.children == null) {
      combinedChildren.add(TextSpan(text: other.text, style: other.style));
    } else {
      combinedChildren.addAll(other.children);
    }

    return TexSpan._(children: combinedChildren, style: style);
  }

  TexSpan copy() {
    return children == null
        ? TexSpan._(text: text, style: style)
        : TexSpan._(children: [...children], style: style);
  }
}
