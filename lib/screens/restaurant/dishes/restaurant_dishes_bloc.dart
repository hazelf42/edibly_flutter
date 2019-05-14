import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import 'package:edibly/models/data.dart';
import 'package:edibly/main_bloc.dart';

class RestaurantDishesBloc {
  final String restaurantKey;

  RestaurantDishesBloc({@required this.restaurantKey}) {
    _firebaseDatabase.setPersistenceEnabled(true);
    _firebaseDatabase.setPersistenceCacheSizeBytes(10000000);
  }

  /// Local  variables
  final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;

  /// Subjects
  final _dishes = BehaviorSubject<List<Data>>();
  final _forcedDiet = BehaviorSubject<Diet>();

  /// Stream getters
  Stream<List<Data>> get dishes => _dishes.stream;

  Stream<Diet> get forcedDiet => _forcedDiet.stream;

  /// Setters
  Function(Diet) get setForcedDiet => _forcedDiet.add;

  void getDishes() async {
    _firebaseDatabase.reference().child('dishes').child(restaurantKey).onValue.listen((event) async {
      Map<dynamic, dynamic> dishesMap = event?.snapshot?.value;
      if (dishesMap == null || dishesMap.isEmpty) {
        _dishes.add([]);
        return;
      }
      List<Data> dishesWithoutRating = [];
      List<Data> dishesWithRating = [];
      dishesMap.forEach((key, value) => dishesWithoutRating.add(Data(key, value)));
      await Future.forEach(dishesWithoutRating, (Data dish) async {
        try {
          Data dishWithRating = Data(dish.key, dish.value);

          /// retrieve rating
          DataSnapshot ratingSnapshot =
              await _firebaseDatabase.reference().child('dishRatings').child(restaurantKey).child(dishWithRating.key).once();
          if (ratingSnapshot?.value != null) dishWithRating.value['rating'] = ratingSnapshot?.value;

          /// insert newly acquired dish to the start of new page
          dishesWithRating.add(dishWithRating);
        } catch (_) {}
      });

      /// publish an update to the stream
      _dishes.add(dishesWithRating);
    });
  }

  /// Dispose function
  void dispose() {
    _dishes.close();
    _forcedDiet.close();
  }
}
