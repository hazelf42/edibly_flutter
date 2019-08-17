import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/material.dart';

import 'package:edibly/screens/restaurant/photos/restaurant_photos_bloc.dart';
import 'package:edibly/screens/restaurant/restaurant_screen.dart';
import 'package:edibly/screens/restaurant/restaurant_bloc.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/models/data.dart';

class RestaurantPhotosScreen extends StatelessWidget {
  final String firebaseUserId;
  final String restaurantName;
  final String restaurantKey;

  RestaurantPhotosScreen({
    @required this.firebaseUserId,
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
      body: MultiProvider(
        providers: [
          DisposableProvider<RestaurantBloc>(
              packageBuilder: (context) => RestaurantBloc(firebaseUserId: firebaseUserId, restaurantKey: restaurantKey)),
          DisposableProvider<RestaurantPhotosBloc>(packageBuilder: (context) => RestaurantPhotosBloc(restaurantKey: restaurantKey)),
        ],
        child: Builder(
          builder: (context) {
            final RestaurantBloc restaurantBloc = Provider.of<RestaurantBloc>(context);
            final RestaurantPhotosBloc restaurantPhotosBloc = Provider.of<RestaurantPhotosBloc>(context);
            return Container(
              alignment: Alignment.center,
              child: StreamBuilder<List<Data>>(
                stream: restaurantPhotosBloc.restaurantPhotos,
                builder: (context, restaurantSnapshot) {
                  if (restaurantSnapshot?.data == null) {
                    if (restaurantSnapshot.connectionState == ConnectionState.waiting) {
                      restaurantPhotosBloc.getRestaurantPhotos();
                    }
                    return CircularProgressIndicator();
                  } else if (restaurantSnapshot?.data == null) {
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
                          Container(
                            height: 12.0,
                          ),
                          RaisedButton(
                            onPressed: () {
                              RestaurantScreen.showAddImageDialog(
                                context: context,
                                restaurantBloc: restaurantBloc,
                                localizations: localizations,
                                restaurantName: restaurantName,
                              );
                            },
                            child: SingleLineText(localizations.addPhoto.toUpperCase()),
                          ),
                        ],
                      ),
                    );
                  } else {
                    List<Data> restaurantPhotosMap = restaurantSnapshot.data;
                    return GridView.builder(
                      itemCount: restaurantPhotosMap.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                      itemBuilder: (context, position) {
                        return GestureDetector(
                          key: Key((restaurantPhotosMap.elementAt(position).key).toString()),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => RestaurantPhotoScreen(
                                    restaurantName: restaurantName,
                                    photoUrl: restaurantPhotosMap[position].value['photo'],
                                  ),
                            ));
                          },
                          child: CachedNetworkImage(
                            imageUrl: restaurantPhotosMap[position].value['photo'],
                            fit: BoxFit.cover,
                            placeholder: (context, imageUrl) {
                              return Container(
                                height: 120.0,
                                alignment: Alignment.center,
                                child: CircularProgressIndicator(),
                              );
                            },
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
