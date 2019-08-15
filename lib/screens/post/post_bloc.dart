import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'package:edibly/values/app_localizations.dart';

import 'package:edibly/models/data.dart';

class PostBloc {
  Data post;
  
  AppLocalizations localizations;

  PostBloc({@required this.post}) {
    _firebaseDatabase.setPersistenceEnabled(true);
    _firebaseDatabase.setPersistenceCacheSizeBytes(10000000);
  }

  /// Static variables
  static const int COMMENTS_PER_PAGE = 5;

  /// Local  variables
  final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;
  StreamSubscription onChildAddedListener;

  /// Subjects
  final _comments = BehaviorSubject<List<Data>>();

  /// Stream getters
  Stream<List<Data>> get comments => _comments.stream;

  /// Other functions
  void clearComments() {
    _comments.add(null);
  }

   void getComments() async {

     List<Data> comments = _comments.value;
     if (comments == null) comments = [];
        comments = post.value['comments'];
        _comments.add(post.value['comments']);
        
  }

  void addComment(String comment, String uid) async {
    var value = json.encode({
      'comment': comment,
      'uid': uid,
    });
    await http.post("http://base.edibly.ca/api/reviews/${post.key}/comment", body: value).then((http.Response response) { 
      if (response.statusCode < 200 || response.statusCode > 400) {
        SnackBar(content: Text("Your comment could not be posted."));
      } else {
        print("Comment successfully added");
      }
    });
  }

  /// Dispose function
  void dispose() {
    onChildAddedListener?.cancel();
    _comments.close();
  }
}
