import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../../game/ui.dart';
import 'package:samsara/ui/close_button2.dart';
import 'package:samsara/ui/responsive_view.dart';
import '../../util.dart';
import '../common.dart';
import 'edit_organization_basic.dart';
import '../../game/data.dart';

const kOrganizationCategoryCultivation = 'cultivation';
const kOrganizationCategoryReligion = 'religion';
const kOrganizationCategoryBusiness = 'business';
// const kOrganizationCategoryGang = 'gang';
// const kOrganizationCategoryNation = 'nation';

class OrganizationView extends StatefulWidget {
  final String? organizationId;
  final HTStruct? organizationData;
  final InformationViewMode mode;

  const OrganizationView({
    super.key,
    this.organizationId,
    this.organizationData,
    this.mode = InformationViewMode.view,
  });

  @override
  State<OrganizationView> createState() => _OrganizationViewState();
}

class _OrganizationViewState extends State<OrganizationView> {
  late final List<Tab> _tabs;
  late final HTStruct _organizationData;

  @override
  void initState() {
    _tabs = [
      Tab(
        iconMargin: const EdgeInsets.all(5.0),
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(Icons.business),
            ),
            Text(engine.locale('information')),
          ],
        ),
      ),
      Tab(
        iconMargin: const EdgeInsets.all(5.0),
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(Icons.summarize),
            ),
            Text(engine.locale('character')),
          ],
        ),
      ),
      Tab(
        iconMargin: const EdgeInsets.all(5.0),
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(Icons.person),
            ),
            Text(engine.locale('territory')),
          ],
        ),
      ),
    ];

    if (widget.organizationData != null) {
      _organizationData = widget.organizationData!;
    } else {
      final organizationId = widget.organizationId ??
          ModalRoute.of(context)!.settings.arguments as String;
      _organizationData = engine.hetu
          .invoke('getOrganizationById', positionalArgs: [organizationId]);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // final headTitle = _organizationData['rankTitles'][6];

    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.center,
      width: 800.0,
      height: widget.mode != InformationViewMode.view ? 450.0 : 400.0,
      child: DefaultTabController(
        length: _tabs.length,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(_organizationData['name']),
            actions: const [CloseButton2()],
            bottom: TabBar(
              tabs: _tabs,
            ),
          ),
          body: TabBarView(
            children: [
              Container(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${engine.locale('genre')}: ${engine.locale(_organizationData['genre'])}'),
                    Text(
                        '${engine.locale('headquarters')}: ${getNameFromId(_organizationData['headquartersId'])}'),
                    Text(
                        '${engine.locale('organizationHead')}: ${getNameFromId(_organizationData['headId'])}'),
                    Text(
                        '${engine.locale('recruitMonth')}: ${_organizationData['yearlyRecruitMonth']}'),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Row(
                        children: [
                          fluent.FilledButton(
                            onPressed: () async {
                              final value = await showDialog(
                                context: context,
                                builder: (context) => EditOrganizationBasics(
                                  id: _organizationData['id'],
                                  name: _organizationData['name'],
                                  category: _organizationData['category'],
                                  genre: _organizationData['genre'],
                                  headId: _organizationData['headId'],
                                  headquartersData:
                                      GameData.gameData['locations']
                                          [_organizationData['headquartersId']],
                                ),
                              );
                              if (value == null) return;

                              final (id, name, category, genre, headId) = value;
                              _organizationData['name'] = name;
                              _organizationData['category'] = category;
                              _organizationData['genre'] = genre;

                              if (headId != null &&
                                  headId != _organizationData['headId']) {
                                _organizationData['headId'] = headId;
                              }

                              if (id != null && id != _organizationData['id']) {
                                GameData.gameData['organizations']
                                    .remove(_organizationData['id']);
                                _organizationData['id'] = id;
                                GameData.gameData['organizations'][id] =
                                    _organizationData;
                              }
                            },
                            child: Text(engine.locale('editIdAndImage')),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              SizedBox.shrink(),
              SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
