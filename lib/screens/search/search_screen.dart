import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:edibly/screens/search/restaurant_preview_widget.dart';
import 'package:edibly/screens/search/search_bloc.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/bloc_helper/provider.dart';
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
      packageBuilder: (context) => SearchBloc(firebaseUser: firebaseUser),
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
                                  child: RestaurantPreviewWidget(
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
