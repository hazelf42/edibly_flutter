import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';

import 'package:edibly/screens/discover/restaurant_preview_widget.dart';
import 'package:edibly/screens/discover/event_preview_widget.dart';
import 'package:edibly/screens/restaurant/restaurant_screen.dart';
import 'package:edibly/screens/discover/discover_bloc.dart';
import 'package:edibly/screens/search/search_screen.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/values/app_colors.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/models/data.dart';

class DiscoverScreen extends StatelessWidget {
  final FirebaseUser firebaseUser;

  DiscoverScreen({@required this.firebaseUser});

  Widget _header(String header) {
    return Card(
      shape: RoundedRectangleBorder(),
      margin: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
        child: SingleLineText(
          header,
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _error({@required String error}) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      alignment: Alignment.center,
      child: Text(
        error,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _loader({double height = 200.0}) {
    return Container(
      alignment: Alignment.center,
      height: height,
      child: CircularProgressIndicator(),
    );
  }

  Widget _map({@required DiscoverBloc discoverBloc}) {
    return StreamBuilder<LatLng>(
      stream: discoverBloc.location,
      builder: (context, locationSnapshot) {
        return StreamBuilder<List<Data>>(
          stream: discoverBloc.restaurants,
          builder: (context, restaurantsSnapshot) {
            if (!locationSnapshot.hasData || (!restaurantsSnapshot.hasData && !restaurantsSnapshot.hasError)) {
              return _loader(height: 200);
            }
            // ignore: sdk_version_set_literal
            Set<Marker> markers = {};
            if (restaurantsSnapshot.hasData) {
              restaurantsSnapshot.data.forEach((data) {
                markers.add(Marker(
                  markerId: MarkerId(data.key),
                  position: LatLng(
                    double.parse(data.value['lat'].toString()),
                    double.parse(data.value['lng'].toString()),
                  ),
                  infoWindow: InfoWindow(
                    title: data.value['name'],
                    snippet: data.value['address'] ?? data.value['address1'] ?? data.value['address2'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RestaurantScreen(
                                firebaseUserId: firebaseUser.uid,
                                restaurantKey: data.key,
                              ),
                        ),
                      );
                    },
                  ),
                ));
              });
            }
            return Container(
              height: 200.0,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: locationSnapshot.data,
                  zoom: 12.0,
                ),
                myLocationButtonEnabled: true,
                myLocationEnabled: true,
                onTap: (_) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchScreen(firebaseUser: firebaseUser),
                    ),
                  );
                },
                gestureRecognizers: Set()
                  ..add(Factory<PanGestureRecognizer>(() => PanGestureRecognizer()))
                  ..add(Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer())),
                markers: markers,
              ),
            );
          },
        );
      },
    );
  }

  Widget _restaurants({@required Stream<List<Data>> stream}) {
    return StreamBuilder<List<Data>>(
      stream: stream,
      builder: (context, restaurantsSnapshot) {
        if (restaurantsSnapshot.hasError) {
          return _error(error: restaurantsSnapshot.error);
        } else if (!restaurantsSnapshot.hasData) {
          return _loader(height: 200);
        } else {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            height: 200.0,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 2.0, horizontal: 6.0),
                  child: RestaurantPreviewWidget(
                    firebaseUser: firebaseUser,
                    restaurant: restaurantsSnapshot.data.elementAt(index),
                  ),
                );
              },
              itemCount: restaurantsSnapshot.data.length,
            ),
          );
        }
      },
    );
  }

  Widget _events({@required Stream<List<Data>> stream}) {
    return StreamBuilder<List<Data>>(
      stream: stream,
      builder: (context, eventsSnapshot) {
        if (eventsSnapshot.hasError) {
          return _error(error: eventsSnapshot.error);
        } else if (!eventsSnapshot.hasData) {
          return _loader(height: 200);
        } else {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            height: 187.0,
            child: ListView.separated(
              separatorBuilder: (context, index) {
                if (index == 0 ||
                    DateFormat('ddMMyyyy').format(
                          DateTime.fromMillisecondsSinceEpoch(
                            eventsSnapshot.data.elementAt(index - 1).value['startTime'] * 1000,
                          ),
                        ) !=
                        DateFormat('ddMMyyyy').format(
                          DateTime.fromMillisecondsSinceEpoch(
                            eventsSnapshot.data.elementAt(index).value['startTime'] * 1000,
                          ),
                        )) {
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 2.0, horizontal: 6.0),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.today),
                            Container(height: 4.0),
                            SingleLineText(
                              DateFormat('MMM').format(
                                DateTime.fromMillisecondsSinceEpoch(
                                  eventsSnapshot.data.elementAt(index).value['startTime'] * 1000,
                                ),
                              ),
                            ),
                            Container(height: 2.0),
                            SingleLineText(
                              DateFormat('d').format(
                                DateTime.fromMillisecondsSinceEpoch(
                                  eventsSnapshot.data.elementAt(index).value['startTime'] * 1000,
                                ),
                              ),
                              style: TextStyle(
                                color: AppColors.primarySwatch.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SingleLineText(
                              DateFormat('EEEE').format(
                                DateTime.fromMillisecondsSinceEpoch(
                                  eventsSnapshot.data.elementAt(index).value['startTime'] * 1000,
                                ),
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  return Container();
                }
              },
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                if (index == 0) return Container();
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 2.0, horizontal: 6.0),
                  child: EventPreviewWidget(
                    firebaseUser: firebaseUser,
                    event: eventsSnapshot.data.elementAt(index - 1),
                  ),
                );
              },
              itemCount: eventsSnapshot.data.length + 1,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    return DisposableProvider<DiscoverBloc>(
      packageBuilder: (context) => DiscoverBloc(
            firebaseUser: firebaseUser,
            localizations: localizations,
          ),
      child: Builder(
        builder: (context) {
          final DiscoverBloc discoverBloc = Provider.of<DiscoverBloc>(context);
          return Container(
            color: Theme.of(context).brightness == Brightness.dark ? null : Colors.grey.shade300,
            alignment: Alignment.center,
            child: RefreshIndicator(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 10.0),
                children: <Widget>[
                  _header(localizations.featured),
                  Container(height: 12.0),
                  _restaurants(stream: discoverBloc.featuredRestaurants),
                  Container(height: 12.0),
                  _header(localizations.events),
                  Container(height: 12.0),
                  _events(stream: discoverBloc.events),
                  Container(height: 12.0),
                  _header(localizations.nearby),
                  Container(height: 12.0),
                  _map(discoverBloc: discoverBloc),
                  Container(height: 10.0),
                  _restaurants(stream: discoverBloc.nearbyRestaurants),
                ],
              ),
              onRefresh: () {
                discoverBloc.fetchData();
                return Future.delayed(Duration(seconds: 1));
              },
            ),
          );
        },
      ),
    );
  }
}
