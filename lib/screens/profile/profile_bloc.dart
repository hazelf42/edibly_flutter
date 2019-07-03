import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'package:edibly/main_bloc.dart';
import 'package:edibly/models/data.dart';

class ProfileBloc {
  final String uid;

  ProfileBloc({@required this.uid}) {
    _firebaseDatabase.setPersistenceEnabled(true);
    _firebaseDatabase.setPersistenceCacheSizeBytes(10000000);
  }

  /// Static variables
  static const int POSTS_PER_PAGE = 5;

  /// Local  variables
  final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;
  StreamSubscription onChildAddedListener;
  bool _fetchStarted = false;
  int _postsInCurrentPage = 0;
  int _currentPage = 0;

  /// Subjects
  final _posts = BehaviorSubject<List<Data>>();

  /// Stream getters
  Stream<List<Data>> get posts => _posts.stream;

  /// Other functions
  void clearPosts() {
    _posts.add([]);
    _fetchStarted = false;
    _postsInCurrentPage = 0;
    _currentPage = 0;
  }

  void followUser() async {
    final currentUser = await MainBloc().getCurrentFirebaseUser();
    final currentUid = currentUser.uid;
    if (currentUid == uid) {
      print("You can't follow yourself");
      return;
    }
    if (currentUid != null) {
      final body = {'uid': currentUid, 'follow': uid};
      //TODO: - why dont this work
      http.post("http://edibly.vassi.li/api/follow",
          body: json.encode(body),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
          }).then((http.Response response) {
        final int statusCode = response.statusCode;

        if (statusCode < 200 || statusCode > 400) {
          throw new Exception(
              "Error while sending data" + statusCode.toString());
        }
      });
    }
  }

  void getPosts() async {
    /// if page is not fully loaded the return
    if (_fetchStarted && _postsInCurrentPage < POSTS_PER_PAGE) {
      return;
    }

    /// if page is fully loaded then start loading next page
    else if (_postsInCurrentPage ==
        POSTS_PER_PAGE + (_currentPage == 0 ? 0 : 1)) {
      _currentPage++;
      _postsInCurrentPage = 0;
    }

    /// started fetching a page
    onChildAddedListener?.cancel();
    _fetchStarted = true;

    /// make sure we have an array to put things in
    List<Data> posts = _posts.value;
    if (posts == null) posts = [];
    int oldPostsLength = posts.where((post) => post != null).length;

    /// if this is still the first page
    if (posts == null || posts.isEmpty) {
      /// make sure variables reflects this being the first page
      _currentPage = 0;
      _postsInCurrentPage = 0;

      /// network request
      Query query = _firebaseDatabase
          .reference()
          .child('postsByUser/$uid')
          .orderByKey()
          .limitToLast(POSTS_PER_PAGE);
      onChildAddedListener = query.onChildAdded.listen((event) {
        /// increment number of posts in current page
        _postsInCurrentPage++;

        /// remove any null values, null values are shown as circular loaders
        posts.remove(null);

        /// insert newly acquired post to the start of new page
        posts.insert(
            oldPostsLength, Data(event?.snapshot?.key, event?.snapshot?.value));

        /// if this was the last post in requested page, then show a circular loader at the end of page
        if (_postsInCurrentPage == POSTS_PER_PAGE + (_currentPage == 0 ? 0 : 1))
          posts.add(null);

        /// publish an update to the stream
        _posts.add(posts);
      });
      query.onValue.listen((event) {
        _posts.add(posts);
        onChildAddedListener?.cancel();
      });
      query.onChildRemoved.listen((event) {
        posts.removeWhere(
            (post) => post != null && post.key == (event?.snapshot?.key ?? ''));

        /// publish an update to the stream
        _posts.add(posts);
      });
    }

    /// if this is not the first page
    else {
      Query query = _firebaseDatabase
          .reference()
          .child('postsByUser/$uid')
          .orderByKey()
          .endAt(posts.lastWhere((post) => post != null).key.toString())
          .limitToLast(POSTS_PER_PAGE + 1);
      onChildAddedListener = query.onChildAdded.listen((event) {
        /// increment number of posts in current page
        _postsInCurrentPage++;

        /// remove any null values, null values are shown as circular loaders
        posts.remove(null);

        /// do not insert duplicate posts
        if (event?.snapshot?.key != posts[oldPostsLength - 1].key) {
          /// insert newly acquired post to the start of new page
          posts.insert(oldPostsLength,
              Data(event?.snapshot?.key, event?.snapshot?.value));
        }

        /// if this was the last post in requested page, then show a circular loader at the end of page
        if (_postsInCurrentPage == POSTS_PER_PAGE + (_currentPage == 0 ? 0 : 1))
          posts.add(null);

        /// publish an update to the stream
        _posts.add(posts);
      });
      query.onValue.listen((event) {
        _posts.add(posts);
        onChildAddedListener?.cancel();
      });
      query.onChildRemoved.listen((event) {
        posts.removeWhere(
            (post) => post != null && post.key == (event?.snapshot?.key ?? ''));

        /// publish an update to the stream
        _posts.add(posts);
      });
    }
  }

  /// Dispose function
  void dispose() {
    onChildAddedListener?.cancel();
    _posts.close();
  }
}
