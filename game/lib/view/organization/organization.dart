import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';
// import 'package:quiver/pattern.dart';
// import 'package:samsara/event.dart';

import '../../config.dart';
import 'package:samsara/ui/close_button.dart';
import 'package:samsara/ui/responsive_window.dart';
// import '../../game_entity_listview.dart';
import '../../util.dart';
import '../common.dart';

const kOrganizationCategoryCultivation = 'cultivation';
const kOrganizationCategoryReligion = 'religion';
const kOrganizationCategoryGang = 'gang';
const kOrganizationCategoryBusiness = 'business';
const kOrganizationCategoryNation = 'nation';

class OrganizationView extends StatefulWidget {
  final String? organizationId;
  final HTStruct? organizationData;
  final ViewPanelMode mode;

  const OrganizationView({
    super.key,
    this.organizationId,
    this.organizationData,
    this.mode = ViewPanelMode.view,
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
            Text(engine.locale('history')),
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

    return ResponsiveWindow(
      alignment: AlignmentDirectional.center,
      size: const Size(400.0, 400.0),
      child: DefaultTabController(
        length: _tabs.length,
        child: Scaffold(
          backgroundColor: kBackgroundColor,
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
                        '${engine.locale('head')}: ${getNameFromId(_organizationData['headId'])}'),
                    // if (category != kOrganizationCategoryNation) ...[
                    Text(
                        '${engine.locale('development')}: ${_organizationData['development']}'),
                    Text(
                        '${engine.locale('recruitMonth')}: ${_organizationData['yearlyRecruitMonth']}'),
                    // ],
                    // if (category == kOrganizationCategoryCultivation) ...[
                    // Text(
                    //     '${engine.locale('fightSkillGenre']}: ${engine.locale(_organizationData['fightSkillGenre'])}'),
                    // Text(
                    //     '${engine.locale('supportSkillGenre']}: ${engine.locale(_organizationData['supportSkillGenre'])}'),
                    // ],
                  ],
                ),
              ),
              Container(),
              Container(),
            ],
          ),
        ),
      ),
    );
  }
}
