import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:location/location.dart';
import 'package:rxdart/rxdart.dart';

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
    _firebaseDatabase.reference().child('restaurants').onValue.listen((event) async {
      List<Data> restaurantsWithExtraData = [];
      List<Data> restaurantsWithoutExtraData = [];
      if (event?.snapshot?.value != null) {
        Map<dynamic, dynamic> restaurantsWithoutRatingMap = event.snapshot.value;
        restaurantsWithoutRatingMap.forEach((key, value) => restaurantsWithoutExtraData.add(Data(key, value)));
      }

      /// get extra data
      await Future.forEach(restaurantsWithoutExtraData, (Data dataWithoutRating) async {
        DataSnapshot ratingSnapshot = await _firebaseDatabase.reference().child('restaurantRatings').child(dataWithoutRating.key).once();
        Data dataWithRating = Data(dataWithoutRating.key, dataWithoutRating.value);
        try {
          dataWithRating.value['rating'] = ratingSnapshot?.value;
          dataWithRating.value['distance'] = _distanceFromMeToDestination(LatLng(
            double.parse(dataWithRating.value['lat'].toString()),
            double.parse(dataWithRating.value['lng'].toString()),
          ));
          restaurantsWithExtraData.add(dataWithRating);
        } catch (_) {}
        return null;
      });

      /// sort by distance
      restaurantsWithExtraData.sort((a, b) {
        double diff = a.value['distance'] - b.value['distance'];
        return diff < 0 ? -1 : (diff == 0 ? 0 : 1);
      });

      /// add nearby restaurants
      List<Data> nearbyRestaurants =
          restaurantsWithExtraData.where((r) => r.value['rating'] != null && r.value['rating']['numRating'] >= 7).take(10).toList();
      if (nearbyRestaurants.isNotEmpty) {
        _nearbyRestaurants.add(nearbyRestaurants);
      } else {
        _nearbyRestaurants.addError(localizations.nothingHereText);
      }

      /// add featured restaurants
      List<Data> featuredRestaurants = restaurantsWithExtraData.where((r) => r.value['featured'] == true).take(10).toList();
      if (featuredRestaurants.isNotEmpty) {
        _featuredRestaurants.add(restaurantsWithExtraData.where((r) => r.value['featured'] == true).take(10).toList());
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

    /// network request
    _firebaseDatabase.reference().child('events').onValue.listen((event) async {
      List<Data> eventsWithExtraData = [];
      List<Data> eventsWithoutExtraData = [];
      if (event?.snapshot?.value != null) {
        Map<dynamic, dynamic> restaurantsWithoutRatingMap = event.snapshot.value;
        restaurantsWithoutRatingMap.forEach((key, value) => eventsWithoutExtraData.add(Data(key, value)));
      }

      /// get extra data
      await Future.forEach(eventsWithoutExtraData, (Data dataWithoutRating) async {
        DataSnapshot ratingSnapshot =
            await _firebaseDatabase.reference().child('restaurants').child(dataWithoutRating.value['restaurantId']).once();
        Data dataWithRating = Data(dataWithoutRating.key, dataWithoutRating.value);
        try {
          dataWithRating.value['restaurant'] = ratingSnapshot?.value;
          dataWithRating.value['distance'] = _distanceFromMeToDestination(LatLng(
            double.parse(dataWithRating.value['lat'].toString()),
            double.parse(dataWithRating.value['lng'].toString()),
          ));
          if (DateTime.fromMillisecondsSinceEpoch(dataWithRating.value['endTime'] * 1000).isAfter(DateTime.now()))
            eventsWithExtraData.add(dataWithRating);
        } catch (_) {}
        return null;
      });

      /// sort by distance
      eventsWithExtraData.sort((a, b) {
        double diff = a.value['distance'] - b.value['distance'];
        return diff < 0 ? -1 : (diff == 0 ? 0 : 1);
      });

      /// add events
      if (eventsWithExtraData.isNotEmpty) {
        _events.add(eventsWithExtraData);
      } else {
        _events.addError(localizations.noEvents);
      }
    });
  }

  Future<LatLng> getCurrentLocation() async {
    LatLng fallbackLatLng = LatLng(53.544406, -113.490915);
    LatLng latLng;
    try {
      Location location = Location();
      if (location != null) {
        LocationData locationData = await location.getLocation().timeout(Duration(seconds: 10));
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
        cos(_myLocation.latitude * p) * cos(destination.latitude * p) * (1 - cos((destination.longitude - _myLocation.longitude) * p)) / 2;
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
