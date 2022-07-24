import 'package:flutter/material.dart';

import '../../../global.dart';

class SiteCard extends StatelessWidget {
  const SiteCard({
    super.key,
    required this.locationId,
    required this.siteId,
    required this.title,
    this.imagePath,
  });

  final String locationId, siteId;
  final String title;

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 100,
      child: Card(
        elevation: 8.0,
        shadowColor: Colors.black26,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: kBorderRadius,
            image: imagePath != null
                ? DecorationImage(
                    image: AssetImage('assets/images/$imagePath'),
                    fit: BoxFit.fill,
                  )
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: kBorderRadius,
              onTap: () {
                engine.invoke('handleSiteInteraction',
                    positionalArgs: [locationId, siteId]);
              },
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
      ),
    );
  }
}
