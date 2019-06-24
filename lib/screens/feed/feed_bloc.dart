import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
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
      final response = await http.get('http://edibly.vassi.li/api/posts');

      final map = json.decode(response.body);
      final postsMap = Map<dynamic, dynamic>();
      map.forEach((p) => postsMap[p['rrid'].toString()] = p);
      var index = 0;
      for (var post in map) {
        final nameResponse = await http.get('http://edibly.vassi.li/api/restaurants/'+post['rid'].toString());
        final name = json.decode(nameResponse.body)['name'];
        post['restaurantName'] = name;
        posts.add(Data(index, post));
      }
      
      print(posts);
      _postsInCurrentPage += 10;
      posts.remove(null);
      _posts.add(posts);
      print(_posts);

      // Query query = _firebaseDatabase.reference().child('feedPosts').orderByKey().limitToLast(POSTS_PER_PAGE);
      // onChildAddedListener = query.onChildAdded.listen((event) {
      //   /// increment number of posts in current page
      //   _postsInCurrentPage++;

      //   /// remove any null values, null values are shown as circular loaders
      //   posts.remove(null);
      //   print(posts);

      //   /// insert newly acquired post to the start of new page
      //   posts.insert(oldPostsLength, Data(event?.snapshot?.key, event?.snapshot?.value));

      //   /// if this was the last post in requested page, then show a circular loader at the end of page
      //   if (_postsInCurrentPage == POSTS_PER_PAGE + (_currentPage == 0 ? 0 : 1)) posts.add(null);

      //   /// publish an update to the stream
      //   _posts.add(posts);
      // });
      // query.onValue.listen((_) {
      //   onChildAddedListener?.cancel();
      // });
      // query.onChildRemoved.listen((event) {
      //   posts.removeWhere((post) => post != null && post.key == (event?.snapshot?.key ?? ''));

      //   /// publish an update to the stream
      //   _posts.add(posts);
      //   print("Posts!");
        
      //   print(_posts);
      // });
    }

    /// if this is not the first page
    else {
      Query query = _firebaseDatabase
          .reference()
          .child('feedPosts')
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
          posts.insert(oldPostsLength, Data(event?.snapshot?.key, event?.snapshot?.value));
        }

        /// if this was the last post in requested page, then show a circular loader at the end of page
        if (_postsInCurrentPage == POSTS_PER_PAGE + (_currentPage == 0 ? 0 : 1)) posts.add(null);

        /// publish an update to the stream
        _posts.add(posts);
        print(_posts);
      });
      query.onValue.listen((_) {
        onChildAddedListener?.cancel();
      });
      query.onChildRemoved.listen((event) {
        posts.removeWhere((post) => post != null && post.key == (event?.snapshot?.key ?? ''));

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
