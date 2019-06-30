import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
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
      _tipsInCurrentPage = 0; }

      /// network request
      final url = "http://edibly.vassi.li/api/restaurants/$restaurantKey/tips";
      final response = await http.get(url);
      final allTips = json.decode(response.body);
      if (allTips.length > oldTipsLength+TIPS_PER_PAGE) {
        tips.insert(oldTipsLength, allTips.sublist(oldTipsLength, oldTipsLength+TIPS_PER_PAGE));
        _tipsInCurrentPage += TIPS_PER_PAGE;
      } else if (allTips.length > 0) {
        var allTipsSublist = allTips.sublist(oldTipsLength, allTips.length);
        allTipsSublist.forEach((t) => tips.add(Data(t['rtid'], t)));
        tips.add(null);
      } else {
        return;
      }
        _tips.add(tips);
      } 

    /// if this is not the first pagem
  

  /// Dispose function
  void dispose() {
    onChildAddedListener?.cancel();
    _tips.close();
  }
}
