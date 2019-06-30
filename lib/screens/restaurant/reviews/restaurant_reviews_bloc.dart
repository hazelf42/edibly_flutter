import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'package:edibly/models/data.dart';

class RestaurantReviewsBloc {
  final String restaurantKey;

  RestaurantReviewsBloc({@required this.restaurantKey}) {
    _firebaseDatabase.setPersistenceEnabled(true);
    _firebaseDatabase.setPersistenceCacheSizeBytes(10000000);
  }

  /// Static variables
  static const int REVIEWS_PER_PAGE = 5;

  /// Local  variables
  final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;
  StreamSubscription onChildAddedListener;
  bool _fetchStarted = false;
  int _reviewsInCurrentPage = 0;
  int _currentPage = 0;

  /// Subjects
  final _reviews = BehaviorSubject<List<Data>>();

  /// Stream getters
  Stream<List<Data>> get reviews => _reviews.stream;

  /// Other functions
  void clearReviews() {
    _reviews.add([]);
    _fetchStarted = false;
    _reviewsInCurrentPage = 0;
    _currentPage = 0;
  }

  void getReviews() async {
    /// if page is not fully loaded, return
    if (_fetchStarted && _reviewsInCurrentPage < REVIEWS_PER_PAGE) {
      return;
    }

    /// if page is fully loaded then start loading next page
    else if (_reviewsInCurrentPage == REVIEWS_PER_PAGE + (_currentPage == 0 ? 0 : 1)) {
      _currentPage++;
      _reviewsInCurrentPage = 0;
    }

    /// started fetching a page
    _fetchStarted = true;

    /// make sure we have an array to put things in
    List<Data> reviews = _reviews.value;
    if (reviews == null) reviews = [];
    int oldReviewsLength = reviews.where((review) => review != null).length;

    /// if this is still the first page
    if (reviews == null || reviews.isEmpty) {
      /// make sure variables reflects this being the first page
      _currentPage = 0;
      _reviewsInCurrentPage = 0;

      /// network request
      final url = "http://edibly.vassi.li/api/restaurants/$restaurantKey/reviews";
      final response = await http.get(url);
      final allReviews = json.decode(response.body); 
      if (allReviews.length > oldReviewsLength+REVIEWS_PER_PAGE) {
        reviews.insert(oldReviewsLength, allReviews.sublist(oldReviewsLength, oldReviewsLength+REVIEWS_PER_PAGE));
        _reviewsInCurrentPage += REVIEWS_PER_PAGE;
      } else if (allReviews.length > 0){
          var allReviewsSublist = allReviews.sublist(oldReviewsLength, allReviews.length);
//        dishesMap.forEach((d) => dishesWithRating.add(Data(d['did'], d)));
          allReviewsSublist.forEach((r) => reviews.add(Data(r['rrid'], r)));
          reviews.add(null);
      } else {
        return;
      }
      _reviews.add(reviews);
    } else {
      
    }
  }

  /// Dispose function
  void dispose() {
    onChildAddedListener?.cancel();
    _reviews.close();
  }
}
