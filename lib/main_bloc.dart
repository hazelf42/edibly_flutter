import 'dart:convert';

import 'package:edibly/bloc_helper/validators.dart';
import 'package:edibly/models/data.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/values/pref_keys.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

/* 
Vassilibase stuff I'm waiting for
Comments
Likes to be converted from iuid to uuid
500 error when uploading photos?
*/
enum Diet {
  VEGETARIAN,
  VEGAN,
}

class MainBloc extends Object with Validators {
  MainBloc() {
    _firebaseDatabase.setPersistenceEnabled(true);
    _firebaseDatabase.setPersistenceCacheSizeBytes(10000000);
  }

  /// Variables
  final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;
  AppLocalizations localizations;

  /// Default values
  static const int bottomNavigationBarCurrentIndexDefaultValue = 0;
  static const bool darkModeEnabledDefaultValue = false;
  static const int glutenFreeDefaultValue = 0;
  static const Diet dietDefaultValue = Diet.VEGAN;

  /// Subjects
  final _bottomNavigationBarCurrentIndex =
      BehaviorSubject<int>.seeded(bottomNavigationBarCurrentIndexDefaultValue);
  final _darkModeEnabled = BehaviorSubject<bool>();
  final _glutenFree = BehaviorSubject<int>.seeded(0);
  final _diet = BehaviorSubject<Diet>.seeded(dietDefaultValue);

  /// Stream getters
  Stream<int> get bottomNavigationBarCurrentIndex =>
      _bottomNavigationBarCurrentIndex.stream;

  Stream<bool> get darkModeEnabled => _darkModeEnabled.stream;

  Stream<int> get glutenFree => _glutenFree.stream;

  Stream<Diet> get diet => _diet.stream;

  /// Void functions
  void setBottomNavigationBarCurrentIndex(int value) {
    _bottomNavigationBarCurrentIndex.add(value);
  }

  void setDarkModeEnabled(bool darkModeEnabled) async {
    _darkModeEnabled.add(darkModeEnabled);
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setBool(PrefKeys.darkModeEnabled, darkModeEnabled);
  }

  Future<void> toggleGlutenFree(String uid) async {
    _glutenFree.add((_glutenFree.value == 0) ? 1 : 0);
    
    if (uid != null) {
      var value =
          json.encode({"glutenfree": "${_glutenFree.value == 0 ? 1 : 0}"});
      await http
          .put("http://edibly.vassi.li/api/profiles/${(uid)}",
              body: value)
          .then((http.Response response) {
        print(response.statusCode);
        return true;
      });
    }
  }

  void setGlutenFree(String uid, int glutenFree) {
    _glutenFree.add(glutenFree);
    if (uid != null) {
      _setCurrentUserInfoWithoutCallback(uid, {
        'glutenFree': glutenFree,
      });
    }
  }

  Future<bool> setDiet(String uid, Diet diet) async {
    _diet.add(diet);

    if (uid != null) {
      var value =
          json.encode({"veglevel": "${diet == Diet.VEGAN ? '2' : '1'}"});
      await http
          .put("http://edibly.vassi.li/api/profiles/${(uid)}",
              body: value)
          .then((http.Response response) {
        print(response.statusCode);
      });
    }

    return true;
  }

  void _setCurrentUserInfoWithoutCallback(String uid, dynamic value) async {
    await http
        .put("http://edibly.vassi.li/api/profiles/$uid", body: json.encode(value))
        .then((http.Response response) {
      print(response.statusCode);
    });
  }

  /// Other functions
  Future<FirebaseUser> getCurrentFirebaseUser() async {
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
    return await _firebaseAuth.currentUser();
  }

  void deletePost({
    @required Data post,
    @required String firebaseUserId,
  }) {
    var url = '';

    switch (post.value['type']) {
      case 0:
        final id = post.value['rrid'];
        url = "http://edibly.vassi.li/api/reviews/$id";
        break;
      case 1:
        final id = post.value['rpid'];
        url = "http://edibly.vassi.li/api/pictures/$id";
        break;
      case 2:
        final id = post.value['rtid'];
        url = "http://edibly.vassi.li/api/tips/$id";
        break;
    }
    //TODO: - VASSILI: Implement deleting (or "deleting") posts
    http.delete(url).then((r) {
      print(r);
    });
  }

  /// Post like functions
  Future<void> likePostByUser(
      {@required String postKey,
      @required String uid,
      @required int postType}) async {
    var type = "";    if (postType == 0) {
      type = "review";
    } else if (postType == 2) {
      type = "tip";
    } else {
      type = "review";
    }
    await http
        .post("http://edibly.vassi.li/api/like",
            body: json.encode({
              'uid': uid,
              'type': type,
              'id': postKey,
            }))
        .then((http.Response response) {
      print(response.statusCode);
    });
  }

  Future<void> unlikePostByUser(
      {@required String postKey,
      @required String uid,
      @required int postType}) async {
    var type = "";
    //TODO :- I'm dumb and bad at coding
    if (postType == 0) {
      type = "review";
    } else if (postType == 2) {
      type = "tip";
    } else {
      type = "review";
    }
    await http
        .post("http://edibly.vassi.li/api/unlike",
            body: json.encode({
              'uid': uid,
              'type': type,
              'id': postKey,
            }))
        .then((http.Response response) {
      print(response.statusCode);
    });
  }

  // Stream<Event> isPostLikedByUser(

  // }

  /// Dispose function
  void dispose() {
    _bottomNavigationBarCurrentIndex.close();
    _darkModeEnabled.close();
    _glutenFree.close();
    _diet.close();
  }
}
