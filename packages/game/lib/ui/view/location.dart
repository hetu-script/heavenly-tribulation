import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/event/events.dart';

import '../shared/empty_placeholder.dart';
import '../../../engine/engine.dart';
// import '../colored_widget.dart';

class LocationRoute extends StatelessWidget {
  const LocationRoute({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locationId = ModalRoute.of(context)!.settings.arguments as String;

    return LocationView(
      locationId: locationId,
    );
  }
}

class LocationView extends StatefulWidget {
  final String locationId;

  const LocationView({
    Key? key,
    required this.locationId,
  }) : super(key: key);

  @override
  _LocationViewState createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView>
    with AutomaticKeepAliveClientMixin
//, SingleTickerProviderStateMixin
{
  @override
  bool get wantKeepAlive => true;

  // final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  List<Widget>? _siteCards;

  // static const _tabs = <Tab>[
  //   Tab(text: '动态'),
  //   Tab(text: '场景'),
  // ];

  // late TabController _tabController;
  late String _locationName;
  // _leadershipName,
  // _organization,
  // _organizationName,
  String? _locationImagePath;

  Future<void> _updateData() async {
    engine.hetu.invoke('nextTick');

    final data = engine.hetu
        .invoke('getLocationById', positionalArgs: [widget.locationId]);

    setState(() {
      final String? name = data['name'];
      if (name != null) {
        _locationName = name;
      } else {
        final String nameId = data['nameId'];
        _locationName = engine.locale[nameId];
      }
      _locationImagePath = data['image'];
      // _leadershipName = widget.locationData['leadershipName'];

      final sitesData = data['sites'];

      _siteCards = List.castFrom(sitesData?.values.map((siteData) {
        final String id = siteData['id'];
        final String type = siteData['type'];
        final titleId = siteData['nameId'];
        String title;
        if (titleId == null) {
          title = engine.locale[type];
        } else {
          title = engine.locale[titleId];
        }
        String? image = siteData['image'];
        image ??= _getDefaultImagePath(type);

        return SizedBox(
          width: 210,
          height: 150,
          child: Card(
            elevation: 8.0,
            shadowColor: Colors.black26,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                image: image != null
                    ? DecorationImage(
                        image: AssetImage('assets/images/$image'),
                        fit: BoxFit.fill,
                      )
                    : null,
              ),
              child: InkWell(
                splashColor: Colors.blue.withAlpha(30),
                onTap: () {
                  engine.hetu
                      .invoke('handleSceneInteraction', positionalArgs: [id]);
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false));
    });
  }

  @override
  void initState() {
    super.initState();
    _updateData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200.0),
        child: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              engine
                  .broadcast(LocationEvent.left(locationId: widget.locationId));
              Navigator.of(context).pop();
            },
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              image: _locationImagePath != null
                  ? DecorationImage(
                      image: AssetImage('assets/images/$_locationImagePath'),
                      fit: BoxFit.fill,
                    )
                  : null,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 180.0,
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _locationName,
                          style: const TextStyle(
                            fontSize: 24.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // bottom: ColoredPreferredSizeWidget(
          //   backgroundColor: Colors.transparent.withOpacity(0.5),
          //   child: TabBar(
          //     controller: _tabController,
          //     tabs: _tabs,
          //     unselectedLabelStyle: const TextStyle(fontSize: 16.0),
          //     labelStyle: const TextStyle(fontSize: 20.0),
          //   ),
          // ),
        ),
      ),
      body: RefreshIndicator(
        // key: _refreshIndicatorKey,
        onRefresh: _updateData,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            },
          ),
          child: Scrollbar(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              shrinkWrap: true,
              children: <Widget>[
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: (_siteCards != null && _siteCards!.isNotEmpty)
                        ? Wrap(
                            spacing: 8.0, // gap between adjacent chips
                            runSpacing: 4.0, // gap between lines
                            children: _siteCards!)
                        : EmptyPlaceholder(text: engine.locale['empty']),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _getDefaultImagePath(String type) {
    String? imagePath;
    switch (type) {
      case 'headquarters':
        imagePath = 'location/site/headquarters.png';
        break;
      case 'residence':
        imagePath = 'location/site/residence.png';
        break;
      case 'library':
        imagePath = 'location/site/library.png';
        break;
      case 'farmland':
        imagePath = 'location/site/farmland.png';
        break;
      case 'mine':
        imagePath = 'location/site/mine.png';
        break;
      case 'timberland':
        imagePath = 'location/site/timberland.png';
        break;
      case 'market':
        imagePath = 'location/site/market.png';
        break;
      case 'shop':
        imagePath = 'location/site/shop.png';
        break;
      case 'restaurant':
        imagePath = 'location/site/restaurant.png';
        break;
      case 'arena':
        imagePath = 'location/site/arena.png';
        break;
      case 'nursery':
        imagePath = 'location/site/nursery.png';
        break;
      case 'workshop':
        imagePath = 'location/site/workshop.png';
        break;
      case 'alchemylab':
        imagePath = 'location/site/alchemylab.png';
        break;
      case 'smithshop':
        imagePath = 'location/site/smithshop.png';
        break;
      case 'zenyard':
        imagePath = 'location/site/zenyard.png';
        break;
      case 'zoo':
        imagePath = 'location/site/zoo.png';
        break;
      case 'maze':
        imagePath = 'location/site/maze.png';
        break;
    }
    return imagePath;
  }
}
