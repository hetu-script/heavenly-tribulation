import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IntTextInputFormatter extends TextInputFormatter {
  final int maxLength;
  final int? maxValue, minValue;
  final bool allowNegative;

  IntTextInputFormatter({
    this.maxLength = 3,
    this.maxValue,
    this.minValue,
    this.allowNegative = false,
  });

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final int? value = int.tryParse(newValue.text);
    if (value == null) return TextEditingValue();

    if (value.abs().toString().length > maxLength) {
      return oldValue;
    }

    if (maxValue != null && value > maxValue!) {
      return oldValue;
    }

    if (minValue != null && value < minValue!) {
      return oldValue;
    }

    if (value < 0 && !allowNegative) {
      return oldValue;
    }

    return TextEditingValue(text: value.toString());
  }
}

class IntEditField extends StatelessWidget {
  static final TextInputFormatter integerOnly =
      FilteringTextInputFormatter.allow(RegExp(r'^-?\d+$'));

  const IntEditField({
    super.key,
    this.controller,
    this.maxLength = 3,
    this.maxValue,
    this.minValue,
    this.allowNegative = false,
    this.width = 40.0,
    this.height = 40.0,
  });

  final int maxLength;
  final int? maxValue, minValue;
  final bool allowNegative;

  final double width, height;

  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      width: width,
      height: height,
      child: TextField(
        inputFormatters: [
          FilteringTextInputFormatter.singleLineFormatter,
          IntTextInputFormatter(
            maxLength: maxLength,
            maxValue: maxValue,
            minValue: minValue,
            allowNegative: allowNegative,
          ),
        ],
        keyboardType: const TextInputType.numberWithOptions(
          signed: false,
          decimal: false,
        ),
        textAlign: TextAlign.center,
        controller: controller,
      ),
    );
  }
}
