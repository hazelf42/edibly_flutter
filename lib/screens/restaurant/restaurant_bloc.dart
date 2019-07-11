import 'dart:io';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:edibly/models/data.dart';

enum PickedPhotoUploadState {
  SUCCESSFUL,
  FAILED,
  TRYING,
  IDLE,
}

enum AddTipState {
  EMPTY_TIP,
  SUCCESSFUL,
  FAILED,
  TRYING,
  IDLE,
}

class RestaurantBloc {
  final String firebaseUserId;
  final String restaurantKey;

  RestaurantBloc({
    @required this.firebaseUserId,
    @required this.restaurantKey,
  }) {
    _firebaseDatabase.setPersistenceEnabled(true);
    _firebaseDatabase.setPersistenceCacheSizeBytes(10000000);
  }

  /// Local  variables
  final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;

  /// Subjects
  final _pickedPhotoUploadState = BehaviorSubject<PickedPhotoUploadState>();
  final _lastThreePhotos = BehaviorSubject<List<Data>>();
  final _addTipState = BehaviorSubject<AddTipState>();
  final _pickedPhoto = BehaviorSubject<File>();
  final _restaurant = BehaviorSubject<Data>();
  final _rating = BehaviorSubject<Data>();

  /// Stream getters
  Stream<PickedPhotoUploadState> get pickedPhotoUploadState =>
      _pickedPhotoUploadState.stream;

  Stream<List<Data>> get lastThreePhotos => _lastThreePhotos.stream;

  Stream<AddTipState> get addTipState => _addTipState.stream;

  Stream<File> get pickedPhoto => _pickedPhoto.stream;

  Stream<Data> get restaurant => _restaurant.stream;

  Stream<Data> get rating => _rating.stream;

  /// Setters
  Function(PickedPhotoUploadState) get setPickedPhotoUploadState =>
      _pickedPhotoUploadState.add;

  Function(AddTipState) get setAddTipState => _addTipState.add;

  Function(File) get setPickedPhoto => _pickedPhoto.add;

  /// Other functions
  void getRestaurant() async {
    _restaurant.add(null);
    final url = 'http://edibly.vassi.li/api/restaurants/' + restaurantKey;
    final response = await http.get(url);
    final map = json.decode(response.body);
    Data restaurantData = Data(map['rid'], map);
    _restaurant.add(restaurantData);
    var featuredTip = [];
    final tipsResponse = await http.get(
        'http://edibly.vassi.li/api/restaurants/' + restaurantKey + '/tips');
    final tipsMap = json.decode(tipsResponse.body);
    print(tipsMap);
    tipsMap.forEach((t) => t['featured'] == 1 ? featuredTip.add(t) : null);
    if (featuredTip.length == 0 && tipsMap.length != 0) {
      featuredTip.add(tipsMap[0]);
      restaurantData.value['featured_tip'] = featuredTip[0];
      print(restaurantData.value);
    }
    _restaurant.add(restaurantData);

    //final tipsResponse = await http.get('http://edibly.vassi.li/api/restaurants/'+restaurantKey+'/tips');
    //final tipsMap = json.decode(tipsResponse.body);
    //   _firebaseDatabase.reference().child('restaurants').child(restaurantKey).onValue.listen((event) async {
    //   if (event?.snapshot?.value != null) {
    //       Data restaurantData = Data(event.snapshot.key, event.snapshot.value);
    //       Query tipsQuery = _firebaseDatabase.reference().child('restaurantTips').child(restaurantKey).orderByKey().limitToLast(1);
    //       tipsQuery.onChildAdded.listen((event) {
    //     try {
    //         DataSnapshot tipsSnapshot = event?.snapshot;
    //         restaurantData.value['featured_tip'] = tipsSnapshot?.value;
    //       });
    //       tipsQuery.onValue.listen((_) async {
    //         _restaurant..add(restaurantData);
    //       });
    //     } catch (_) {}
    //   }
    // });
    // }
  }

  void addTip({@required String tip, @required String restaurantName}) {
    AddTipState addTipState = _addTipState.value;

    if (addTipState == AddTipState.TRYING) return;
    _addTipState.add(AddTipState.TRYING);

    bool tipIsEmpty = false;

    if (tip == null || tip.isEmpty) {
      _addTipState.addError(AddTipState.EMPTY_TIP);
      tipIsEmpty = true;
    }

    if (!tipIsEmpty) {
      final tipBody = {
        'text': tip,
        'uid': firebaseUserId,
        'rid': restaurantKey
      };

      http
          .post("http://edibly.vassi.li/api/tips/add",
              body: json.encode(tipBody))
          .then((http.Response response) {
        final int statusCode = response.statusCode;
        _addTipState.add(AddTipState.SUCCESSFUL);

        if (statusCode < 200 || statusCode > 400 || tipBody == null) {
          _addTipState.addError(AddTipState.FAILED);

          throw new Exception(
              "Error while fetching data" + statusCode.toString());
        }
      });
    } else if (tipIsEmpty) {
      _addTipState.addError(AddTipState.EMPTY_TIP);
    }
    // }

    // DatabaseReference feedPostReference = _firebaseDatabase.reference().child('feedPosts').push();
    // feedPostReference.set({
    //   'description': tip,
    //   'tagArray': null,
    //   'otherTags': null,
    //   'restaurantName': restaurantName,
    //   'restaurantKey': restaurantKey,
    //   'numRating': null,
    //   'imageUrl': null,
    //   'postType': 2,
    //   'comments': null,
    //   'reviewingUserId': firebaseUserId,
    //   'timeStamp': DateTime.now().microsecondsSinceEpoch / 1000000,
    //   'isATest': false,
    // }).then((_) async {
    //   await _firebaseDatabase.reference().child('restaurantTips').child(restaurantKey).child(feedPostReference.key).set({
    //     'tipUserId': firebaseUserId,
    //     'description': tip,
    //     'isATest': false,
    //   });
    //   await _firebaseDatabase.reference().child('postsByUser').child(firebaseUserId).child(feedPostReference.key).set({
    //     'description': tip,
    //     'tagArray': null,
    //     'otherTags': null,
    //     'restaurantName': restaurantName,
    //     'restaurantKey': restaurantKey,
    //     'numRating': null,
    //     'imageUrl': null,
    //     'postType': 2,
    //     'comments': null,
    //     'reviewingUserId': firebaseUserId,
    //     'timeStamp': DateTime.now().microsecondsSinceEpoch / 1000000,
    //     'isATest': false,
    //   });
    //   _addTipState.add(AddTipState.SUCCESSFUL);
    // }).catchError((error) {
    //   _addTipState.addError(AddTipState.FAILED);
    // });
  }

  Future<bool> submitPhoto({@required String restaurantName}) async {
    PickedPhotoUploadState pickedPhotoUploadState =
        _pickedPhotoUploadState.value;
    if (pickedPhotoUploadState == PickedPhotoUploadState.TRYING) return false;
    _pickedPhotoUploadState.add(PickedPhotoUploadState.TRYING);

        await getImageUrl(photo: _pickedPhoto.value).then((fileName) {
       var imageUrl = "http://edibly.vassi.li/static/uploads/" +
            json.decode(fileName)['filename'];
      var reviewBody = {
        'uid': firebaseUserId,
        'rid': restaurantKey,
        'postType': 0,
        'photo': imageUrl
      };

      http
          .post("http://edibly.vassi.li/api/reviews/add",
              body: json.encode(reviewBody))
          .then((http.Response response) {
        final int statusCode = response.statusCode;

        if (statusCode < 200 || statusCode > 400 || reviewBody == null) {
          _pickedPhotoUploadState.add(PickedPhotoUploadState.FAILED);
        }
        _pickedPhotoUploadState.add(PickedPhotoUploadState.SUCCESSFUL);
      });
      return true;
    });
  }

  Future<String> getImageUrl({
    @required File photo,
  }) async {
    /// upload photo
    Future<String> photoUrl;
    if (photo != null) {
      var request = http.MultipartRequest(
          "POST", Uri.parse("http://edibly.vassi.li/api/upload"));
      request.files.add(http.MultipartFile.fromBytes(
          'file', await photo.readAsBytes(),
          contentType: MediaType('image', 'jpeg')));
      await request.send().then((response) {
        if (response.statusCode == 200) {
          photoUrl = response.stream.bytesToString();
        } else {
          SnackBar(content: Text("An error occurred."));
        }
      });
    }
    return photoUrl;
  }

  Future<Stream<Event>> getRestaurantBookmarkValue(
      String uid, String restaurantKey) async {
    final url =
        'http://edibly.vassi.li/api/profiles/' + uid + "/" + restaurantKey;
    final response = await http.get(url);
    return json.decode(response.body);
  }

  void getLastThreeRestaurantPhotos() async {
    final url =
        'http://edibly.vassi.li/api/restaurants/' + restaurantKey + '/pictures';
    final response = await http.get(url);
    List<Data> photos = [];
    final imagesMap = json.decode(response.body);
    var i = 0;
    imagesMap.asMap().forEach((index, r) => photos.add(Data(index, r)));
    //photos = (photos.reversed); photos = photos.sublist(0,3);
    if (photos.length > 3) {
      photos = photos.sublist(0, 3);
    }
    _lastThreePhotos.add(photos);
  }

  void getRating() async {
    // _firebaseDatabase.reference().child('restaurantRatings').child(restaurantKey).onValue.listen((event) {
    //   if (event?.snapshot?.key != null && event?.snapshot?.value != null) {
    //     _rating.add(Data(event.snapshot.key, event.snapshot.value));
    //   }
    // });
  }

  void setRestaurantBookmarkValue(
      String uid, String restaurantKey, bool value) {
    // _firebaseDatabase.reference().child('starredRestaurants').child(uid).child(restaurantKey).set(value ? 1 : 0);
  }

  /// Dispose function
  void dispose() {
    _pickedPhotoUploadState.close();
    _lastThreePhotos.close();
    _addTipState.close();
    _pickedPhoto.close();
    _restaurant.close();
    _rating.close();
  }
}
