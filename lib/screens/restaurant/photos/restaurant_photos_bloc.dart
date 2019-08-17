import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  final _restaurantPhotos = BehaviorSubject<List<Data>>();

  /// Stream getters
  Stream<List<Data>> get restaurantPhotos => _restaurantPhotos.stream;

  /// Other functions
  void getRestaurantPhotos() async {
    List<Data> restaurantPhotosData = [];
    http
        .get("http://base.edibly.ca/api/restaurants/$restaurantKey/pictures")
        .then((response) {
      if (response.body != null) {
        (json.decode(response.body)).forEach((r) {
          restaurantPhotosData.add(Data(r['rrid'], r));
        });
        _restaurantPhotos..add(restaurantPhotosData);
      } else {
        _restaurantPhotos..add([Data(null, null)]);
      }
    });
  }

  /// Dispose function
  void dispose() {
    _restaurantPhotos.close();
  }
}
