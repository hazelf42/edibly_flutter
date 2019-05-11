import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import 'package:edibly/models/data.dart';

class RestaurantPhotosBloc {
  final String restaurantKey;

  RestaurantPhotosBloc({
    @required this.restaurantKey,
  }) {
    _firebaseDatabase.setPersistenceEnabled(true);
    _firebaseDatabase.setPersistenceCacheSizeBytes(10000000);
  }

  /// Local  variables
  final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;

  /// Subjects
  final _restaurantPhotos = BehaviorSubject<Data>();

  /// Stream getters
  Stream<Data> get restaurantPhotos => _restaurantPhotos.stream;

  /// Other functions
  void getRestaurantPhotos() async {
    _firebaseDatabase.reference().child('restaurantImages').child(restaurantKey).onValue.listen((event) async {
      if (event?.snapshot?.value != null) {
        try {
          Data restaurantPhotosData = Data(event.snapshot.key, event.snapshot.value);
          _restaurantPhotos..add(restaurantPhotosData);
        } catch (_) {}
      }
    });
  }

  /// Dispose function
  void dispose() {
    _restaurantPhotos.close();
  }
}
