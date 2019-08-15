import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:edibly/models/data.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:rxdart/rxdart.dart';

//TODO: - Sort search by distance by default
enum AddReviewState {
  SUCCESSFUL,
  FAILED,
  TRYING,
  IDLE,
}

class SearchBloc {
  final FirebaseUser firebaseUser;
  AppLocalizations localizations;

  SearchBloc({@required this.firebaseUser}) {
    _firebaseDatabase.setPersistenceEnabled(true);
    _firebaseDatabase.setPersistenceCacheSizeBytes(10000000);
  }

  /// Local  variables
  final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;

  /// Subjects
  final _ratingSlider = BehaviorSubject<double>();
  final _distanceSlider = BehaviorSubject<double>();
  final _allRestaurants = BehaviorSubject<List<Data>>();
  final _filteredRestaurants = BehaviorSubject<List<Data>>();
  final _bookmarkedRestaurants = BehaviorSubject<List<Data>>();
  final _addReviewState = BehaviorSubject<AddReviewState>();
  final _restaurantName = BehaviorSubject<String>();
  final _restaurantLocation = BehaviorSubject<String>();

  /// Variables
  int _filterRestaurantsCallCounter = 0;
  double _distanceFilterValue = -1;
  double _ratingFilterValue = -1;
  LatLng _myLocation;
  String _keyword;

  /// Stream getters
  Stream<double> get ratingSlider => _ratingSlider.stream;

  Stream<double> get distanceSlider => _distanceSlider.stream;

  Stream<List<Data>> get allRestaurants => _allRestaurants.stream;

  Stream<List<Data>> get filteredRestaurants => _filteredRestaurants.stream;

  Stream<List<Data>> get bookmarkedRestaurants => _bookmarkedRestaurants.stream;

  Stream<AddReviewState> get addReviewState => _addReviewState.stream;

  Stream<String> get restaurantName => _restaurantName.stream;

  Stream<String> get restaurantLocation => _restaurantLocation.stream;

  /// Setters
  void setDistanceFilterValue() {
    double distanceFilterValue = _distanceSlider.value;
    if (distanceFilterValue == null) distanceFilterValue = -1;
    if (distanceFilterValue >= 30) distanceFilterValue = -1;
    _distanceFilterValue = distanceFilterValue;
  }

  void setRatingFilterValue() {
    double ratingFilterValue = _ratingSlider.value;
    if (ratingFilterValue == null) ratingFilterValue = -1;
    if (ratingFilterValue == 0) ratingFilterValue = -1;
    _ratingFilterValue = ratingFilterValue;
  }

  Function(double value) get setRatingSliderValue => _ratingSlider.add;

  Function(double value) get setDistanceSliderValue => _distanceSlider.add;

  Function(AddReviewState) get setAddReviewState => _addReviewState.add;

  /// Void functions
  void setRestaurantName(String name) {
    _restaurantName.add(name);
    _addReviewState.add(AddReviewState.IDLE);
  }

  void setRestaurantLocation(String location) {
    _restaurantLocation.add(location);
    _addReviewState.add(AddReviewState.IDLE);
  }

  Future<Data> addReview({
    @required AppLocalizations localizations,
  }) async {
    final restaurantName = _restaurantName.value;
    final restaurantLocation = _restaurantLocation.value;
    final addReviewState = _addReviewState.value;

    if (addReviewState == AddReviewState.TRYING) return null;
    _addReviewState.add(AddReviewState.TRYING);

    bool credentialsAreEmpty = false;

    if (restaurantName == null || restaurantName.isEmpty) {
      _restaurantName.addError(localizations.errorEmptyField);
      credentialsAreEmpty = true;
    }
    if (restaurantLocation == null || restaurantLocation.isEmpty) {
      _restaurantLocation.addError(localizations.errorEmptyField);
      credentialsAreEmpty = true;
    }

    if (!credentialsAreEmpty) {
      _firebaseDatabase
          .reference()
          .child('addedRestaurants')
          .orderByKey()
          .limitToLast(1)
          .once()
          .then((snapshot) async {
        String restaurantKey = snapshot?.value != null
            ? 'A${int.parse(snapshot.key.substring(1)) + 1}'
            : 'A1';
        await _firebaseDatabase
            .reference()
            .child('addedRestaurants')
            .child(restaurantKey)
            .set({
          'key': restaurantKey,
          'name': restaurantName,
          'location': restaurantLocation,
        }).catchError((error) {
          _addReviewState.addError(AddReviewState.FAILED);
          return null;
        });
        _addReviewState.addError(AddReviewState.SUCCESSFUL);
        return Data(restaurantKey, restaurantName);
      }).catchError((error) {
        _addReviewState.addError(AddReviewState.FAILED);
      });
    } else if (credentialsAreEmpty) {
      _addReviewState.add(AddReviewState.IDLE);
    }
    return null;
  }

  /// Other functions
  void getAllRestaurants() async {
    _allRestaurants.add(null);
    List<Data> restaurantsWithoutRating = [];
    await getCurrentLocation().then((location) async {
      //TODO: - testing only
      location = LatLng(53.522385, 113.622810);
    final response = await http.post('http://base.edibly.ca/api/restaurants/nearby', body: json.encode({'lat' : location.latitude, 'lon' : location.longitude, 'radius' : 5000000000000000000}));
    final map = json.decode(response.body);
    print(map);
    final restaurantsWithoutRatingMap = Map<dynamic, dynamic>();
    map.forEach((r) => restaurantsWithoutRatingMap[r['rid'].toString()] = r);

    restaurantsWithoutRatingMap.forEach((key, value) {
      value['distance'] = _distanceFromMeToDestination(LatLng(
        double.parse((value['lat']/10000000).toString()),
        double.parse((value['lon']/10000000).toString()),
      ));
            restaurantsWithoutRating.add(Data(key, value));

    });

        restaurantsWithoutRating.sort((a, b) {
          double diff = a.value['distance'] - b.value['distance'];
          return diff < 0 ? -1 : (diff == 0 ? 0 : 1);
        });
    _allRestaurants.add(restaurantsWithoutRating);
    });
  }

  void filterRestaurants(String keyword) async {
    if (keyword == null) keyword = _keyword;
    _keyword = keyword;
    _filteredRestaurants.add(null);
    List<Data> filteredRestaurants = [];
    List<Data> restaurantsToFilter = [];
    //Vassilibase conversion: search restaurants, then filter.
    var url =
        "http://base.edibly.ca/api/restaurants/search/" + toUrlFormat(keyword);
    await http.get(url).then((response) {
      final map = json.decode(response.body);
      map.forEach((r) => restaurantsToFilter.add(Data(r['rid'], r)));

      //TODO: - why isn't this being caleld?!?!?
      for (var data in restaurantsToFilter) {
        /// rating filter
        if (_ratingFilterValue == -1 ||
            (data.value['averagerating'] != null &&
                double.parse(data.value['averagerating'].toString()) >=
                    _ratingFilterValue)) {
          /// distance filter
          if (_distanceFilterValue == -1 ||
              (data.value['lat'] != null &&
                  data.value['lon'] != null &&
                  _distanceToRestaurant(LatLng(
                        double.parse(data.value['lat'].toString()),
                        double.parse(data.value['lon'].toString()),
                      )) <=
                      _distanceFilterValue)) {
            filteredRestaurants.add(data);
          }
        }
      }
      _filteredRestaurants.add(restaurantsToFilter);
    });
    // if (currentFilterRestaurantsCallCount == _filterRestaurantsCallCounter - 1) {
    // }
  }

  Stream<Event> getRestaurantBookmarkValue(String uid, String restaurantKey) {
    return _firebaseDatabase
        .reference()
        .child('starredRestaurants')
        .child(uid)
        .child(restaurantKey)
        .onValue;
  }

  void setRestaurantBookmarkValue(
      String uid, String restaurantKey, bool value) {
    _firebaseDatabase
        .reference()
        .child('starredRestaurants')
        .child(uid)
        .child(restaurantKey)
        .set(value ? 1 : 0);
  }

  Future<LatLng> getCurrentLocation() async {
    LatLng fallbackLatLng = LatLng(53.544406, -113.490915);
    LatLng latLng;
    try {
      Location location = Location();
      if (location != null) {
        LocationData locationData =
            await location.getLocation().timeout(Duration(seconds: 10));
        if (locationData != null) {
          latLng = LatLng(locationData.latitude, locationData.longitude);
        }
      }
    } catch (e) {
      latLng = fallbackLatLng;
    }
    LatLng locationToBeReturned = latLng == null ? fallbackLatLng : latLng;
    _myLocation = locationToBeReturned;
    return locationToBeReturned;
  }

  double _distanceToRestaurant(LatLng restaurantLocation) {
    if (_myLocation == null) return 0;
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((restaurantLocation.latitude - _myLocation.latitude) * p) / 2 +
        cos(_myLocation.latitude * p) *
            cos(restaurantLocation.latitude * p) *
            (1 -
                cos((restaurantLocation.longitude - _myLocation.longitude) *
                    p)) /
            2;
    return 12742 * asin(sqrt(a));
  }

  void getBookmarkedRestaurants() async {
    _bookmarkedRestaurants.add(null);
    _firebaseDatabase
        .reference()
        .child('starredRestaurants')
        .child(firebaseUser.uid)
        .onValue
        .listen((event) async {
      List<String> bookmarkKeys = [];
      List<Data> restaurantsWithRating = [];
      List<Data> restaurantsWithoutRating = [];
      if (event?.snapshot?.value != null) {
        Map<dynamic, dynamic> bookmarks = event.snapshot.value;
        bookmarks.forEach((key, value) {
          if (value.toString() == '1') bookmarkKeys.add(key);
        });
      }

      await Future.forEach(bookmarkKeys, (String restaurantKey) async {
        DataSnapshot restaurantSnapshot = await _firebaseDatabase
            .reference()
            .child('restaurants')
            .child(restaurantKey)
            .once();
        restaurantsWithoutRating
            .add(Data(restaurantSnapshot.key, restaurantSnapshot.value));
        return null;
      });

      await Future.forEach(restaurantsWithoutRating,
          (Data dataWithoutRating) async {
        DataSnapshot ratingSnapshot = await _firebaseDatabase
            .reference()
            .child('restaurantRatings')
            .child(dataWithoutRating.key)
            .once();
        Data dataWithRating =
            Data(dataWithoutRating.key, dataWithoutRating.value);
        try {
          dataWithRating.value['rating'] = ratingSnapshot?.value;
          restaurantsWithRating.add(dataWithRating);
        } catch (_) {}
        return null;
      });
      _bookmarkedRestaurants.add(restaurantsWithRating);
    });
  }

  //I am dumb and bad at coding
  String toUrlFormat(String string) {
    List<String> urlFormattedList = [];
    List<String> stringList = string.split("");
    stringList.forEach((c) {
      urlFormattedList.add((c.toString() == " ") ? "+" : c.toString());
    });
    return urlFormattedList.join();
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
    _ratingSlider.close();
    _distanceSlider.close();
    _allRestaurants.close();
    _filteredRestaurants.close();
    _bookmarkedRestaurants.close();
    _addReviewState.close();
    _restaurantName.close();
    _restaurantLocation.close();
  }
}
