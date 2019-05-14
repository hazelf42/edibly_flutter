import 'package:photo_view/photo_view.dart';
import 'package:flutter/material.dart';

import 'package:edibly/screens/restaurant/photos/restaurant_photos_bloc.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/models/data.dart';

class RestaurantPhotosScreen extends StatelessWidget {
  final String restaurantName;
  final String restaurantKey;

  RestaurantPhotosScreen({
    @required this.restaurantName,
    @required this.restaurantKey,
  });

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: SingleLineText(restaurantName),
      ),
      body: DisposableProvider<RestaurantPhotosBloc>(
        packageBuilder: (context) => RestaurantPhotosBloc(restaurantKey: restaurantKey),
        child: Builder(
          builder: (context) {
            final RestaurantPhotosBloc restaurantPhotosBloc = Provider.of<RestaurantPhotosBloc>(context);
            return Container(
              alignment: Alignment.center,
              child: StreamBuilder<Data>(
                stream: restaurantPhotosBloc.restaurantPhotos,
                builder: (context, restaurantSnapshot) {
                  if (restaurantSnapshot?.data == null) {
                    if (restaurantSnapshot.connectionState == ConnectionState.waiting) {
                      restaurantPhotosBloc.getRestaurantPhotos();
                    }
                    return CircularProgressIndicator();
                  } else if (restaurantSnapshot?.data != null && restaurantSnapshot.data.value == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.warning,
                            color: Theme.of(context).hintColor,
                            size: 48.0,
                          ),
                          Container(
                            height: 12.0,
                          ),
                          Text(
                            localizations.noPhotosText,
                            style: TextStyle(
                              fontSize: 18.0,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    Map<dynamic, dynamic> restaurantPhotosMap = restaurantSnapshot.data.value;
                    return GridView.builder(
                      itemCount: restaurantPhotosMap.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                      itemBuilder: (context, position) {
                        return GestureDetector(
                          key: Key(restaurantPhotosMap.entries.elementAt(position).key),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => RestaurantPhotoScreen(
                                    restaurantName: restaurantName,
                                    photoUrl: restaurantPhotosMap.entries.elementAt(position).value['imageUrl'],
                                  ),
                            ));
                          },
                          child: Image.network(
                            restaurantPhotosMap.entries.elementAt(position).value['imageUrl'],
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class RestaurantPhotoScreen extends StatelessWidget {
  final String restaurantName;
  final String photoUrl;

  RestaurantPhotoScreen({
    @required this.restaurantName,
    @required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SingleLineText(restaurantName),
      ),
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(photoUrl),
          loadingChild: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          ),
          backgroundDecoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
          minScale: PhotoViewComputedScale.contained * 1.0,
          maxScale: PhotoViewComputedScale.covered * 4.0,
        ),
      ),
    );
  }
}
