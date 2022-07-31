import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';
// import 'package:quiver/pattern.dart';
// import 'package:samsara/event.dart';

import '../../../global.dart';
import 'site_card.dart';
import '../../shared/close_button.dart';
import '../../shared/responsive_window.dart';
import '../../util.dart';

// const _kLocationTabNames = [
//   'site',
//   'information',
//   'character',
// ];

class LocationView extends StatefulWidget {
  final bool showSites;
  final String? locationId;
  final HTStruct? locationData;

  const LocationView({
    super.key,
    this.showSites = true,
    this.locationId,
    this.locationData,
  });

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView> {
  late final List<Tab> _tabs;
  late final HTStruct _locationData;

  @override
  void initState() {
    _tabs = [
      if (widget.showSites)
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
              Text(engine.locale['site']),
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
              child: Icon(Icons.person),
            ),
            Text(engine.locale['character']),
          ],
        ),
      ),
    ];

    if (widget.locationData != null) {
      _locationData = widget.locationData!;
    } else {
      final locationId = widget.locationId ??
          ModalRoute.of(context)!.settings.arguments as String;
      _locationData =
          engine.invoke('getLocationById', positionalArgs: [locationId]);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String? locationName = _locationData['name'];
    if (locationName == null) {
      final String nameId = _locationData['nameId'];
      locationName = engine.locale[nameId];
    }

    String? nationId = _locationData['nationId'];
    String nation = '';
    if (nationId != null) {
      nation = '${getNameFromId(nationId)} - ';
    }

    final HTStruct sitesData = _locationData['sites'];

    final List<Widget> siteCards = sitesData.values.map(
      (siteData) {
        String? imagePath = siteData['image'];
        return SiteCard(
          siteData: siteData,
          imagePath: imagePath,
        );
      },
    ).toList();

    // Scaffold(
    //   appBar:
    //  PreferredSize(
    //   preferredSize: const Size.fromHeight(200.0),
    //   child:
    //   AppBar(
    // leading: IconButton(
    //   icon: const Icon(Icons.arrow_back),
    //   onPressed: () {
    //     engine.broadcast(LocationEvent.left(locationId: locationId));
    //     Navigator.of(context).pop();
    //   },
    // ),
    // flexibleSpace: Container(
    //   decoration: BoxDecoration(
    //     image: locationImagePath != null
    //         ? DecorationImage(
    //             image: AssetImage('assets/images/$locationImagePath'),
    //             fit: BoxFit.fill,
    //           )
    //         : null,
    //   ),
    //   child: Container(
    //     alignment: Alignment.centerLeft,
    //     padding: const EdgeInsets.fromLTRB(70, 10, 10, 10),
    //     child: SizedBox(
    //       width: 180.0,
    //       child: Card(
    //         elevation: 5,
    //         shape: RoundedRectangleBorder(
    //             borderRadius: BorderRadius.circular(8.0)),
    //         child: Padding(
    //           padding: const EdgeInsets.all(8.0),
    //           child: Column(
    //             crossAxisAlignment: CrossAxisAlignment.start,
    //             children: [
    //               Text(
    //                 locationName,
    //                 style: const TextStyle(fontSize: 24.0),
    //               ),
    //             ],
    //           ),
    //         ),
    //       ),
    //     ),
    //   ),
    // ),
    // bottom: ColoredPreferredSizeWidget(
    //   backgroundColor: Colors.transparent.withOpacity(0.5),
    //   child: TabBar(
    //     controller: _tabController,
    //     tabs: _tabs,
    //     unselectedLabelStyle: const TextStyle(fontSize: 16.0),
    //     labelStyle: const TextStyle(fontSize: 20.0),
    //   ),
    // ),
    // ),
    // ),
    // body:

    final layout = DefaultTabController(
      length: _tabs.length, // 物品栏通过tabs过滤不同种类的物品
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('$nation$locationName'),
          actions: const [ButtonClose()],
          bottom: TabBar(
            tabs: _tabs,
          ),
        ),
        body: TabBarView(
          children: [
            if (widget.showSites)
              ListView(
                shrinkWrap: true,
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8.0, // gap between adjacent chips
                        runSpacing: 4.0, // gap between lines
                        children: siteCards,
                      ),
                    ),
                  ),
                ],
              ),
            Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${engine.locale['worldPosition']}: ${_locationData['tilePosition']['left']}, ${_locationData['tilePosition']['top']}'),
                  Text('${engine.locale['money']}: ${_locationData['money']}'),
                  Text(
                      '${engine.locale['development']}: ${_locationData['development']}'),
                  Text(
                      '${engine.locale['stability']}: ${_locationData['stability']}'),
                ],
              ),
            ),
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
