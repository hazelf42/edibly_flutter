import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

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
    /// if page is not fully loaded the return
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

    /// if this is still the first page
    if (reviews == null || reviews.isEmpty) {
      /// make sure variables reflects this being the first page
      _currentPage = 0;
      _reviewsInCurrentPage = 0;

      /// network request
      Query query = _firebaseDatabase.reference().child('reviews').child(restaurantKey).orderByKey().limitToLast(REVIEWS_PER_PAGE);
      query.onChildAdded.listen((event) async {
        /// increment number of reviews in current page
        _reviewsInCurrentPage++;

        /// remove any null values, null values are shown as circular loaders
        reviews.remove(null);

        DataSnapshot dataSnapshot = await _firebaseDatabase.reference().child('feedPosts').child(event?.snapshot?.key).once();

        /// insert newly acquired review to the start of new page
        reviews.insert(_currentPage * REVIEWS_PER_PAGE, Data(dataSnapshot?.key, dataSnapshot?.value));

        /// if this was the last review in requested page, then show a circular loader at the end of page
        if (_reviewsInCurrentPage == REVIEWS_PER_PAGE + (_currentPage == 0 ? 0 : 1)) reviews.add(null);

        /// publish an update to the stream
        _reviews.add(reviews);
      });
      query.onValue.listen((event) {
        _reviews.add(reviews);
      });
    }

    /// if this is not the first page
    else {
      Query query = _firebaseDatabase
          .reference()
          .child('reviews')
          .child(restaurantKey)
          .orderByKey()
          .endAt(reviews.lastWhere((review) => review != null).key.toString())
          .limitToLast(REVIEWS_PER_PAGE + 1);
      query.onChildAdded.listen((event) async {
        /// increment number of reviews in current page
        _reviewsInCurrentPage++;

        /// remove any null values, null values are shown as circular loaders
        reviews.remove(null);

        /// do not insert duplicate reviews
        if (event?.snapshot?.key != reviews[_currentPage * REVIEWS_PER_PAGE - 1].key) {
          DataSnapshot dataSnapshot = await _firebaseDatabase.reference().child('feedPosts').child(event?.snapshot?.key).once();

          /// insert newly acquired review to the start of new page
          reviews.insert(_currentPage * REVIEWS_PER_PAGE, Data(dataSnapshot?.key, dataSnapshot?.value));
        }

        /// if this was the last review in requested page, then show a circular loader at the end of page
        if (_reviewsInCurrentPage == REVIEWS_PER_PAGE + (_currentPage == 0 ? 0 : 1)) reviews.add(null);

        /// publish an update to the stream
        _reviews.add(reviews);
      });
      query.onValue.listen((event) {
        _reviews.add(reviews);
      });
    }
  }

  /// Dispose function
  void dispose() {
    _reviews.close();
  }
}
