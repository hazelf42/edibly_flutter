import 'dart:io';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:edibly/models/data.dart';
import 'package:edibly/values/app_localizations.dart';

class NewPostBloc {
  String firebaseUserId;
  String restaurantKey;
  AppLocalizations localizations;

  NewPostBloc({
    @required this.firebaseUserId,
    @required this.restaurantKey,
  }) {
    _firebaseDatabase.setPersistenceEnabled(true);
    _firebaseDatabase.setPersistenceCacheSizeBytes(10000000);
  }

  /// Local  variables
  final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;

  /// Subjects
  final _dislikedDishes = BehaviorSubject<List<Data>>();
  final _likedDishes = BehaviorSubject<List<Data>>();
  final _dishes = BehaviorSubject<List<Data>>();
  final _rating = BehaviorSubject<double>();
  final _photo = BehaviorSubject<File>();
  final _tags = BehaviorSubject<List<Data>>();
  int _addedDishesCounter = 0;

  /// Stream getters
  Stream<List<Data>> get dislikedDishes => _dislikedDishes.stream;

  Stream<List<Data>> get likedDishes => _likedDishes.stream;

  Stream<List<Data>> get dishes => _dishes.stream;

  Stream<double> get rating => _rating.stream;

  Stream<File> get photo => _photo.stream;

  Stream<List<Data>> get tags => _tags.stream;

  /// Stream adders
  Function(List<Data>) get setDishes => _dishes.add;

  Function(double) get setRating => _rating.add;

  Function(File) get setPhoto => _photo.add;

  /// Value getters
  List<Data> tagsValue() {
    return _tags.value ?? [];
  }

  File photoValue() {
    return _photo.value;
  }

  /// Manipulate
  void addTag(String tagKey, [bool selected = true]) {
    List<Data> tags = _tags.value ?? [];
    if (!selected || tags.where((tag) => tag.value == true).length < 3) {
      tags.removeWhere((tag) => tag.key == tagKey);
      tags.add(Data(tagKey, selected));
      tags.sort((a, b) => (a.key as String)
          .toLowerCase()
          .compareTo((b.key as String).toLowerCase()));
      _tags.add(tags);
    }
  }

  void addTags(List<String> tags) {
    tags.forEach((tag) => addTag(tag, false));
  }

  void removeTag(String tagKey) {
    addTag(tagKey, false);
  }

  void resetDish(Data dish) {
    /// remove from liked dishes list
    List<Data> likedDishes = _likedDishes.value ?? [];
    if (likedDishes.where((d) => d.key == dish.key).isNotEmpty) {
      likedDishes.removeWhere((d) => d.key == dish.key);
      _likedDishes.add(likedDishes);
    }

    /// remove from disliked dishes list
    List<Data> dislikedDishes = _dislikedDishes.value ?? [];
    if (dislikedDishes.where((d) => d.key == dish.key).isNotEmpty) {
      dislikedDishes.removeWhere((d) => d.key == dish.key);
      _dislikedDishes.add(dislikedDishes);
    }
  }

  void likeDish(Data dish) {
    List<Data> likedDishes = _likedDishes.value ?? [];
    if (likedDishes.where((d) => d.key == dish.key).isEmpty) {
      likedDishes.add(dish);
      _likedDishes.add(likedDishes);
    }

    /// remove from disliked dishes list
    List<Data> dislikedDishes = _dislikedDishes.value ?? [];
    if (dislikedDishes.where((d) => d.key == dish.key).isNotEmpty) {
      dislikedDishes.removeWhere((d) => d.key == dish.key);
      _dislikedDishes.add(dislikedDishes);
    }
  }

  void dislikeDish(Data dish) {
    List<Data> dislikedDishes = _dislikedDishes.value ?? [];
    if (dislikedDishes.where((d) => d.key == dish.key).isEmpty) {
      dislikedDishes.add(dish);
      _dislikedDishes.add(dislikedDishes);
    }

    /// remove from liked dishes list
    List<Data> likedDishes = _likedDishes.value ?? [];
    if (likedDishes.where((d) => d.key == dish.key).isNotEmpty) {
      likedDishes.removeWhere((d) => d.key == dish.key);
      _likedDishes.add(likedDishes);
    }
  }

  void addDish(String category, String name) {
    List<Data> dishes = _dishes.value ?? [];
    dishes.insert(
      0,
      Data('_(${_addedDishesCounter++})', {
        'category': category,
        'name': name,
      }),
    );
    _dishes.add(dishes);
  }

  void resetLastDishes() {
    _dishes.lastWhere((dishes) => dishes != null).then((dishes) {
      _dishes.add(dishes);
    });
  }


  Future<String> getImageUrl({
     @required File photo,
  }) async {
    /// upload photo
    Future<String> photoUrl; 
    if (photo != null) {
      var request =  http.MultipartRequest("POST", Uri.parse("http://base.edibly.ca/api/upload"));
        request.files.add(http.MultipartFile.fromBytes('file', await photo.readAsBytes(), contentType: MediaType('image', 'jpeg')));
       await request.send().then((response) {
        if (response.statusCode == 200) { photoUrl =  response.stream.bytesToString();}
        else {
          SnackBar(content: Text("An error occurred."));
        }
      });
    }
    return photoUrl;
  }
  Future<bool> submit({
    @required String restaurantName,
    @required List<String> tags,
    @required double rating,
    @required String review,
    String photoUrl}) async { 

      /*
      String imageUuid = Uuid().v1();
      StorageTaskSnapshot storageTaskSnapshot = await FirebaseStorage.instance
          ?.ref()
          ?.child('restaurants')
          ?.child(restaurantKey)
          ?.child('$imageUuid.jpg')
          ?.putFile(photo)
          ?.onComplete;
      photoUrl = await storageTaskSnapshot?.ref?.getDownloadURL();
      */

    // /// put photo info into database)

    // if (photoUrl != null && photoUrl.isNotEmpty) {
    //   await _firebaseDatabase.reference().child('restaurantImages').child(restaurantKey).push().set({
    //     'imageUrl': photoUrl,
    //     'userId': firebaseUserId,
    //     'timeStamp': DateTime.now().microsecondsSinceEpoch / 1000000,
    //     'isATest': false,
    //   });
    // }

    /// create post value
    var reviewBody = {
      'uid': firebaseUserId,
      'rid': int.parse(restaurantKey),
      'text': review,
      'stars': rating,
      'postType': 0,
      'tags': tags,
      'photo': photoUrl ?? null
    };

    http.post("http://base.edibly.ca/api/reviews/add",
            body: json.encode(reviewBody))
        .then((http.Response response) {
      final int statusCode = response.statusCode;

      if (statusCode < 200 || statusCode > 400 || reviewBody == null) {
        throw new Exception("Error while sending data" + statusCode.toString());
      }
    });
    return true;
    //   DatabaseReference reviewReference = _firebaseDatabase.reference().child('reviews').child(restaurantKey).push();
    //   await reviewReference.set(value);
    //   await _firebaseDatabase.reference().child('feedPosts').child(reviewReference.key).set(value);
    //   await _firebaseDatabase.reference().child('postsByUser').child(firebaseUserId).child(reviewReference.key).set(value);
    //   await _submitRatedDishes(_likedDishes.value, reviewReference.key, true);
    //   await _submitRatedDishes(_dislikedDishes.value, reviewReference.key, false);
    //   await _submitAddedDishes(_likedDishes.value, reviewReference.key, true);
    //   await _submitAddedDishes(_dislikedDishes.value, reviewReference.key, false);
    //   await _updateRestaurantRating(rating: rating, tags: tags);
    //   return true;
    // }
  }

  Future<bool> _submitRatedDishes(
      List<Data> ratedDishes, String reviewKey, bool liked) async {
    await Future.forEach(
        (ratedDishes ?? []).where((d) => !d.key.toString().startsWith('_')),
        (dish) async {
      await _firebaseDatabase
          .reference()
          .child('dishReviews')
          .child(restaurantKey)
          .child(reviewKey)
          .child(dish.key)
          .set({
        'ratingString': liked ? 'Good' : 'Bad',
        'dishName': dish.value,
        'dishKey': dish.key,
        'reviewKey': reviewKey,
        'isATest': false,
      });
      DatabaseReference ratingReference = _firebaseDatabase
          .reference()
          .child('dishRatings')
          .child(restaurantKey)
          .child(dish.key);
      DataSnapshot ratingSnapshot = await ratingReference.once();
      await ratingReference.set({
        'isGoodCount': _lookup(ratingSnapshot?.value, 'isGoodCount') ??
            0 + (liked ? 1 : 0),
        'isBadCount': _lookup(ratingSnapshot?.value, 'isBadCount') ??
            0 + (!liked ? 1 : 0),
        'isNotEdibleCount':
            _lookup(ratingSnapshot?.value, 'isNotEdibleCount') ?? 0,
      });
    });
    return true;
  }

  Future<bool> _submitAddedDishes(
      List<Data> addedDishes, String reviewKey, bool liked) async {
    int counter = 0;
    await Future.forEach(
        (addedDishes ?? []).where((d) => d.key.toString().startsWith('_')),
        (dish) async {
      await _firebaseDatabase
          .reference()
          .child('addedDishes')
          .child(restaurantKey)
          .child(reviewKey)
          .child('$counter')
          .set({
        'ratingString': liked ? 'Good' : 'Bad',
        'dishName': dish.value,
        'dishKey': 'Added($counter)',
        'reviewKey': reviewKey,
        'isATest': false,
      });
      counter++;
    });
    return true;
  }

  // Future<bool> _updateRestaurantRating({
  //   @required List<String> tags,
  //   @required double rating,
  // }) async {
  //   DatabaseReference ratingReference = _firebaseDatabase
  //       .reference()
  //       .child('restaurantRatings')
  //       .child(restaurantKey);
  //   DataSnapshot ratingSnapshot = await ratingReference.once();
  //   int totalReviews = _lookup(ratingSnapshot?.value, 'totalReviews') ?? 0;
  //   dynamic oldAverageRatingDynamic =
  //       _lookup(ratingSnapshot?.value, 'numRating') ?? -1;
  //   double oldAverageRating = oldAverageRatingDynamic is int
  //       ? oldAverageRatingDynamic.toDouble()
  //       : oldAverageRatingDynamic as double;
  //   double newAverageRating = oldAverageRating == -1
  //       ? rating
  //       : ((totalReviews * oldAverageRating + rating) / (totalReviews + 1));
  //   dynamic tagValues = _lookup(ratingSnapshot?.value, 'tagDict') ?? {};
  //   if (tagValues is List) tagValues = {};
  //   tags.forEach((tag) {
  //     if (tagValues[tag] != null) {
  //       tagValues[tag] += 1;
  //     } else {
  //       tagValues[tag] = 1;
  //     }
  //   });
  //   await ratingReference.set({
  //     'tagDict': tagValues,
  //     'numRating': newAverageRating,
  //     'totalReviews': totalReviews + 1,
  //     'otherTags': _lookup(ratingSnapshot?.value, 'otherTags')
  //   });
  //   return true;
  // }

  dynamic _lookup(dynamic value, String key) {
    return value == null ? null : value[key];
  }

  /// Other
  void getDishes() async {
    final url =
        ('http://base.edibly.ca/api/restaurants/' + restaurantKey + '/dishes');
    final response = await http.get(url);
    final dishesMap = json.decode(response.body).reversed;

    //TODO: - Dish reviews
    List<Data> dishesWithRating = [];
    dishesMap.forEach((d) => dishesWithRating.add(Data(d['did'], d)));
    _dishes.add(dishesWithRating);
  }

  /// Dispose function
  void dispose() {
    _dislikedDishes.close();
    _likedDishes.close();
    _dishes.close();
    _rating.close();
    _photo.close();
    _tags.close();
  }
}
