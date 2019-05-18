import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import 'package:edibly/models/data.dart';

class RestaurantTipsBloc {
  final String restaurantKey;

  RestaurantTipsBloc({@required this.restaurantKey}) {
    _firebaseDatabase.setPersistenceEnabled(true);
    _firebaseDatabase.setPersistenceCacheSizeBytes(10000000);
  }

  /// Static variables
  static const int TIPS_PER_PAGE = 5;

  /// Local  variables
  final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;
  StreamSubscription onChildAddedListener;
  bool _fetchStarted = false;
  int _tipsInCurrentPage = 0;
  int _currentPage = 0;

  /// Subjects
  final _tips = BehaviorSubject<List<Data>>();

  /// Stream getters
  Stream<List<Data>> get tips => _tips.stream;

  /// Other functions
  void clearTips() {
    _tips.add([]);
    _fetchStarted = false;
    _tipsInCurrentPage = 0;
    _currentPage = 0;
  }

  void getTips() async {
    /// if page is not fully loaded the return
    if (_fetchStarted && _tipsInCurrentPage < TIPS_PER_PAGE) {
      return;
    }

    /// if page is fully loaded then start loading next page
    else if (_tipsInCurrentPage == TIPS_PER_PAGE + (_currentPage == 0 ? 0 : 1)) {
      _currentPage++;
      _tipsInCurrentPage = 0;
    }

    /// started fetching a page
    onChildAddedListener?.cancel();
    _fetchStarted = true;

    /// make sure we have an array to put things in
    List<Data> tips = _tips.value;
    if (tips == null) tips = [];
    int oldTipsLength = tips.where((tip) => tip != null).length;

    /// if this is still the first page
    if (tips == null || tips.isEmpty) {
      /// make sure variables reflects this being the first page
      _currentPage = 0;
      _tipsInCurrentPage = 0;

      /// network request
      Query query = _firebaseDatabase.reference().child('restaurantTips').child(restaurantKey).orderByKey().limitToLast(TIPS_PER_PAGE);
      onChildAddedListener = query.onChildAdded.listen((event) async {
        /// increment number of tips in current page
        _tipsInCurrentPage++;

        /// remove any null values, null values are shown as circular loaders
        tips.remove(null);

        /// insert newly acquired tip to the start of new page
        tips.insert(oldTipsLength, Data(event?.snapshot?.key, event?.snapshot?.value));

        /// if this was the last tip in requested page, then show a circular loader at the end of page
        if (_tipsInCurrentPage == TIPS_PER_PAGE + (_currentPage == 0 ? 0 : 1)) tips.add(null);

        /// publish an update to the stream
        _tips.add(tips);
      });
      query.onValue.listen((event) {
        _tips.add(tips);
        onChildAddedListener?.cancel();
      });
      query.onChildRemoved.listen((event) {
        tips.removeWhere((tip) => tip != null && tip.key == (event?.snapshot?.key ?? ''));

        /// publish an update to the stream
        _tips.add(tips);
      });
    }

    /// if this is not the first page
    else {
      Query query = _firebaseDatabase
          .reference()
          .child('restaurantTips')
          .child(restaurantKey)
          .orderByKey()
          .endAt(tips.lastWhere((tip) => tip != null).key.toString())
          .limitToLast(TIPS_PER_PAGE + 1);
      onChildAddedListener = query.onChildAdded.listen((event) async {
        /// increment number of tips in current page
        _tipsInCurrentPage++;

        /// remove any null values, null values are shown as circular loaders
        tips.remove(null);

        /// do not insert duplicate tips
        if (event?.snapshot?.key != tips[oldTipsLength - 1].key) {
          /// insert newly acquired tip to the start of new page
          tips.insert(oldTipsLength, Data(event?.snapshot?.key, event?.snapshot?.value));
        }

        /// if this was the last tip in requested page, then show a circular loader at the end of page
        if (_tipsInCurrentPage == TIPS_PER_PAGE + (_currentPage == 0 ? 0 : 1)) tips.add(null);

        /// publish an update to the stream
        _tips.add(tips);
      });
      query.onValue.listen((event) {
        _tips.add(tips);
        onChildAddedListener?.cancel();
      });
      query.onChildRemoved.listen((event) {
        tips.removeWhere((tip) => tip != null && tip.key == (event?.snapshot?.key ?? ''));

        /// publish an update to the stream
        _tips.add(tips);
      });
    }
  }

  /// Dispose function
  void dispose() {
    onChildAddedListener?.cancel();
    _tips.close();
  }
}
