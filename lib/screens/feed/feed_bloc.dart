import 'package:firebase_database/firebase_database.dart';
import 'package:rxdart/rxdart.dart';

import 'package:edibly/models/data.dart';

class FeedBloc {
  FeedBloc() {
    _firebaseDatabase.setPersistenceEnabled(true);
    _firebaseDatabase.setPersistenceCacheSizeBytes(10000000);
  }

  /// Static variables
  static const int POSTS_PER_PAGE = 5;

  /// Local  variables
  final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;
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

  void getPosts() async {
    /// if page is not fully loaded the return
    if (_fetchStarted && _postsInCurrentPage < POSTS_PER_PAGE) {
      return;
    }

    /// if page is fully loaded then start loading next page
    else if (_postsInCurrentPage == POSTS_PER_PAGE + (_currentPage == 0 ? 0 : 1)) {
      _currentPage++;
      _postsInCurrentPage = 0;
    }

    /// started fetching a page
    _fetchStarted = true;

    /// make sure we have an array to put things in
    List<Data> posts = _posts.value;
    if (posts == null) posts = [];

    /// if this is still the first page
    if (posts == null || posts.isEmpty) {
      /// make sure variables reflects this being the first page
      _currentPage = 0;
      _postsInCurrentPage = 0;

      /// network request
      _firebaseDatabase.reference().child('feedPosts').orderByKey().limitToLast(POSTS_PER_PAGE).onChildAdded.listen((event) {
        /// increment number of posts in current page
        _postsInCurrentPage++;

        /// remove any null values, null values are shown as circular loaders
        posts.remove(null);

        /// insert newly acquired post to the start of new page
        posts.insert(_currentPage * POSTS_PER_PAGE, Data(event?.snapshot?.key, event?.snapshot?.value));

        /// if this was the last post in requested page, then show a circular loader at the end of page
        if (_postsInCurrentPage == POSTS_PER_PAGE + (_currentPage == 0 ? 0 : 1)) posts.add(null);

        /// publish an update to the stream
        _posts.add(posts);
      });
    }

    /// if this is not the first page
    else {
      _firebaseDatabase
          .reference()
          .child('feedPosts')
          .orderByKey()
          .endAt(posts.lastWhere((post) => post != null).key.toString())
          .limitToLast(POSTS_PER_PAGE + 1)
          .onChildAdded
          .listen((event) {
        /// increment number of posts in current page
        _postsInCurrentPage++;

        /// remove any null values, null values are shown as circular loaders
        posts.remove(null);

        /// do not insert duplicate posts
        if (event?.snapshot?.key != posts[_currentPage * POSTS_PER_PAGE - 1].key) {
          /// insert newly acquired post to the start of new page
          posts.insert(_currentPage * POSTS_PER_PAGE, Data(event?.snapshot?.key, event?.snapshot?.value));
        }

        /// if this was the last post in requested page, then show a circular loader at the end of page
        if (_postsInCurrentPage == POSTS_PER_PAGE + (_currentPage == 0 ? 0 : 1)) posts.add(null);

        /// publish an update to the stream
        _posts.add(posts);
      });
    }
  }

  /// Dispose function
  void dispose() {
    _posts.close();
  }
}
