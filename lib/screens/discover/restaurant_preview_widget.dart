import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:edibly/screens/restaurant/restaurant_screen.dart';
import 'package:edibly/values/app_colors.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/models/data.dart';

class RestaurantPreviewWidget extends StatelessWidget {
  final FirebaseUser firebaseUser;
  final Data restaurant;

  RestaurantPreviewWidget({
    @required this.firebaseUser,
    @required this.restaurant,
  }) : super(key: Key(restaurant.key));

  List<Data> dynamicTagArrayToTagList(dynamic dynamicTagArray) {
    List<Data> tagList = [];
    if (dynamicTagArray != null) {
      Map<dynamic, dynamic> map = dynamicTagArray;
      map.forEach((key, value) {
        tagList.add(Data(key, value));
      });
    }
    return tagList;
  }

  Widget _rating({@required BuildContext context, @required dynamic value}) {
    if (value == null || value['numRating'] == null) {
      return Container();
    }
    return Container(
      margin: const EdgeInsets.only(top: 2.0),
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            SmoothStarRating(
              allowHalfRating: true,
              starCount: 5,
              rating: value['numRating'] / 2.0 - 0.1,
              size: 16.0,
              color: AppColors.primarySwatch.shade900,
              borderColor: AppColors.primarySwatch.shade900,
            ),
            Container(
              width: 8.0,
            ),
            SingleLineText(
              (double.parse(value['numRating'].toString()) / 2.0).toStringAsFixed(1),
              style: TextStyle(
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tags({@required BuildContext context, @required dynamic value}) {
    if (value == null || value['tagDict'] == null || value['tagDict'].toString().isEmpty) {
      return Container();
    }
    List<Data> tags = dynamicTagArrayToTagList(value['tagDict']);
    tags.sort((a, b) => b.value - a.value);
    return Container(
        margin: const EdgeInsets.only(top: 6.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: tags.map((data) {
              return Container(
                margin: EdgeInsets.only(
                  top: 1.0,
                  bottom: 1.0,
                  left: data.key == tags.first.key ? 0 : 6.0,
                ),
                child: CustomTag(
                  '${data.key} (${data.value})',
                  fontSize: 10.0,
                  padding: const EdgeInsets.symmetric(
                    vertical: 2.0,
                    horizontal: 3.0,
                  ),
                ),
              );
            }).toList(),
          ),
        ));
  }

  Widget _photoAndDistance(String distance) {
    String url = (restaurant.value['photoUrl'] ?? restaurant.value['photoURL'] ?? '').toString();
    bool hasPhoto = url.isNotEmpty && url.toLowerCase() != 'none';
    if (!hasPhoto) {
      url = 'https://images.pexels.com/photos/6267/menu-restaurant-vintage-table.jpg?auto=compress&cs=tinysrgb&dpr=1&w=500';
      hasPhoto = true;
    }
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(hasPhoto ? 4.0 : 0.0),
        topRight: Radius.circular(hasPhoto ? 4.0 : 0.0),
      ),
      child: Container(
        height: hasPhoto ? 120.0 : null,
        color: hasPhoto ? Colors.white : null,
        child: Stack(
          children: <Widget>[
            hasPhoto
                ? CachedNetworkImage(
                    imageUrl: url,
                    width: 200.0,
                    height: 120.0,
                    fit: BoxFit.cover,
                    placeholder: (context, imageUrl) {
                      return Container(
                        width: 200.0,
                        height: 120.0,
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(),
                      );
                    },
                  )
                : Container(),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 4.0,
                horizontal: 6.0,
              ),
              color: Colors.black.withOpacity(0.5),
              child: SingleLineText(
                distance,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String url = (restaurant.value['photoUrl'] ?? restaurant.value['photoURL'] ?? '').toString();
    bool hasPhoto = url.isNotEmpty && url.toLowerCase() != 'none';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantScreen(
                  firebaseUserId: firebaseUser.uid,
                  restaurantKey: restaurant.key,
                ),
          ),
        );
      },
      behavior: HitTestBehavior.translucent,
      child: Container(
        width: 200.0,
        child: Card(
          margin: EdgeInsets.zero,
          child: Column(
            mainAxisAlignment: hasPhoto ? MainAxisAlignment.start : MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _photoAndDistance(restaurant.value['distance'] != null
                  ? '${double.parse(restaurant.value['distance'].toString()).toStringAsFixed(1)} km'
                  : '...'),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              SingleLineText(
                                restaurant.value['name'] ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.0,
                                ),
                              ),
                              _rating(
                                context: context,
                                value: restaurant.value['rating'],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    _tags(
                      context: context,
                      value: restaurant.value['rating'],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
