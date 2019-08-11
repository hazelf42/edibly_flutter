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
import 'package:rxdart/rxdart.dart';

//TODO: - Sort search by distance by default
enum AddReviewState { 
  SUCCESSFUL,
  FAILED,
  TRYING,
  IDLE,
}

class SearchProfileBloc {
  final FirebaseUser firebaseUser;
  AppLocalizations localizations;

  SearchProfileBloc({@required this.firebaseUser}) {
    _firebaseDatabase.setPersistenceEnabled(true);
    _firebaseDatabase.setPersistenceCacheSizeBytes(10000000);
  }

  /// Local  variables
  final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;

  /// Subjects
  final _ratingSlider = BehaviorSubject<double>();
  final _distanceSlider = BehaviorSubject<double>();
  final _profiles = BehaviorSubject<List<Data>>();
  final _filteredRestaurants = BehaviorSubject<List<Data>>();
  final _bookmarkedRestaurants = BehaviorSubject<List<Data>>();
  final _addReviewState = BehaviorSubject<AddReviewState>();
  final _restaurantName = BehaviorSubject<String>();
  final _restaurantLocation = BehaviorSubject<String>();

  /// Variables
  String _keyword;

  /// Stream getters
  Stream<double> get ratingSlider => _ratingSlider.stream;

  Stream<double> get distanceSlider => _distanceSlider.stream;

  Stream<List<Data>> get profiles => _profiles.stream;

  Stream<List<Data>> get filteredRestaurants => _filteredRestaurants.stream;

  Stream<List<Data>> get bookmarkedRestaurants => _bookmarkedRestaurants.stream;

  Stream<AddReviewState> get addReviewState => _addReviewState.stream;

  Stream<String> get restaurantName => _restaurantName.stream;

  Stream<String> get restaurantLocation => _restaurantLocation.stream;

  /// Other functions
  
  void filterRestaurants(String keyword) async {
    AppLocalizations localizations;
    if (keyword == null) keyword = _keyword;
    _keyword = keyword;
    _filteredRestaurants.add(null);
    List<Data> profiles = [];
    //Vassilibase conversion: search restaurants, then filter.
    var url =
        "http://edibly.vassi.li/api/profiles/search/$keyword";
    await http.get(url).then((response) {
      final map = json.decode(response.body);
      map.forEach((p) => profiles.add(Data(p['uid'], p)));
      });
      _profiles.add(profiles);

  }
  
  void autocomplete(String keyword) async {
    if (keyword == null) keyword = _keyword;
    _keyword = keyword;
    _filteredRestaurants.add(null);
    List<Data> profiles = [];
    //Vassilibase conversion: search restaurants, then filter.
    var url =
        "http://edibly.vassi.li/api/profiles/complete/$keyword";
    await http.get(url).then((response) {
      final map = json.decode(response.body);
      map.forEach((p) => profiles.add(Data(p['uid'], p)));
      });
      _profiles.add(profiles);
  }
  
  Future<bool> isFollowing({
    @required profileUid, 
    @required currentUid
  }) async { 
    bool isFollowing;
    await http
        .get("http://edibly.vassi.li/api/profiles/$currentUid/following"   )
        .then((response) {
      (json.decode(response.body)).forEach((profile) {
        if (profile['uid'] == profileUid) {
           isFollowing= true;
          return isFollowing;
        }  
      }); if (isFollowing != true) {
        isFollowing = false;
      };
    });
    return isFollowing;
  }

  Future<bool> followUser({
    //This function also unfollows profiles if the user is already following them because im a lazy goon who doesnt know whats good for me
    @required String currentUid,
    @required String profileUid,
    @required bool isFollowing
  }) async {
    if (currentUid == profileUid) {
      print("You can't follow yourself");
      return true;
    }

     {
      if (isFollowing) {
        final body = {'uid': currentUid, 'follow': profileUid};
        http
            .post("http://edibly.vassi.li/api/unfollow",
                body: json.encode(body))
            .then((http.Response response) {
          final int statusCode = response.statusCode;
          if (statusCode < 200 || statusCode > 400) {
            throw new Exception(
                "Error while sending data" + statusCode.toString());
          }
        });
      } else {
        final body = {'uid': currentUid, 'follow': profileUid };
        http
            .post("http://edibly.vassi.li/api/follow", body: json.encode(body))
            .then((http.Response response) {
          final int statusCode = response.statusCode;
          if (statusCode < 200 || statusCode > 400) {
            throw new Exception(
                "Error while sending data" + statusCode.toString());
          }
        });
      }
    }
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

  /// Dispose function
  void dispose() {
    _ratingSlider.close();
    _distanceSlider.close();
    _profiles.close();
    _filteredRestaurants.close();
    _bookmarkedRestaurants.close();
    _addReviewState.close();
    _restaurantName.close();
    _restaurantLocation.close();
  }
}
