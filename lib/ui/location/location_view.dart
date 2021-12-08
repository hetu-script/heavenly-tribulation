import 'package:flutter/material.dart';
import '../../engine/game.dart';
// import '../colored_widget.dart';

class LocationView extends StatefulWidget {
  final SamsaraGame game;

  final Map<String, dynamic> data;

  const LocationView({
    required this.game,
    required this.data,
    Key? key,
  }) : super(key: key);

  @override
  _LocationViewState createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  SamsaraGame get game => widget.game;
  Map<String, dynamic> get data => widget.data;

  // late final List<Widget> _pages;

  // static const _tabs = <Tab>[
  //   Tab(text: '动态'),
  //   Tab(text: '场景'),
  // ];

  // late TabController _tabController;
  late String _title,
      // _leadershipName,
      // _organization,
      // _organizationName,
      _image;

  @override
  void initState() {
    super.initState();
    // _tabController = TabController(vsync: this, length: _tabs.length);

    final String titleId = data['name'];
    _title = game.texts[titleId];
    // _leadershipName = widget.locationData['leadershipName'];
    _image = data['image'];

    // _pages = <Widget>[
    //   Center(
    //     child: Column(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: <Widget>[
    //         TextButton(
    //           style: TextButton.styleFrom(
    //             primary: Colors.white,
    //             backgroundColor: Colors.lightBlue,
    //             textStyle: const TextStyle(fontSize: 12),
    //           ),
    //           child: const Text(
    //             'Roguelike Game Test',
    //           ),
    //           onPressed: () {
    //             widget.game.createScene('RogueGame');
    //             // GameDialog.show(context, [
    //             //   const Saying('Hello, world!'),
    //             //   const Saying('Alef out...'),
    //             // ]);
    //           },
    //         ),
    //       ],
    //     ),
    //   ),
    //   const Align(
    //     alignment: Alignment.center,
    //     child: Text('场景'),
    //   ),
    //   const Align(
    //     alignment: Alignment.center,
    //     child: Text('人物'),
    //   ),
    // ];
  }

  @override
  void dispose() {
    // _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(180.0), // here the desired height
        child: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/$_image'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              children: <Widget>[
                Text(_title),
              ],
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
      body: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Wrap(
            spacing: 8.0, // gap between adjacent chips
            runSpacing: 4.0, // gap between lines
            children: <Widget>[
              SizedBox(
                width: 200,
                height: 180,
                child: Card(
                  shadowColor: Colors.black26,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(5.0),
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () {
                      print('Card tapped.');
                    },
                    child: const SizedBox(
                      width: 300,
                      height: 100,
                      child: Text('Card 0'),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                height: 180,
                child: Card(
                  shadowColor: Colors.black26,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(5.0),
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () {
                      print('Card 1 tapped.');
                    },
                    child: const SizedBox(
                      width: 300,
                      height: 100,
                      child: Text('Card 1'),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                height: 180,
                child: Card(
                  shadowColor: Colors.black26,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(5.0),
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () {
                      print('Card 2 tapped.');
                    },
                    child: const SizedBox(
                      width: 300,
                      height: 100,
                      child: Text('Card 2'),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                height: 180,
                child: Card(
                  shadowColor: Colors.black26,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(5.0),
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () {
                      print('Card 3 tapped.');
                    },
                    child: const SizedBox(
                      width: 300,
                      height: 100,
                      child: Text('Card 3'),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                height: 180,
                child: Card(
                  shadowColor: Colors.black26,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(5.0),
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () {
                      print('Card 4 tapped.');
                    },
                    child: const SizedBox(
                      width: 300,
                      height: 100,
                      child: Text('Card 4'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // TabBarView(
      //   controller: _tabController,
      //   children: _pages,
      // )
    );
  }
}
