import 'package:photo_view/photo_view.dart';
import 'package:flutter/material.dart';

import 'package:edibly/values/app_localizations.dart';

class FullScreenImageScreen extends StatelessWidget {
  final String _url;

  FullScreenImageScreen(this._url);

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.photo),
      ),
      body: PhotoView(
        imageProvider: NetworkImage(_url ?? ''),
        loadingChild: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: CircularProgressIndicator(),
          ),
        ),
        backgroundDecoration: BoxDecoration(color: Colors.black),
        minScale: PhotoViewComputedScale.contained * 1.0,
        maxScale: PhotoViewComputedScale.covered * 4.0,
      ),
    );
  }
}
