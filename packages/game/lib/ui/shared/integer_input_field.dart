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
  final double buttonWidth;
  final double buttonHeight;
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
    this.buttonWidth = 48,
    this.buttonHeight = 24,
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
    _updateButtons(int.tryParse(_controller.text));
  }

  @override
  void didUpdateWidget(covariant IntegerInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller = widget.controller ?? _controller;
    _focusNode = widget.focusNode ?? _focusNode;
    _updateButtons(int.tryParse(_controller.text));
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
              maxHeight: widget.buttonHeight, maxWidth: widget.buttonWidth),
          prefixIcon: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(widget.borderWidth),
                    bottomRight: Radius.circular(widget.borderWidth))),
            clipBehavior: Clip.antiAlias,
            margin: EdgeInsets.only(
                top: widget.borderWidth,
                right: widget.borderWidth,
                bottom: widget.borderWidth,
                left: widget.borderWidth),
            child: Material(
              type: MaterialType.transparency,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _canGoDown
                          ? () => _update(absolute: widget.min)
                          : null,
                      child: Opacity(
                        opacity: _canGoDown ? 1 : 0.5,
                        child: const Text('MIN'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: _canGoDown
                          ? () => _update(relative: -widget.step)
                          : null,
                      child: Opacity(
                        opacity: _canGoDown ? 1 : 0.5,
                        child: const Icon(Icons.remove),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          suffixIconConstraints: BoxConstraints(
              maxHeight: widget.buttonHeight, maxWidth: widget.buttonWidth),
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
                left: widget.borderWidth),
            child: Material(
              type: MaterialType.transparency,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _canGoUp
                          ? () => _update(relative: widget.step)
                          : null,
                      child: Opacity(
                        opacity: _canGoUp ? 1 : 0.5,
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap:
                          _canGoUp ? () => _update(absolute: widget.max) : null,
                      child: Opacity(
                        opacity: _canGoUp ? 1 : 0.5,
                        child: const Text('MAX'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        maxLines: 1,
        onChanged: (value) {
          final intValue = int.tryParse(value);
          widget.onChanged?.call(intValue);
          _updateButtons(intValue);
        },
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          _NumberTextInputFormatter(widget.min, widget.max)
        ],
      );

  void _update({int? relative, int? absolute}) {
    if (relative != null) {
      var intValue = int.tryParse(_controller.text);
      intValue == null ? intValue = 0 : intValue += relative;
      _updateButtons(intValue);
      _controller.text = intValue.toString();
    } else if (absolute != null) {
      if (absolute < widget.min) absolute = widget.min;
      if (absolute > widget.max) absolute = widget.max;
      _updateButtons(absolute);
      _controller.text = absolute.toString();
    }
    // _focusNode.requestFocus();
  }

  void _updateButtons(int? value) {
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
