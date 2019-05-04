import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import 'package:edibly/models/data.dart';

class PostBloc {
  Data post;

  PostBloc({@required this.post}) {
    _firebaseDatabase.setPersistenceEnabled(true);
    _firebaseDatabase.setPersistenceCacheSizeBytes(10000000);
  }

  /// Static variables
  static const int COMMENTS_PER_PAGE = 5;

  /// Local  variables
  final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;
  bool _fetchStarted = false;
  int _commentsInCurrentPage = 0;
  int _currentPage = 0;

  /// Subjects
  final _comments = BehaviorSubject<List<Data>>();

  /// Stream getters
  Stream<List<Data>> get comments => _comments.stream;

  /// Other functions
  void clearComments() {
    _comments.add(null);
    _fetchStarted = false;
    _commentsInCurrentPage = 0;
    _currentPage = 0;
  }

  void getComments() async {
    /// if page is not fully loaded the return
    if (_fetchStarted && _commentsInCurrentPage < COMMENTS_PER_PAGE) {
      return;
    }

    /// if page is fully loaded then start loading next page
    else if (_commentsInCurrentPage == COMMENTS_PER_PAGE + (_currentPage == 0 ? 0 : 1)) {
      _currentPage++;
      _commentsInCurrentPage = 0;
    }

    /// started fetching a page
    _fetchStarted = true;

    /// make sure we have an array to put things in
    List<Data> comments = _comments.value;
    if (comments == null) comments = [];

    /// if this is still the first page
    if (comments == null || comments.isEmpty) {
      /// make sure variables reflects this being the first page
      _currentPage = 0;
      _commentsInCurrentPage = 0;

      /// network request
      Query query = _firebaseDatabase.reference().child('comments').child(post.key.toString()).orderByKey().limitToFirst(COMMENTS_PER_PAGE);
      query.onChildAdded.listen((event) {
        /// increment number of comments in current page
        _commentsInCurrentPage++;

        /// remove any null values, null values are shown as circular loaders
        comments.remove(null);

        /// insert newly acquired comment to the start of new page
        comments.add(Data(event?.snapshot?.key, event?.snapshot?.value));

        /// if this was the last comment in requested page, then show a circular loader at the end of page
        if (_commentsInCurrentPage == COMMENTS_PER_PAGE + (_currentPage == 0 ? 0 : 1)) comments.add(null);

        /// publish an update to the stream
        _comments.add(comments);
      });
      query.onValue.listen((event) {
        _comments.add(comments);
      });
    }

    /// if this is not the first page
    else {
      Query query = _firebaseDatabase
          .reference()
          .child('comments')
          .child(post.key.toString())
          .orderByKey()
          .startAt(comments.lastWhere((comment) => comment != null).key.toString())
          .limitToFirst(COMMENTS_PER_PAGE + 1);
      query.onChildAdded.listen((event) {
        /// increment number of comments in current page
        _commentsInCurrentPage++;

        /// remove any null values, null values are shown as circular loaders
        comments.remove(null);

        /// do not insert duplicate comments
        if (event?.snapshot?.key != comments[_currentPage * COMMENTS_PER_PAGE - 1].key) {
          /// insert newly acquired comment to the start of new page
          comments.add(Data(event?.snapshot?.key, event?.snapshot?.value));
        }

        /// if this was the last comment in requested page, then show a circular loader at the end of page
        if (_commentsInCurrentPage == COMMENTS_PER_PAGE + (_currentPage == 0 ? 0 : 1)) comments.add(null);

        /// publish an update to the stream
        _comments.add(comments);
      });
      query.onValue.listen((event) {
        _comments.add(comments);
      });
    }
  }

  void addComment(String comment, String uid) {
    _firebaseDatabase.reference().child('comments').child(post.key).push().set({
      'timeStamp': DateTime.now().microsecondsSinceEpoch / 1000,
      'postId': post.key,
      'commentText': comment,
      'userId': uid,
    });
  }

  /// Dispose function
  void dispose() {
    _comments.close();
  }
}
