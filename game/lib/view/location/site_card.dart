import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../config.dart';

class SiteCard extends StatelessWidget {
  const SiteCard({
    super.key,
    required this.siteData,
    this.imagePath,
  });

  final HTStruct siteData;

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
              onTap: () async {
                // await engine.hetu
                //     .invoke('onAfterHeroEnterSite', positionalArgs: [siteData]);
                // engine.hetu.invoke('onAfterHeroEnterSite', positionalArgs: [
                //   siteData['locationId'],
                //   siteData['id'],
                // ]);
              },
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      color: Theme.of(context).primaryColor.withAlpha(128),
                      child: Text(
                        siteData['name'],
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
