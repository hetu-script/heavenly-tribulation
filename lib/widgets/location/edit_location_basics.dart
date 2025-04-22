import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:samsara/extensions.dart' show StringEx;
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../../game/data.dart';
import '../../game/ui.dart';
import '../ui/menu_builder.dart';
import '../ui/close_button2.dart';

class EditLocationBasics extends StatefulWidget {
  /// 返回六个值的元组：
  /// category, kind, id, name, image, background
  const EditLocationBasics({
    super.key,
    this.id,
    this.category,
    this.kind,
    this.name,
    this.image,
    this.background,
    this.atLocation,
    this.allowEditCategory = true,
    this.allowEditKind = true,
    this.createNpc = false,
  });

  final String? id;
  final String? category;
  final String? kind;
  final String? name;
  final String? image;
  final String? background;
  final dynamic atLocation;
  final bool allowEditCategory, allowEditKind;
  final bool createNpc;

  @override
  State<EditLocationBasics> createState() => _EditLocationBasicsState();
}

class _EditLocationBasicsState extends State<EditLocationBasics> {
  final _idEditingController = TextEditingController();
  final _nameEditingController = TextEditingController();
  final _imageEditingController = TextEditingController();
  final _backgroundEditingController = TextEditingController();

  String? _selectedCategory;
  String? _selectedKind;

  final Map<String, String> _categories = {};
  final Map<String, String> _kinds = {};

  bool _createNpc = false;

  @override
  void initState() {
    super.initState();

    _categories['custom'] = engine.locale('custom');
    _categories['city'] = engine.locale('city');
    _categories['site'] = engine.locale('site');

    if (widget.category != null) {
      setCategoryKind(category: widget.category, kind: widget.kind);
    } else {
      setCategoryKind(category: 'custom');
    }

    _idEditingController.text = widget.id ?? '';
    _nameEditingController.text = widget.name ?? '';
    _imageEditingController.text = widget.image ?? '';
    _backgroundEditingController.text = widget.background ?? '';

    _createNpc = widget.createNpc;
  }

  @override
  void dispose() {
    super.dispose();

    _idEditingController.dispose();
    _nameEditingController.dispose();
    _imageEditingController.dispose();
    _backgroundEditingController.dispose();
  }

  void setCategoryKind({String? category, String? kind}) {
    if (category == null && kind == null) {
      return;
    }

    if (category != null) {
      _selectedCategory = category;

      _kinds.clear();
      _kinds['custom'] = engine.locale('custom');

      if (_selectedCategory == 'city') {
        _kinds.addAll(GameData.cityKindNames);
      } else if (_selectedCategory == 'site') {
        _kinds.addAll(GameData.siteKindNames);
      }
    }
    _selectedKind = kind ?? _kinds.keys.first;

    if (GameData.siteKindNames.containsKey(_selectedKind)) {
      assert(widget.atLocation != null);
      _idEditingController.text = '${widget.atLocation['id']}_$_selectedKind';
      _nameEditingController.text = engine.locale(_selectedKind);

      if (_selectedCategory == 'city') {
        _imageEditingController.text = '';
        _backgroundEditingController.text = 'city_plain_0_0.png';
      } else if (_selectedCategory == 'site') {
        _imageEditingController.text = 'location/card/$_selectedKind.png';
        _backgroundEditingController.text = 'location/site/$_selectedKind.png';
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      width: 600.0,
      height: 500.0,
      backgroundColor: GameUI.backgroundColor2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('editSite')),
          actions: const [CloseButton2()],
        ),
        body: Container(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(
                    width: 100.0,
                    child: Text('ID:'),
                  ),
                  SizedBox(
                    width: 450.0,
                    height: 40.0,
                    child: TextField(
                      controller: _idEditingController,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100.0,
                      child: Text('${engine.locale('category')}:'),
                    ),
                    fluent.DropDownButton(
                      disabled: !widget.allowEditCategory,
                      title: Text(engine.locale(_selectedCategory)),
                      items: buildFluentMenuItems(
                        items: {
                          for (final key in _categories.keys)
                            engine.locale(key): key,
                        },
                        onSelectedItem: (String value) {
                          setCategoryKind(category: value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100.0,
                      child: Text('${engine.locale('kind')}:'),
                    ),
                    fluent.DropDownButton(
                      disabled: !widget.allowEditKind,
                      title: Text(engine.locale(_selectedKind)),
                      items: buildFluentMenuItems(
                        items: {
                          for (final key in _kinds.keys)
                            engine.locale(key): key,
                        },
                        onSelectedItem: (String value) {
                          setCategoryKind(kind: value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 100.0,
                    child: Text('${engine.locale('name')}:'),
                  ),
                  SizedBox(
                    width: 200.0,
                    height: 40.0,
                    child: TextField(
                      controller: _nameEditingController,
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 100.0,
                    child: Text('${engine.locale('image')}:'),
                  ),
                  SizedBox(
                    width: 450.0,
                    height: 40.0,
                    child: TextField(
                      controller: _imageEditingController,
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 100.0,
                    child: Text('${engine.locale('background')}:'),
                  ),
                  SizedBox(
                    width: 450.0,
                    height: 40.0,
                    child: TextField(
                      controller: _backgroundEditingController,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 100.0,
                      child: Text('${engine.locale('createNpc')}:'),
                    ),
                    fluent.Checkbox(
                      checked: _createNpc,
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            _createNpc = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: fluent.FilledButton(
                  onPressed: () {
                    String? id = _idEditingController.text.nonEmptyValue;
                    String? name = _nameEditingController.text.nonEmptyValue;
                    String? category = _selectedCategory?.nonEmptyValue;
                    String? kind = _selectedKind?.nonEmptyValue;
                    String? image = _imageEditingController.text.nonEmptyValue;
                    String? background =
                        _backgroundEditingController.text.nonEmptyValue;

                    Navigator.of(context).pop((
                      id,
                      category,
                      kind,
                      name,
                      image,
                      background,
                      _createNpc,
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
