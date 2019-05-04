import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import 'package:edibly/bloc_helper/validators.dart';
import 'package:edibly/values/pref_keys.dart';
import 'package:flutter/foundation.dart';

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

  /// Default values
  static const int bottomNavigationBarCurrentIndexDefaultValue = 0;
  static const bool darkModeEnabledDefaultValue = true;
  static const bool glutenFreeDefaultValue = false;
  static const Diet dietDefaultValue = Diet.VEGAN;

  /// Subjects
  final _bottomNavigationBarCurrentIndex = BehaviorSubject<int>.seeded(bottomNavigationBarCurrentIndexDefaultValue);
  final _darkModeEnabled = BehaviorSubject<bool>.seeded(darkModeEnabledDefaultValue);
  final _glutenFree = BehaviorSubject<bool>.seeded(glutenFreeDefaultValue);
  final _diet = BehaviorSubject<Diet>.seeded(dietDefaultValue);

  /// Stream getters
  Stream<int> get bottomNavigationBarCurrentIndex => _bottomNavigationBarCurrentIndex.stream;

  Stream<bool> get darkModeEnabled => _darkModeEnabled.stream;

  Stream<bool> get glutenFree => _glutenFree.stream;

  Stream<Diet> get diet => _diet.stream;

  /// Void functions
  void setBottomNavigationBarCurrentIndex(int value) {
    _bottomNavigationBarCurrentIndex.add(value);
  }

  void toggleDarkMode() async {
    _darkModeEnabled.add(!_darkModeEnabled.value);
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setBool(PrefKeys.darkModeEnabled, _darkModeEnabled.value);
  }

  void toggleGlutenFree(String uid) {
    _glutenFree.add(!_glutenFree.value);
    _setCurrentUserInfoWithoutCallback(uid, {
      'isGlutenFree': _glutenFree.value,
    });
  }

  void setDiet(String uid, Diet diet) {
    _diet.add(diet);
    _setCurrentUserInfoWithoutCallback(uid, {
      'dietName': diet == Diet.VEGAN ? 'vegan' : 'vegetarian',
    });
  }

  void _setCurrentUserInfoWithoutCallback(String uid, dynamic value) {
    _firebaseDatabase.reference().child('userProfiles/$uid').update(value);
  }

  /// Other functions
  Future<FirebaseUser> getCurrentFirebaseUser() async {
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
    return await _firebaseAuth.currentUser();
  }

  Stream<Event> getUser(String uid) {
    return _firebaseDatabase.reference().child('userProfiles/$uid').onValue;
  }

  Stream<Event> getRestaurant(String key) {
    return _firebaseDatabase.reference().child('restaurants').child('$key').onValue;
  }

  /// Post like functions
  void likePostByUser({@required String postKey, @required String uid}) {
    _firebaseDatabase.reference().child('likes').child(postKey).update({
      uid: 1,
    });
  }

  void unlikePostByUser({@required String postKey, @required String uid}) {
    _firebaseDatabase.reference().child('likes').child(postKey).update({
      uid: 0,
    });
  }

  Stream<Event> isPostLikedByUser({@required String postKey, @required String uid}) {
    return _firebaseDatabase.reference().child('likes').child(postKey).child(uid).onValue;
  }

  /// Dispose function
  void dispose() {
    _bottomNavigationBarCurrentIndex.close();
    _darkModeEnabled.close();
    _glutenFree.close();
    _diet.close();
  }
}
