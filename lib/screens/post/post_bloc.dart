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
  //   /// if page is not fully loaded the return
  //   if (_fetchStarted && _commentsInCurrentPage < COMMENTS_PER_PAGE) {
  //     return;
  //   }

  //   /// if page is fully loaded then start loading next page
  //   else if (_commentsInCurrentPage == COMMENTS_PER_PAGE + (_currentPage == 0 ? 0 : 1)) {
  //     _currentPage++;
  //     _commentsInCurrentPage = 0;
  //   }

  //   /// started fetching a page
  //   onChildAddedListener?.cancel();
  //   _fetchStarted = true;

  //   /// make sure we have an array to put things in
     List<Data> comments = _comments.value;
     if (comments == null) comments = [];
  //   int oldCommentsLength = comments.where((comment) => comment != null).length;

  //   /// if this is still the first page
  //   if (comments == null || comments.isEmpty) {
  //     /// make sure variables reflects this being the first page
  //     _currentPage = 0;
  //     _commentsInCurrentPage = 0;

  //     /// network request
      
  //     Query query = _firebaseDatabase.reference().child('comments').child(post.key.toString()).orderByKey().limitToFirst(COMMENTS_PER_PAGE);
  //     onChildAddedListener = query.onChildAdded.listen((event) {
  //       /// increment number of comments in current page
  //       _commentsInCurrentPage++;

  //       /// remove any null values, null values are shown as circular loaders
  //       comments.remove(null);

  //       /// insert newly acquired comment to the start of new page
  //       comments.add(Data(event?.snapshot?.key, event?.snapshot?.value));

  //       /// if this was the last comment in requested page, then show a circular loader at the end of page
  //       if (_commentsInCurrentPage == COMMENTS_PER_PAGE + (_currentPage == 0 ? 0 : 1)) comments.add(null);

  //       /// publish an update to the stream
  //       _comments.add(comments);
  //     });
  //     query.onValue.listen((event) {
  //       _comments.add(comments);
  //       onChildAddedListener?.cancel();
  //     });
  //     query.onChildRemoved.listen((event) {
  //       comments.removeWhere((comment) => comment != null && comment.key == (event?.snapshot?.key ?? ''));

        /// TODO: - stream probably not necessary here
        comments = post.value['comments'];
        _comments.add(post.value['comments']);
    //   });
    // }

    // /// if this is not the first page
    // else {
    //   Query query = _firebaseDatabase
    //       .reference()
    //       .child('comments')
    //       .child(post.key.toString())
    //       .orderByKey()
    //       .startAt(comments.lastWhere((comment) => comment != null).key.toString())
    //       .limitToFirst(COMMENTS_PER_PAGE + 1);
    //   onChildAddedListener = query.onChildAdded.listen((event) {
    //     /// increment number of comments in current page
    //     _commentsInCurrentPage++;

    //     /// remove any null values, null values are shown as circular loaders
    //     comments.remove(null);

    //     /// do not insert duplicate comments
    //     if (event?.snapshot?.key != comments[oldCommentsLength - 1].key) {
    //       /// insert newly acquired comment to the start of new page
    //       comments.add(Data(event?.snapshot?.key, event?.snapshot?.value));
    //     }

    //     /// if this was the last comment in requested page, then show a circular loader at the end of page
    //     if (_commentsInCurrentPage == COMMENTS_PER_PAGE + (_currentPage == 0 ? 0 : 1)) comments.add(null);

    //     /// publish an update to the stream
    //     _comments.add(comments);
    //   });
    //   query.onValue.listen((event) {
    //     _comments.add(comments);
    //     onChildAddedListener?.cancel();
    //   });
    //   query.onChildRemoved.listen((event) {
    //     comments.removeWhere((comment) => comment != null && comment.key == (event?.snapshot?.key ?? ''));

    //     /// publish an update to the stream
    //     _comments.add(comments);
    //   });
    // }
  }

  void addComment(String comment, String uid) async {
    var value = json.encode({
      'comment': comment,
      'uid': uid,
    });
    await http.post("http://edibly.vassi.li/api/reviews/${post.key}/comment", body: value).then((http.Response response) { 
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
