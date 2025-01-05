import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import '../ui.dart';

enum DropdownMenuButtonStyle {
  normal,
  underline,
  border,
}

class DropdownMenuButton<T> extends StatelessWidget {
  const DropdownMenuButton({
    super.key,
    this.hint,
    this.selected,
    required this.selections,
    this.onChanged,
    this.style = DropdownMenuButtonStyle.normal,
  });

  final Widget? hint;
  final T? selected;

  /// Key is for display, value is for selected value returned.
  final Map<String, T> selections;

  final void Function(T? newValue)? onChanged;

  final DropdownMenuButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final button = DropdownButton2<T>(
      style: Theme.of(context).textTheme.titleSmall,
      hint: hint,
      menuItemStyleData: const MenuItemStyleData(height: 35.0),
      dropdownStyleData: DropdownStyleData(
        decoration: BoxDecoration(
          border: Border.all(color: GameUI.foregroundColor),
          borderRadius: BorderRadius.circular(5.0),
        ),
      ),
      isExpanded: true,
      value: selected,
      items: selections.keys
          .map(
            (key) => DropdownMenuItem<T>(
              value: selections[key],
              child: Text(key),
            ),
          )
          .toList(),
      onChanged: (newValue) => onChanged?.call(newValue),
    );

    return InputDecorator(
      decoration: InputDecoration(
        border: style == DropdownMenuButtonStyle.border
            ? const OutlineInputBorder()
            : null,
        contentPadding: const EdgeInsets.all(0.0),
      ),
      child: style == DropdownMenuButtonStyle.underline
          ? button
          : DropdownButtonHideUnderline(child: button),
    );
  }
}
