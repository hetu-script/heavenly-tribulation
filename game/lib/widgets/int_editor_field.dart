import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IntEditField extends StatelessWidget {
  const IntEditField({
    super.key,
    this.controller,
  });

  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      width: 40.0,
      height: 40.0,
      child: TextField(
        inputFormatters: [
          LengthLimitingTextInputFormatter(3),
          FilteringTextInputFormatter.digitsOnly,
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
