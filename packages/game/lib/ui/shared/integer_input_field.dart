import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../global.dart';

class IntegerInputField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final int? initValue;
  final int min;
  final int max;
  final int step;
  final double arrowsWidth;
  final double arrowsHeight;
  final EdgeInsets contentPadding;
  final double borderWidth;
  final ValueChanged<int?>? onChanged;
  final bool readOnly;

  const IntegerInputField({
    Key? key,
    this.controller,
    this.focusNode,
    this.initValue,
    required this.min,
    required this.max,
    this.step = 1,
    this.arrowsWidth = 24,
    this.arrowsHeight = 24,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 0.0),
    this.borderWidth = 2,
    this.onChanged,
    this.readOnly = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _IntegerInputFieldState();
}

class _IntegerInputFieldState extends State<IntegerInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _canGoUp = false;
  bool _canGoDown = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.text = widget.initValue != null
        ? widget.initValue.toString()
        : widget.min.toString();
    _focusNode = widget.focusNode ?? FocusNode();
    _updateArrows(int.tryParse(_controller.text));
  }

  @override
  void didUpdateWidget(covariant IntegerInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller = widget.controller ?? _controller;
    _focusNode = widget.focusNode ?? _focusNode;
    _updateArrows(int.tryParse(_controller.text));
  }

  @override
  Widget build(BuildContext context) => TextField(
        readOnly: widget.readOnly,
        controller: _controller,
        focusNode: _focusNode,
        textAlign: TextAlign.center,
        textInputAction: TextInputAction.done,
        keyboardType: TextInputType.number,
        maxLength:
            widget.max.toString().length + (widget.min.isNegative ? 1 : 0),
        cursorColor: kForegroundColor,
        decoration: InputDecoration(
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey, width: 1.0),
          ),
          border: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey, width: 0.0),
          ),
          counterText: '',
          isDense: true,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: widget.contentPadding,
          prefixIconConstraints: BoxConstraints(
              maxHeight: widget.arrowsHeight,
              maxWidth: widget.arrowsWidth + widget.contentPadding.left),
          prefixIcon: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(widget.borderWidth),
                    bottomRight: Radius.circular(widget.borderWidth))),
            clipBehavior: Clip.antiAlias,
            margin: EdgeInsets.only(
                top: widget.borderWidth,
                right: widget.contentPadding.right,
                bottom: widget.borderWidth,
                left: widget.borderWidth),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: _canGoDown ? () => _update(false) : null,
                child: Opacity(
                  opacity: _canGoDown ? 1 : .5,
                  child: const Icon(Icons.remove),
                ),
              ),
            ),
          ),
          suffixIconConstraints: BoxConstraints(
              maxHeight: widget.arrowsHeight,
              maxWidth: widget.arrowsWidth + widget.contentPadding.right),
          suffixIcon: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(widget.borderWidth),
                    bottomRight: Radius.circular(widget.borderWidth))),
            clipBehavior: Clip.antiAlias,
            margin: EdgeInsets.only(
                top: widget.borderWidth,
                right: widget.borderWidth,
                bottom: widget.borderWidth,
                left: widget.contentPadding.right),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: _canGoUp ? () => _update(true) : null,
                child: Opacity(
                  opacity: _canGoUp ? 1 : .5,
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ),
        ),
        maxLines: 1,
        onChanged: (value) {
          final intValue = int.tryParse(value);
          widget.onChanged?.call(intValue);
          _updateArrows(intValue);
        },
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          _NumberTextInputFormatter(widget.min, widget.max)
        ],
      );

  void _update(bool up) {
    var intValue = int.tryParse(_controller.text);
    intValue == null
        ? intValue = 0
        : intValue += up ? widget.step : -widget.step;
    _controller.text = intValue.toString();
    _updateArrows(intValue);
    // _focusNode.requestFocus();
  }

  void _updateArrows(int? value) {
    final canGoUp = value == null || value < widget.max;
    final canGoDown = value == null || value > widget.min;
    if (_canGoUp != canGoUp || _canGoDown != canGoDown) {
      setState(() {
        _canGoUp = canGoUp;
        _canGoDown = canGoDown;
      });
    }
  }
}

class _NumberTextInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  _NumberTextInputFormatter(this.min, this.max);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (const ['-', ''].contains(newValue.text)) return newValue;
    final intValue = int.tryParse(newValue.text);
    if (intValue == null) return oldValue;
    if (intValue < min) return newValue.copyWith(text: min.toString());
    if (intValue > max) return newValue.copyWith(text: max.toString());
    return newValue.copyWith(text: intValue.toString());
  }
}
