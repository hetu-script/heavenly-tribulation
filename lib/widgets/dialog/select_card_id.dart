import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../global.dart';
import '../ui/dropdown_menu_button.dart';
import '../ui/close_button2.dart';
import '../ui/responsive_view.dart';
import '../../ui.dart';
import '../../data/common.dart';

class SelectCardIdDialog extends StatefulWidget {
  static Future<(String, String, String)?> show({
    required BuildContext context,
    String? title,
    bool barrierDismissible = true,
  }) {
    return showDialog<(String, String, String)?>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return SelectCardIdDialog(
          title: title,
          barrierDismissible: barrierDismissible,
        );
      },
    );
  }

  const SelectCardIdDialog({
    super.key,
    this.title,
    this.barrierDismissible = true,
  });

  final String? title;
  final bool barrierDismissible;

  @override
  State<SelectCardIdDialog> createState() => _SelectCardIdDialogState();
}

class _SelectCardIdDialogState extends State<SelectCardIdDialog> {
  Iterable<String> availableCategories = {};
  Iterable<String> availableRarities = {};
  Iterable<String> availableGenres = {};
  Iterable<String>? availableIds;

  late String _selectedCategory;
  late String _selectedRarity;
  late String _selectedGenre;

  @override
  void initState() {
    super.initState();

    availableCategories = kBattleCardCategories;
    availableRarities = kRarities;
    availableGenres = kBattleCardGenres;

    _selectedCategory = availableCategories.first;
    _selectedRarity = availableRarities.first;
    _selectedGenre = availableGenres.first;

    availableIds = kBattleCardKindsByCategory[_selectedCategory]
        ?[_selectedRarity]?[_selectedGenre];
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      barrierDismissible: widget.barrierDismissible,
      barrierColor: null,
      backgroundColor: GameUI.backgroundColorOpaque,
      width: 400,
      height: 200,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.title ?? engine.locale('select')),
          actions: const [CloseButton2()],
        ),
        body: Container(
          alignment: AlignmentDirectional.center,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              SizedBox(
                width: 480.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 120.0,
                      child: DropdownMenuButton(
                        selected: _selectedCategory,
                        selections: {
                          for (final key in availableCategories)
                            engine.locale(key): key
                        },
                        onChanged: (newValue) {
                          _selectedCategory = newValue!;
                          setState(() {});
                        },
                      ),
                    ),
                    SizedBox(
                      width: 120.0,
                      child: DropdownMenuButton(
                        selected: _selectedRarity,
                        selections: {
                          for (final key in availableRarities)
                            engine.locale(key): key
                        },
                        onChanged: (newValue) {
                          _selectedRarity = newValue!;
                          setState(() {});
                        },
                      ),
                    ),
                    SizedBox(
                      width: 120.0,
                      child: DropdownMenuButton(
                        selected: _selectedGenre,
                        selections: {
                          for (final key in availableGenres)
                            engine.locale(key): key
                        },
                        onChanged: (newValue) {
                          _selectedGenre = newValue!;
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: fluent.Button(
                  onPressed: () {
                    Navigator.of(context).pop((
                      _selectedCategory,
                      _selectedRarity,
                      _selectedGenre,
                    ));
                  },
                  child: Text(
                    engine.locale('confirm'),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
