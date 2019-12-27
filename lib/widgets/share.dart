import 'package:flutter/material.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:share/share.dart';
import 'package:minsk8/import.dart';

Widget buildShare(TuChongItem item) {
  return Tooltip(
    message: 'Share',
    child: Material(
      child: InkWell(
        borderRadius: BorderRadius.all(kImageBorderRadius),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 16.3,
          ),
          child: Icon(
            Icons.share,
            color: Colors.black,
            size: 18.0,
          ),
        ),
        onTap: _onTap(item),
      ),
    ),
  );
}

Function _onTap(TuChongItem item) {
  // TODO: реализовать ожидание для buildShortLink()
  return () async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://minsk8.page.link',
      link: Uri.parse('https://minsk8.example.com/item?id=${item.postId}'),
      androidParameters: AndroidParameters(
        packageName: 'com.example.minsk8',
        minimumVersion: 1,
      ),
      dynamicLinkParametersOptions: DynamicLinkParametersOptions(
        shortDynamicLinkPathLength: ShortDynamicLinkPathLength.short,
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: 'Example of a Dynamic Link',
        description: 'This link works whether app is installed or not!',
        // TODO: The URL to an image related to this link. The image should be at least 300x200 px, and less than 300 KB.
        // imageUrl:
      ),
      navigationInfoParameters: NavigationInfoParameters(
        forcedRedirectEnabled: false,
      ),
    );
    final ShortDynamicLink shortLink = await parameters.buildShortLink();
    Uri url = shortLink.shortUrl;
    print('${item.postId} $url');
    Share.share(
      'check out my website $url',
      subject: 'Look what I made!',
    );
  };
}