import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'package:edibly/models/data.dart';
import 'package:image_picker/image_picker.dart';
import 'package:edibly/values/app_localizations.dart';

class ProfileBloc {
  final String uid;
  AppLocalizations localizations;

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

  Future<bool> isFollowing({@required profileUid, @required currentUid}) async {
    bool a;
    await http
        .get("http://base.edibly.ca/api/profiles/$currentUid/following")
        .then((response) {
      (json.decode(response.body)).forEach((profile) {
        if (profile['uid'] == profileUid) {
          a = true;
          return a;
        }
      });
      if (a != true) {
        a = false;
      }
      ;
    });
    return a;
  }

  Future<bool> followUser(
      {
      //This function also unfollows profiles if the user is already following them because im a lazy goon who doesnt know whats good for me
      @required String currentUid,
      @required String profileUid,
      @required bool isFollowing}) async {
    if (currentUid == uid) {
      print("You can't follow yourself");
      return true;
    }

    {
      if (isFollowing) {
        final body = {'uid': currentUid, 'follow': uid};
        http
            .post("http://base.edibly.ca/api/unfollow", body: json.encode(body))
            .then((http.Response response) {
          final int statusCode = response.statusCode;
          if (statusCode < 200 || statusCode > 400) {
            throw new Exception(
                "Error while sending data" + statusCode.toString());
          }
        });
      } else {
        final body = {'uid': currentUid, 'follow': uid};
        http
            .post("http://base.edibly.ca/api/follow", body: json.encode(body))
            .then((http.Response response) {
          final int statusCode = response.statusCode;
          if (statusCode < 200 || statusCode > 400) {
            throw new Exception(
                "Error while sending data" + statusCode.toString());
          }
        });
      }
    }
  }
  
  Future<String> getImage(FirebaseUser user) async {
    var photo = await ImagePicker.pickImage(source: ImageSource.gallery);

    if (photo != null) {
      
      StorageReference ref =
          FirebaseStorage().ref().child(user.uid).child("profilePicture");
      StorageUploadTask uploadTask = ref.putFile(photo);

      return await uploadTask.onComplete.then((downloadUrl) async {
        return await downloadUrl.ref.getDownloadURL().then((url) async {
          var response = await http.put("http://base.edibly.ca/api/profiles/${user.uid}", body: json.encode(
            {'photo' : url}
          )
        );
        print(response.statusCode);
        UserUpdateInfo updateInfo = UserUpdateInfo();
        updateInfo.photoUrl = url;
        await user.updateProfile(updateInfo);
      });
    });
    }
    return null;
  }
  // return string;

  void getPosts() async {
    List<Data> posts = _posts.value;
    if (posts == null) posts = [];

    await http
        .get('http://base.edibly.ca/api/profiles/${uid}/posts')
        .then((postResponse) {
      json.decode(postResponse.body).forEach((post) {
        posts.add(Data((post['rtid'] ?? post['rrid']).toString(), post));
      });

      _posts.add(posts);
    });
    //   /// if page is not fully loaded the return
    //   // if (_fetchStarted && _postsInCurrentPage < POSTS_PER_PAGE) {
    //   //   return;
    //   // }

    //   // /// if page is fully loaded then staprofrt loading next page
    //   // else if (_postsInCurrentPage ==
    //   //     POSTS_PER_PAGE + (_currentPage == 0 ? 0 : 1)) {
    //   //   _currentPage++;
    //   //   _postsInCurrentPage = 0;
    //   // }

    //   // /// started fetching a page
    //   // onChildAddedListener?.cancel();
    //   // _fetchStarted = true;

    //   /// make sure we have an array to put things in
    //   List<Data> posts = _posts.value;
    //   if (posts == null) posts = [];
    //   int oldPostsLength = posts.where((post) => post != null).length;

    //   /// if this is still the first page
    //   if (posts == null || posts.isEmpty) {
    //     /// make sure variables reflects this being the first page
    //     _currentPage = 0;
    //     _postsInCurrentPage = 0;
    //     print(uid);
    //     /// network request
    //     await http.get("base.edibly.ca/api/profiles/$uid/posts").then((response) {
    //       /// increment number of posts in current page
    //       var snapshot = json.decode(response.body);

    //       /// remove any null values, null values are shown as circular loaders
    //       posts.remove(null);

    //       /// insert newly acquired post to the start of new page
    //       snapshot.forEach((post) {
    //         posts.insert(oldPostsLength, Data(post['rrid'] ?? post['rtid'], post));
    //       });
    /// if this was the last post in requested page, then show a circular loader at the end of page

    /// publish an update to the stream
    //   _posts.add(posts);
    // });
    // query.onValue.listen((event) {
    //   _posts.add(posts);
    //   onChildAddedListener?.cancel();
    // });
    // query.onChildRemoved.listen((event) {
    //   posts.removeWhere(
    //       (post) => post != null && post.key == (event?.snapshot?.key ?? ''));

    // /// publish an update to the stream
    // return posts;

    /// if this is not the first page
    // else {
    //   Query query = _firebaseDatabase
    //       .reference()
    //       .child('postsByUser/$uid')
    //       .orderByKey()
    //       .endAt(posts.lastWhere((post) => post != null).key.toString())
    //       .limitToLast(POSTS_PER_PAGE + 1);
    //   onChildAddedListener = query.onChildAdded.listen((event) {
    //     /// increment number of posts in current page
    //     _postsInCurrentPage++;

    //     /// remove any null values, null values are shown as circular loaders
    //     posts.remove(null);

    //     /// do not insert duplicate posts
    //     if (event?.snapshot?.key != posts[oldPostsLength - 1].key) {
    //       /// insert newly acquired post to the start of new page
    //       posts.insert(oldPostsLength,
    //           Data(event?.snapshot?.key, event?.snapshot?.value));
    //     }

    //     /// if this was the last post in requested page, then show a circular loader at the end of page
    //     if (_postsInCurrentPage == POSTS_PER_PAGE + (_currentPage == 0 ? 0 : 1))
    //       posts.add(null);

    //     /// publish an update to the stream
    //     _posts.add(posts);
    //   });
    //   query.onValue.listen((event) {
    //     _posts.add(posts);
    //     onChildAddedListener?.cancel();
    //   });
    //   query.onChildRemoved.listen((event) {
    //     posts.removeWhere(
    //         (post) => post != null && post.key == (event?.snapshot?.key ?? ''));

    //     /// publish an update to the stream
    //     _posts.add(posts);
    //   });
    // }
  }

//Oh boy I cannot be bothered to integrate this with the backend rn.
//It's firebase time

  //     "POST", Uri.parse("http://base.edibly.ca/api/upload"));
  // request.files.add(http.MultipartFile.fromBytes(
  //     'file', await photo.readAsBytes(),
  //     contentType: MediaType('image', 'jpeg')));
  // return await request.send().then((response) async {
  //   print(response.statusCode);
  //   if (response.statusCode == 200) {
  //     print("OK!");
  //     var bytesToString = await (response.stream.bytesToString());
  //     var newPhotoUrl = (json.decode(bytesToString))['filename'];
  //     UserUpdateInfo info = UserUpdateInfo();
  //     var url = "http://base.edibly.ca/static/uploads/$newPhotoUrl";
  //     info.photoUrl = url;
  //     await user.updateProfile(info);
  //     await http.put("http://base.edibly.ca/api/profiles/$uid",
  //         body: json.encode({'photo': url}));
  //     return url;
  //   } else if (response.statusCode == 413) {
  //     String path;
  //     await FlutterImageCompress.compressAndGetFile(
  //             photo.absolute.path, path,
  //             quality: 88)
  //         .then((file) {
  //       response.stream.bytesToString().then((newPhotoUrl) async {
  //         newPhotoUrl = (json.decode(newPhotoUrl))['filename'];
  //         UserUpdateInfo info;
  //         info.photoUrl = newPhotoUrl;
  //         user.updateProfile(info);
  //         await http.put("http://base.edibly.ca/api/profiles/${uid}",
  //             body: json.encode({
  //               'photo':
  //                   ("http://base.edibly.ca/static/uploads/$newPhotoUrl"),
  //             }));
  //       });
  //     });
  //   }
  // });

  /// Dispose function
  void dispose() {
    onChildAddedListener?.cancel();
    _posts.close();
  }
}
