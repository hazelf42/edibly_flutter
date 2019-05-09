import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:edibly/screens/search/search_bloc.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/values/app_colors.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/models/data.dart';

class SearchScreen extends StatelessWidget {
  final FirebaseUser firebaseUser;

  SearchScreen({@required this.firebaseUser});

  Widget _map({
    @required AsyncSnapshot<LatLng> currentLocationSnapshot,
    @required AsyncSnapshot<List<Data>> allRestaurantsSnapshot,
  }) {
    Set<Marker> markers = {};
    if (allRestaurantsSnapshot?.data != null) {
      allRestaurantsSnapshot.data.forEach((data) {
        markers.add(Marker(
          markerId: MarkerId(data.key),
          position: LatLng(
            double.parse(data.value['lat'].toString()),
            double.parse(data.value['lng'].toString()),
          ),
          infoWindow: InfoWindow(
            title: data.value['name'],
            snippet: data.value['address'],
          ),
        ));
      });
    }
    return Container(
      height: 200.0,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: currentLocationSnapshot.data,
          zoom: 12.0,
        ),
        myLocationButtonEnabled: true,
        myLocationEnabled: true,
        gestureRecognizers: Set()
          ..add(Factory<PanGestureRecognizer>(() => PanGestureRecognizer()))
          ..add(Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer())),
        markers: markers,
      ),
    );
  }

  void _openFilters({
    @required BuildContext context,
    @required SearchBloc searchBloc,
    @required AppLocalizations localizations,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: Text(localizations.filters),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              StreamBuilder<double>(
                initialData: 0,
                stream: searchBloc.ratingSlider,
                builder: (context, snapshot) {
                  return Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          SingleLineText(
                            localizations.rating,
                            style: TextStyle(
                              fontSize: 13.0,
                            ),
                          ),
                          Expanded(
                            child: SingleLineText(
                              localizations.ratingText(snapshot.data.toInt()),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 13.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: snapshot.data,
                        min: 0.0,
                        max: 10.0,
                        divisions: 10,
                        onChanged: (value) {
                          searchBloc.setRatingSliderValue(value);
                        },
                        activeColor: Theme.of(context).toggleableActiveColor,
                        inactiveColor: Theme.of(context).toggleableActiveColor.withOpacity(0.25),
                      ),
                    ],
                  );
                },
              ),
              Container(height: 12.0),
              StreamBuilder<double>(
                initialData: 30,
                stream: searchBloc.distanceSlider,
                builder: (context, snapshot) {
                  return Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          SingleLineText(
                            localizations.distance,
                            style: TextStyle(
                              fontSize: 13.0,
                            ),
                          ),
                          Expanded(
                            child: SingleLineText(
                              localizations.distanceText(snapshot.data.toInt()),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 13.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: snapshot.data,
                        min: 0.0,
                        max: 30.0,
                        divisions: 30,
                        onChanged: (value) {
                          searchBloc.setDistanceSliderValue(value);
                        },
                        activeColor: Theme.of(context).toggleableActiveColor,
                        inactiveColor: Theme.of(context).toggleableActiveColor.withOpacity(0.25),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
          actions: <Widget>[
            FlatButton(
              child: Text(localizations.cancel.toUpperCase()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text(localizations.reset.toUpperCase()),
              onPressed: () {
                searchBloc.setDistanceSliderValue(30);
                searchBloc.setRatingSliderValue(0);
                searchBloc.setDistanceFilterValue();
                searchBloc.setRatingFilterValue();
                searchBloc.filterRestaurants(null);
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text(localizations.search.toUpperCase()),
              onPressed: () {
                searchBloc.setDistanceFilterValue();
                searchBloc.setRatingFilterValue();
                searchBloc.filterRestaurants(null);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _footer({
    @required BuildContext context,
    @required AppLocalizations localizations,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
      child: Column(
        children: <Widget>[
          Text(
            localizations.searchScreenFooterTitleText,
            style: Theme.of(context).textTheme.headline,
            textAlign: TextAlign.center,
          ),
          Container(height: 12.0),
          Text(
            localizations.searchScreenFooterDescriptionText,
            textAlign: TextAlign.center,
          ),
          Container(height: 12.0),
          RaisedButton(
            onPressed: () {},
            child: Text(localizations.addReview),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    return DisposableProvider<SearchBloc>(
      packageBuilder: (context) => SearchBloc(),
      child: Builder(
        builder: (context) {
          final SearchBloc searchBloc = Provider.of<SearchBloc>(context);
          return Container(
            color: Theme.of(context).brightness == Brightness.dark ? null : Colors.grey.shade300,
            alignment: Alignment.center,
            child: FutureBuilder(
                future: searchBloc.getCurrentLocation(),
                builder: (context, currentLocationSnapshot) {
                  if (currentLocationSnapshot?.data == null) {
                    return CircularProgressIndicator();
                  }
                  return StreamBuilder<List<Data>>(
                    stream: searchBloc.allRestaurants,
                    builder: (context, allRestaurantsSnapshot) {
                      if (allRestaurantsSnapshot?.data == null) {
                        if (allRestaurantsSnapshot.connectionState == ConnectionState.waiting) {
                          searchBloc.getAllRestaurants();
                        }
                        return CircularProgressIndicator();
                      }
                      return RefreshIndicator(
                        child: StreamBuilder<List<Data>>(
                          stream: searchBloc.filteredRestaurants,
                          initialData: allRestaurantsSnapshot?.data,
                          builder: (context, filteredRestaurantsSnapshot) {
                            bool filteredRestaurantsValueIsNull = filteredRestaurantsSnapshot?.data == null;
                            int listViewItemCount = (filteredRestaurantsValueIsNull ? 0 : filteredRestaurantsSnapshot.data.length) + 2;
                            return ListView.separated(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              separatorBuilder: (context, position) {
                                return Container(height: 10.0);
                              },
                              itemCount: listViewItemCount + 1,
                              itemBuilder: (context, position) {
                                if (position == listViewItemCount) {
                                  return _footer(
                                    context: context,
                                    localizations: localizations,
                                  );
                                } else if (position == 0) {
                                  return _map(
                                    currentLocationSnapshot: currentLocationSnapshot,
                                    allRestaurantsSnapshot: allRestaurantsSnapshot,
                                  );
                                } else if (position == 1) {
                                  return Column(
                                    children: <Widget>[
                                      Card(
                                        margin: const EdgeInsets.symmetric(horizontal: 10.0),
                                        child: Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: TextField(
                                                onChanged: (keyword) {
                                                  searchBloc.filterRestaurants(keyword);
                                                },
                                                decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  isDense: true,
                                                  hintText: localizations.searchExampleText,
                                                  labelText: localizations.search,
                                                  prefixIcon: Icon(Icons.search),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.tune,
                                                color: Theme.of(context).brightness == Brightness.dark ? null : Colors.grey,
                                              ),
                                              onPressed: () {
                                                _openFilters(
                                                  context: context,
                                                  searchBloc: searchBloc,
                                                  localizations: localizations,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      Builder(builder: (context) {
                                        if (listViewItemCount == 2 && filteredRestaurantsValueIsNull) {
                                          return Container(
                                            margin: const EdgeInsets.all(24.0),
                                            child: CircularProgressIndicator(),
                                          );
                                        } else if (listViewItemCount == 2) {
                                          return Container(
                                            margin: const EdgeInsets.all(24.0),
                                            child: Column(
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
                                                  localizations.noRestaurantsFound,
                                                  style: TextStyle(
                                                    fontSize: 18.0,
                                                    color: Theme.of(context).hintColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        return Container();
                                      }),
                                    ],
                                  );
                                }
                                return Container(
                                  margin: EdgeInsets.symmetric(horizontal: 10.0),
                                  child: RestaurantWidget(
                                    firebaseUser: firebaseUser,
                                    restaurant: filteredRestaurantsSnapshot.data.elementAt(position - 2),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        onRefresh: () {
                          searchBloc.getAllRestaurants();
                          return Future.delayed(Duration(seconds: 1));
                        },
                      );
                    },
                  );
                }),
          );
        },
      ),
    );
  }
}

class RestaurantWidget extends StatelessWidget {
  final FirebaseUser firebaseUser;
  final Data restaurant;

  RestaurantWidget({
    @required this.firebaseUser,
    @required this.restaurant,
  }) : super(key: Key(restaurant.key));

  List<Data> dynamicTagArrayToTagList(dynamic dynamicTagArray) {
    List<Data> tagList = [];
    if (dynamicTagArray != null) {
      Map<dynamic, dynamic> map = dynamicTagArray;
      map.forEach((key, value) {
        tagList.add(Data(key, value));
      });
    }
    return tagList;
  }

  Widget _rating({@required BuildContext context, @required dynamic value}) {
    if (value == null || value['numRating'] == null) {
      return Container();
    }
    return Container(
      margin: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: <Widget>[
          SmoothStarRating(
            allowHalfRating: true,
            starCount: 10,
            rating: value['numRating'] / 1.0,
            size: 16.0,
            color: AppColors.primarySwatch.shade900,
            borderColor: AppColors.primarySwatch.shade900,
          ),
          Container(
            width: 8.0,
          ),
          SingleLineText(
            value['numRating'].toString(),
            style: TextStyle(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _address() {
    if (restaurant?.value == null || restaurant.value['address'] == null) {
      return Container();
    }
    return Container(
      margin: const EdgeInsets.only(top: 4.0),
      child: Text(
        restaurant.value['address'].toString().trim() ?? '',
      ),
    );
  }

  Widget _tags({@required BuildContext context, @required dynamic value}) {
    if (value == null || value['tagDict'] == null || value['tagDict'].toString().isEmpty) {
      return Container();
    }
    return Container(
      margin: const EdgeInsets.only(top: 6.0),
      child: Wrap(
        spacing: 6.0,
        runSpacing: 6.0,
        children: dynamicTagArrayToTagList(value['tagDict']).map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(
              vertical: 4.0,
              horizontal: 8.0,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).chipTheme.backgroundColor,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: SingleLineText(
              '${tag.key} (${tag.value})',
              style: TextStyle(
                fontSize: 12.0,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SearchBloc searchBloc = Provider.of<SearchBloc>(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4.0),
              bottomLeft: Radius.circular(4.0),
            ),
            child: Container(
              width: 70.0,
              height: 70.0,
              color: Colors.white,
              child: FadeInImage(
                image: restaurant.value['photoUrl'] != null
                    ? (NetworkImage(restaurant.value['photoUrl'] ?? ''))
                    : AssetImage('assets/drawables/ic_launcher.png'),
                placeholder: AssetImage('assets/drawables/ic_launcher.png'),
                width: 70.0,
                height: 70.0,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12.0, 8.0, 0.0, 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    restaurant.value['name'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.0,
                    ),
                  ),
                  _rating(
                    context: context,
                    value: restaurant.value['rating'],
                  ),
                  _address(),
                  _tags(
                    context: context,
                    value: restaurant.value['rating'],
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<Event>(
            stream: searchBloc.getRestaurantBookmarkValue(firebaseUser.uid, restaurant.key),
            builder: (context, bookmarkValueSnapshot) {
              bool bookmarked = bookmarkValueSnapshot?.data?.snapshot?.value == 1;
              return IconButton(
                icon: Icon(
                  bookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: bookmarked ? AppColors.primarySwatch.shade600 : Theme.of(context).disabledColor,
                ),
                onPressed: () {
                  searchBloc.setRestaurantBookmarkValue(firebaseUser.uid, restaurant.key, !bookmarked);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
