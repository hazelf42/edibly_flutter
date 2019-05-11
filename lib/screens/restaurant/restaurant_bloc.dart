import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import 'package:edibly/models/data.dart';

class RestaurantBloc {
  final String firebaseUserId;
  final String restaurantKey;

  RestaurantBloc({
    @required this.firebaseUserId,
    @required this.restaurantKey,
  }) {
    _firebaseDatabase.setPersistenceEnabled(true);
    _firebaseDatabase.setPersistenceCacheSizeBytes(10000000);
  }

  /// Local  variables
  final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;

  /// Subjects
  final _restaurant = BehaviorSubject<Data>();

  /// Stream getters
  Stream<Data> get restaurant => _restaurant.stream;

  /// Other functions
  void getRestaurant() async {
    _firebaseDatabase.reference().child('restaurants').child(restaurantKey).onValue.listen((event) async {
      if (event?.snapshot?.value != null) {
        try {
          Data restaurantData = Data(event.snapshot.key, event.snapshot.value);
          DataSnapshot ratingSnapshot = await _firebaseDatabase.reference().child('restaurantRatings').child(restaurantKey).once();
          restaurantData.value['rating'] = ratingSnapshot?.value;
          DataSnapshot tipsSnapshot =
              await _firebaseDatabase.reference().child('restaurantTips').child(restaurantKey).orderByKey().limitToLast(1).once();
          restaurantData.value['featured_tip'] = tipsSnapshot?.value;
          _restaurant..add(restaurantData);
        } catch (_) {}
      }
    });
  }

  Stream<Event> getRestaurantBookmarkValue(String uid, String restaurantKey) {
    return _firebaseDatabase.reference().child('starredRestaurants').child(uid).child(restaurantKey).onValue;
  }

  void setRestaurantBookmarkValue(String uid, String restaurantKey, bool value) {
    _firebaseDatabase.reference().child('starredRestaurants').child(uid).child(restaurantKey).set(value ? 1 : 0);
  }

  /// Dispose function
  void dispose() {
    _restaurant.close();
  }
}
