import 'package:flutter/material.dart';

import 'tex_span.dart';

class CursorText extends StatefulWidget {
  final List<TexSpan> spanComponents;
  final TextStyle style;
  final double cursorWidth;
  final Color cursorColor;
  final bool autofocus;
  final TextSpanEditingController controller;
  final ScrollController scrollController;
  final int componentPos;
  final Function onTap;

  const CursorText(
      {Key key,
      this.spanComponents,
      this.style,
      this.cursorWidth,
      this.cursorColor,
      this.autofocus,
      this.controller,
      this.scrollController,
      this.componentPos,
      this.onTap})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _CursorTextState();
}

class TextSpanEditingController extends TextEditingController {
  TextSpanEditingController({TextSpan textSpan})
      : _textSpan = textSpan,
        super();

  TextSpan _textSpan;

  @override
  TextSpan buildTextSpan({TextStyle style, bool withComposing}) {
    return _textSpan ?? TextSpan(text: '', style: style);
  }

  @override
  set text(String newText) {
    // This should never be reached.
    throw UnimplementedError();
  }

  @override
  bool isSelectionWithinTextBounds(TextSelection selection) {
    if (_textSpan == null) {
      return false;
    }
    return selection.start <= _textSpan.toPlainText().length &&
        selection.end <= _textSpan.toPlainText().length;
  }

  @override
  set value(TextEditingValue newValue) {
    if (newValue.selection.start >= 0) {
      super.value = newValue;
    }
  }
}

class _SelectableTextSelectionGestureDetectorBuilder extends TextSelectionGestureDetectorBuilder {
  final _CursorTextState _state;

  _SelectableTextSelectionGestureDetectorBuilder({@required _CursorTextState state})
      : _state = state,
        super(delegate: state);

  @override
  void onSingleLongTapMoveUpdate(LongPressMoveUpdateDetails details) {
    if (delegate.selectionEnabled) {
      renderEditable.selectPositionAt(
        from: details.globalPosition,
        to: details.globalPosition,
        cause: SelectionChangedCause.tap,
      );
      if (_state.widget.onTap != null) {
        _state.widget.onTap();
      }
    }
  }

  @override
  void onSingleLongTapEnd(LongPressEndDetails details) {
    if (delegate.selectionEnabled) {
      renderEditable.selectPositionAt(
        from: details.globalPosition,
        to: details.globalPosition,
        cause: SelectionChangedCause.tap,
      );
    }
    if (_state.widget.onTap != null) {
      _state.widget.onTap();
    }
  }

  @override
  void onSingleTapUp(TapUpDetails details) {
    if (delegate.selectionEnabled) {
      renderEditable.selectPosition(cause: SelectionChangedCause.tap);
    }
    if (_state.widget.onTap != null) {
      _state.widget.onTap();
    }
  }
}

class _CursorTextState extends State<CursorText>
    implements TextSelectionGestureDetectorBuilderDelegate {
  @override
  final GlobalKey<EditableTextState> editableTextKey = GlobalKey<EditableTextState>();

  _SelectableTextSelectionGestureDetectorBuilder _selectionGestureDetectorBuilder;
  final FocusNode _focusNode = FocusNode();
  TextSpanEditingController _controller;
  ScrollController _scrollController;
  double _lastScrollExtend;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextSpanEditingController();
    _selectionGestureDetectorBuilder = _SelectableTextSelectionGestureDetectorBuilder(state: this);
    _scrollController = widget.scrollController ?? ScrollController();
    _lastScrollExtend = 0;
  }

  @override
  void dispose() {
    widget.controller ?? _controller.dispose();
    widget.scrollController ?? _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    TextStyle effectiveTextStyle = widget.style;
    if (widget.style == null || widget.style.inherit) {
      effectiveTextStyle = defaultTextStyle.style.merge(widget.style);
    }

    TexSpan texSpan;
    TexSpan subCursorSpan;
    int cursorPos = 0;
    int componentPos = 0;
    for (final comp in widget.spanComponents) {
      if (texSpan == null) {
        texSpan = comp;
      } else {
        texSpan = texSpan.merge(comp);
      }
      if (componentPos < widget.componentPos) {
        cursorPos += comp.toPlainText().length;
        if (componentPos == widget.componentPos - 1) {
          subCursorSpan = texSpan.copy();
        }
      }
      componentPos++;
    }

    texSpan ?? _controller.clear();
    texSpan ??= TexSpan('', effectiveTextStyle);
    _controller._textSpan = texSpan;
    _controller.selection = TextSelection.collapsed(offset: cursorPos);

    TextPainter painter = TextPainter(
        textDirection: TextDirection.ltr,
        text: subCursorSpan ?? TextSpan(text: '', style: effectiveTextStyle));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      double curPosition = _scrollController.position.pixels;
      painter.layout();
      if (curPosition + _scrollController.position.viewportDimension <= painter.width ||
          curPosition >= painter.width ||
          _scrollController.position.pixels > _scrollController.position.maxScrollExtent) {
        curPosition += _scrollController.position.maxScrollExtent - _lastScrollExtend;
        _scrollController.animateTo(curPosition,
            curve: Curves.ease, duration: const Duration(milliseconds: 10));
      }
      _lastScrollExtend = _scrollController.position.maxScrollExtent;
    });

    return _selectionGestureDetectorBuilder.buildGestureDetector(
        behavior: HitTestBehavior.translucent,
        child: EditableText(
          key: editableTextKey,
          controller: _controller,
          focusNode: _focusNode,
          style: effectiveTextStyle,
          cursorColor: widget.cursorColor,
          backgroundCursorColor: Colors.transparent,
          readOnly: true,
          showCursor: true,
          autofocus: widget.autofocus,
          rendererIgnoresPointer: true,
          cursorWidth: widget.cursorWidth,
          forceLine: false,
          scrollController: _scrollController,
          toolbarOptions:
              const ToolbarOptions(copy: false, cut: false, paste: false, selectAll: false),
        ));
  }

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => true;
}
