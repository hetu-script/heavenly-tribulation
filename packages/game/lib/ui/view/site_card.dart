import 'package:flutter/material.dart';

import '../../engine/engine.dart';

class SiteCard extends StatelessWidget {
  const SiteCard({
    Key? key,
    required this.locationId,
    required this.siteId,
    required this.title,
    this.imagePath,
  }) : super(key: key);

  final String locationId, siteId;
  final String title;

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      height: 150,
      child: Card(
        elevation: 8.0,
        shadowColor: Colors.black26,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            image: imagePath != null
                ? DecorationImage(
                    image: AssetImage('assets/images/$imagePath'),
                    fit: BoxFit.fill,
                  )
                : null,
          ),
          child: InkWell(
            splashColor: Colors.blue.withAlpha(30),
            onTap: () {
              engine.hetu.invoke('handleSiteInteraction',
                  positionalArgs: [siteId, locationId]);
            },
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(2),
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                    child: Text(
                      title,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
