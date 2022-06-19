import 'package:flutter/material.dart';

/// An item with sub menu for using in popup menus
///
/// [title] is the text which will be displayed in the pop up
/// [values] is the list of items to populate the sub menu
/// [onSelected] is the callback to be fired if specific item is pressed
///
/// Selecting items from the submenu will automatically close the parent menu
/// Closing the sub menu by clicking outside of it, will automatically close the parent menu
class PopupSubMenuItem<T> extends PopupMenuEntry<T> {
  const PopupSubMenuItem(
      {Key? key,
      required this.title,
      required this.items,
      this.offset = Offset.zero,
      this.onSelected,
      this.textStyle})
      : super(key: key);

  final String title;
  final Offset offset;
  final Map<String, T> items;
  final Function(T)? onSelected;
  final TextStyle? textStyle;

  @override
  double get height => 24;

  @override
  bool represents(T? value) =>
      false; //Our submenu does not represent any specific value for the parent menu

  @override
  State createState() => _PopupSubMenuState<T>();
}

/// The [State] for [PopupSubMenuItem] subclasses.
class _PopupSubMenuState<T> extends State<PopupSubMenuItem<T>> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PopupMenuThemeData popupMenuTheme = PopupMenuTheme.of(context);
    TextStyle style = widget.textStyle ??
        popupMenuTheme.textStyle ??
        theme.textTheme.subtitle1!;

    return PopupMenuButton<T>(
      tooltip: '',
      onCanceled: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      onSelected: (T value) {
        if (Navigator.canPop(context)) {
          Navigator.pop<T>(context, value);
        }
        widget.onSelected?.call(value);
      },
      offset: widget.offset,
      itemBuilder: (BuildContext context) {
        final items = <PopupMenuEntry<T>>[];
        for (final key in widget.items.keys) {
          final value = widget.items[key];
          items.add(PopupMenuItem<T>(
            height: 24.0,
            value: value,
            child: Text(key, style: style),
          ));
        }
        return items;
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Text(widget.title, style: style),
            ),
            Icon(
              Icons.arrow_right,
              size: 24.0,
              color: Theme.of(context).iconTheme.color,
            ),
          ],
        ),
      ),
    );
  }
}
