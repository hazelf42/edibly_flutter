import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

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
  final _addTipState = BehaviorSubject<AddTipState>();
  final _pickedPhoto = BehaviorSubject<File>();
  final _restaurant = BehaviorSubject<Data>();

  /// Stream getters
  Stream<PickedPhotoUploadState> get pickedPhotoUploadState => _pickedPhotoUploadState.stream;

  Stream<AddTipState> get addTipState => _addTipState.stream;

  Stream<File> get pickedPhoto => _pickedPhoto.stream;

  Stream<Data> get restaurant => _restaurant.stream;

  /// Setters
  Function(PickedPhotoUploadState) get setPickedPhotoUploadState => _pickedPhotoUploadState.add;

  Function(AddTipState) get setAddTipState => _addTipState.add;

  Function(File) get setPickedPhoto => _pickedPhoto.add;

  /// Other functions
  void getRestaurant() async {
    _firebaseDatabase.reference().child('restaurants').child(restaurantKey).onValue.listen((event) async {
      if (event?.snapshot?.value != null) {
        try {
          Data restaurantData = Data(event.snapshot.key, event.snapshot.value);
          DataSnapshot ratingSnapshot = await _firebaseDatabase.reference().child('restaurantRatings').child(restaurantKey).once();
          restaurantData.value['rating'] = ratingSnapshot?.value;
          DataSnapshot tipsSnapshot =
              await _firebaseDatabase.reference().child('restaurantTips').child(restaurantKey).orderByKey().limitToLast(1).once();
          restaurantData.value['featured_tip'] = tipsSnapshot?.value;
          _restaurant..add(restaurantData);
        } catch (_) {}
      }
    });
  }

  void addTip({@required String tip}) {
    AddTipState addTipState = _addTipState.value;

    if (addTipState == AddTipState.TRYING) return;
    _addTipState.add(AddTipState.TRYING);

    bool tipIsEmpty = false;

    if (tip == null || tip.isEmpty) {
      _addTipState.addError(AddTipState.EMPTY_TIP);
      tipIsEmpty = true;
    }

    if (!tipIsEmpty) {
      _firebaseDatabase.reference().child('restaurantTips').child(restaurantKey).push().set({
        'tipUserId': firebaseUserId,
        'description': tip,
        'isATest': false,
      }).then((_) {
        _addTipState.add(AddTipState.SUCCESSFUL);
      }).catchError((error) {
        _addTipState.addError(AddTipState.FAILED);
      });
    } else if (tipIsEmpty) {
      _addTipState.addError(AddTipState.EMPTY_TIP);
    }
  }

  void uploadPhoto({@required String restaurantName}) {
    File pickedPhoto = _pickedPhoto.value;
    if (pickedPhoto == null) return;

    PickedPhotoUploadState pickedPhotoUploadState = _pickedPhotoUploadState.value;
    if (pickedPhotoUploadState == PickedPhotoUploadState.TRYING) return;
    _pickedPhotoUploadState.add(PickedPhotoUploadState.TRYING);

    String imageUuid = Uuid().v1();
    StorageReference storageReference = FirebaseStorage.instance.ref();
    storageReference
        .child('restaurants')
        .child(restaurantKey)
        .child('$imageUuid.jpg')
        .putFile(pickedPhoto)
        .onComplete
        .then((storageTaskSnapshot) async {
      String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
      if (downloadUrl == null || downloadUrl.isEmpty) {
        _pickedPhotoUploadState.addError(PickedPhotoUploadState.FAILED);
        return;
      }
      await _firebaseDatabase.reference().child('restaurantImages').child(restaurantKey).push().set({
        'imageUrl': downloadUrl,
        'userId': firebaseUserId,
        'timeStamp': DateTime.now().microsecondsSinceEpoch / 1000,
        'isATest': false,
      });
      DatabaseReference feedPostReference = _firebaseDatabase.reference().child('feedPosts').push();
      await feedPostReference.set({
        'description': null,
        'tagArray': null,
        'otherTags': null,
        'restaurantName': restaurantName,
        'restaurantKey': restaurantKey,
        'numRating': null,
        'imageUrl': downloadUrl,
        'postType': 1,
        'comments': null,
        'reviewingUserId': firebaseUserId,
        'timeStamp': DateTime.now().microsecondsSinceEpoch / 1000,
        'isATest': false,
      });
      await _firebaseDatabase.reference().child('postsByUser').child(firebaseUserId).child(feedPostReference.key).set({
        'description': null,
        'tagArray': null,
        'otherTags': null,
        'restaurantName': restaurantName,
        'restaurantKey': restaurantKey,
        'numRating': null,
        'imageUrl': downloadUrl,
        'postType': 1,
        'comments': null,
        'reviewingUserId': firebaseUserId,
        'timeStamp': DateTime.now().microsecondsSinceEpoch / 1000,
        'isATest': false,
      });
      _pickedPhotoUploadState.add(PickedPhotoUploadState.SUCCESSFUL);
    }).catchError((error) {
      _pickedPhotoUploadState.addError(PickedPhotoUploadState.FAILED);
    });
  }

  Stream<Event> getRestaurantBookmarkValue(String uid, String restaurantKey) {
    return _firebaseDatabase.reference().child('starredRestaurants').child(uid).child(restaurantKey).onValue;
  }

  void setRestaurantBookmarkValue(String uid, String restaurantKey, bool value) {
    _firebaseDatabase.reference().child('starredRestaurants').child(uid).child(restaurantKey).set(value ? 1 : 0);
  }

  /// Dispose function
  void dispose() {
    _pickedPhotoUploadState.close();
    _addTipState.close();
    _pickedPhoto.close();
    _restaurant.close();
  }
}
