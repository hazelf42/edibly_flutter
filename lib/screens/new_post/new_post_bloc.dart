import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

class NewPostBloc {
  String restaurantKey;

  NewPostBloc({@required this.restaurantKey}) {
    _firebaseDatabase.setPersistenceEnabled(true);
    _firebaseDatabase.setPersistenceCacheSizeBytes(10000000);
  }

  /// Local  variables
  final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;

  /// Subjects
  final _rating = BehaviorSubject<double>();
  final _photo = BehaviorSubject<File>();
  final _tags = BehaviorSubject<List<String>>();

  /// Stream getters
  Stream<double> get rating => _rating.stream;

  Stream<File> get photo => _photo.stream;

  Stream<List<String>> get tags => _tags.stream;

  /// Stream adders
  Function(double) get setRating => _rating.add;

  Function(File) get setPhoto => _photo.add;

  /// Value getters
  List<String> tagsValue() {
    return _tags.value ?? [];
  }

  File photoValue() {
    return _photo.value;
  }

  /// Manipulate
  void addTag(String tag) {
    List<String> tags = _tags.value ?? [];
    if (tags.length < 3) {
      tags.add(tag);
      _tags.add(tags);
    }
  }

  void removeTag(String tag) {
    List<String> tags = _tags.value ?? [];
    tags.remove(tag);
    _tags.add(tags);
  }

  /// Dispose function
  void dispose() {
    _rating.close();
    _photo.close();
    _tags.close();
  }
}
