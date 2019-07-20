import 'dart:math';
import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:location/location.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;

import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/models/data.dart';

class DiscoverBloc {
  final AppLocalizations localizations;
  final FirebaseUser firebaseUser;

  DiscoverBloc({@required this.firebaseUser, @required this.localizations}) {
    _firebaseDatabase.setPersistenceEnabled(true);
    _firebaseDatabase.setPersistenceCacheSizeBytes(10000000);
    getCurrentLocation().then((_) => fetchData());
  }

  /// Local  variables
  final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;

  /// Subjects
  final _location = BehaviorSubject<LatLng>();
  final _featuredRestaurants = BehaviorSubject<List<Data>>();
  final _nearbyRestaurants = BehaviorSubject<List<Data>>();
  final _restaurants = BehaviorSubject<List<Data>>();
  final _events = BehaviorSubject<List<Data>>();

  /// Variables
  LatLng _myLocation;

  /// Stream getters

  Stream<LatLng> get location => _location.stream;

  Stream<List<Data>> get featuredRestaurants => _featuredRestaurants.stream;

  Stream<List<Data>> get nearbyRestaurants => _nearbyRestaurants.stream;

  Stream<List<Data>> get restaurants => _restaurants.stream;

  Stream<List<Data>> get events => _events.stream;

  /// Other functions
  void fetchData() {
    _fetchRestaurants();
    _fetchEvents();
  }

  void _fetchRestaurants() async {
    /// start showing loaders
    _featuredRestaurants.add(null);
    _nearbyRestaurants.add(null);
    _restaurants.add(null);

    /// network request
    final location = await getCurrentLocation().then((location) async {
      final response =
          await http.post('http://edibly.vassi.li/api/restaurants/discover',
              body: json.encode({
                'lat': location.latitude,
                'lon': location.longitude,
                'radius': 5000000000000000000
              }));
      final map = json.decode(response.body);

      final restaurantsWithoutRatingMap = Map<dynamic, dynamic>();
      map.forEach((r) => restaurantsWithoutRatingMap[r['rid'].toString()] = r);

      List<Data> restaurantsWithExtraData = [];
      List<Data> restaurantsWithoutExtraData = [];
      restaurantsWithoutRatingMap.forEach(
          (key, value) => restaurantsWithoutExtraData.add(Data(key, value)));
      await Future.forEach(restaurantsWithoutExtraData,
          (Data dataWithoutRating) async {
        //I filter out unrated and lower than rated 7 restaurants. Comment me out before production.
        if (dataWithoutRating.value['averagerating'] != null &&
            dataWithoutRating.value['averagerating'] >= 1) {
          Data dataWithRating =
              Data(dataWithoutRating.key, dataWithoutRating.value);

          //TODO - fix whatever the fuck happened w lat and lon
          dataWithRating.value['averagerating'] =
              dataWithoutRating.value['averagerating'];
          dataWithRating.value['lat'] =
              (dataWithRating.value['lat'] / 10000000);
          dataWithRating.value['lon'] = (dataWithRating.value['lon'] / 1000000);
          dataWithRating.value['distance'] =
              _distanceFromMeToDestination(LatLng(
            double.parse((dataWithRating.value['lat']).toString()),
            double.parse((dataWithRating.value['lon']).toString()),
          ));
          restaurantsWithExtraData.add(dataWithRating);
        }
        return null;
      });

      /// add nearby restaurants
      List<Data> nearbyRestaurants = restaurantsWithExtraData
          .take(10)
          //TODO: Filter ratings
          .toList(); //|| r.value['averagerating'] >= 7).take(10).toList();
      if (nearbyRestaurants.isNotEmpty) {
        _nearbyRestaurants.add(nearbyRestaurants);
      } else {
        _nearbyRestaurants.addError(localizations.nothingHereText);
      }

      /// add featured restaurants
      List<Data> featuredRestaurants = restaurantsWithExtraData
          .where((r) => r.value['featured'] == true)
          .take(10)
          .toList();
      if (featuredRestaurants.isNotEmpty) {
        _featuredRestaurants.add(restaurantsWithExtraData
            .where((r) => r.value['featured'] == true)
            .take(10)
            .toList());
      } else {
        _featuredRestaurants.addError(localizations.nothingHereText);
      }

      /// add restaurants
      _restaurants.add(restaurantsWithExtraData);
    });
  }

  void _fetchEvents() async {
    /// start showing loaders
    _events.add(null);

    List<Data> eventsWithExtraData = [];
    List<Data> eventsWithoutExtraData = [];

    /// network request

    await http
        .get('http://edibly.vassi.li/api/events')
        .then((http.Response response) {
      final map = json.decode(response.body);
      map.forEach(
          (event) => eventsWithoutExtraData.add(Data(event['eid'], event)));
    });

    for (var dataWithoutRating in eventsWithoutExtraData) {
      if (eventsWithoutExtraData.isEmpty) {
        return;
      }
      final id = dataWithoutRating.value['rid'];
      await (http.get('http://edibly.vassi.li/api/restaurants/$id'))
          .then((http.Response response) {
        final restaurant = json.decode(response.body);
        Data dataWithRating =
            Data(dataWithoutRating.value['eid'], dataWithoutRating.value);
        try {
          dataWithRating.value['rname'] = restaurant['name'];
          dataWithRating.value['lat'] = restaurant['lat'];
          dataWithRating.value['lon'] = restaurant['lon'] / 10;
          dataWithRating.value['distance'] =
              _distanceFromMeToDestination(LatLng(
            double.parse(dataWithRating.value['lat'].toString()),
            double.parse(dataWithRating.value['lon'].toString()),
          ));

          //TODO: - reenable this once you are able to add events
          // if (DateTime.fromMillisecondsSinceEpoch(
          //         dataWithRating.value['end'] * 1000)
          //     .isAfter(DateTime.now()))
          eventsWithExtraData.add(dataWithRating);
        } catch (_) {}
      });
    }

    /// sort by distance
    eventsWithExtraData.sort((a, b) {
      double diff = a.value['distance'] - b.value['distance'];
      return diff < 0 ? -1 : (diff == 0 ? 0 : 1);
    });

    /// add events
    if (eventsWithExtraData.isNotEmpty) {
      _events.add(eventsWithExtraData);
      //Maybe?
    } else {
      _events.addError(localizations.noEvents);
    }
  }

  Future<LatLng> getCurrentLocation() async {
    LatLng fallbackLatLng = LatLng(53.544406, -113.490915);
    LatLng latLng;
    try {
      Location location = Location();
      if (location != null) {
        LocationData locationData =
            await location.getLocation().timeout(Duration(seconds: 1000));
        if (locationData != null) {
          latLng = LatLng(locationData.latitude, locationData.longitude);
        }
      }
    } catch (e) {
      latLng = fallbackLatLng;
    }
    LatLng locationToBeReturned = latLng == null ? fallbackLatLng : latLng;
    _myLocation = locationToBeReturned;
    _location.add(locationToBeReturned);
    return locationToBeReturned;
  }

  double _distanceFromMeToDestination(LatLng destination) {
    if (_myLocation == null) return 0;
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((destination.latitude - _myLocation.latitude) * p) / 2 +
        cos(_myLocation.latitude * p) *
            cos(destination.latitude * p) *
            (1 - cos((destination.longitude - _myLocation.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a));
  }

  /// Dispose function
  void dispose() {
    _location.close();
    _featuredRestaurants.close();
    _nearbyRestaurants.close();
    _restaurants.close();
    _events.close();
  }
}
