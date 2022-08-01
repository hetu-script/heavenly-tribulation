import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';
// import 'package:quiver/pattern.dart';
// import 'package:samsara/event.dart';

import '../../../global.dart';
import '../../shared/close_button.dart';
import '../../shared/responsive_window.dart';
import '../../game_entity_listview.dart';
import '../../util.dart';

const kOrganizationCategoryCultivation = 'cultivation';
const kOrganizationCategoryGang = 'gang';
const kOrganizationCategoryReligion = 'religion';
const kOrganizationCategoryNation = 'nation';
const kOrganizationCategoryBusiness = 'business';

class LocationView extends StatefulWidget {
  final String? organizationId;
  final HTStruct? organizationData;

  const LocationView({
    super.key,
    this.organizationId,
    this.organizationData,
  });

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView> {
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
            Text(engine.locale['information']),
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
            Text(engine.locale['character']),
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
            Text(engine.locale['history']),
          ],
        ),
      ),
    ];

    if (widget.organizationData != null) {
      _organizationData = widget.organizationData!;
    } else {
      final organizationId = widget.organizationId ??
          ModalRoute.of(context)!.settings.arguments as String;
      _organizationData = engine
          .invoke('getOrganizationById', positionalArgs: [organizationId]);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String? leaderTitle;
    switch (_organizationData['category']) {
      case kOrganizationCategoryCultivation:
        leaderTitle = engine.locale['cultivation.titleRank0'];
        break;
      case kOrganizationCategoryGang:
        leaderTitle = engine.locale['gang.titleRank0'];
        break;
      case kOrganizationCategoryReligion:
        leaderTitle = engine.locale['religion.titleRank0'];
        break;
      case kOrganizationCategoryNation:
        leaderTitle = engine.locale['nation.titleRank0'];
        break;
      case kOrganizationCategoryBusiness:
        leaderTitle = engine.locale['business.titleRank0'];
        break;
    }

    assert(leaderTitle != null);

    final layout = DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(_organizationData['name']),
          actions: const [ButtonClose()],
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
                      '${engine.locale['headquarters']}: ${getNameFromId(_organizationData['headquartersId'])}'),
                  Text(
                      '$leaderTitle:  ${getNameFromId(_organizationData['leaderId'])}'),
                  Text(
                      '${engine.locale['development']}: ${_organizationData['development']}'),
                ],
              ),
            ),
            Container(),
            Container(),
          ],
        ),
      ),
    );

    return ResponsiveWindow(
      alignment: AlignmentDirectional.topStart,
      size: const Size(400.0, 400.0),
      child: layout,
    );
  }
}
