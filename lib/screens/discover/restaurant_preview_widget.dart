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
      dynamicTagArray.forEach((value) {
        tagList.add(Data(value['num'], value));
      });
    }
    return tagList;
  }

  Widget _rating({@required BuildContext context, @required dynamic value}) {
    if (value == null) {
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
              rating: value / 2.0 - 0.1,
              size: 16.0,
              color: AppColors.primarySwatch.shade900,
              borderColor: AppColors.primarySwatch.shade900,
            ),
            Container(
              width: 8.0,
            ),
            SingleLineText(
              (double.parse(value.toString()) / 2.0).toStringAsFixed(1),
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
    if (value == null || value['tags'] == null || value['tags'].toString().isEmpty) {
      return Container();
    }

    List<Data> tags = dynamicTagArrayToTagList(value['tags']);
    tags.sort((a, b) => b.value['num'] - a.value['num']);
    return Container(
      height: 20.0,
      margin: const EdgeInsets.only(top: 6.0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, position) {
          return Container(width: 6.0, height: 1.0);
        },
        itemCount: tags.length,
        itemBuilder: (context, position) {
          return CustomTag(
            '${tags.elementAt(position).value['text']} (${tags.elementAt(position).key})',
            fontSize: 10.0,
            padding: const EdgeInsets.symmetric(
              vertical: 2.0,
              horizontal: 3.0,
            ),
          );
        },
      ),
    );
  }

  Widget _photoAndDistance(String distance) {
    String url = (restaurant.value['photo'] ?? '').toString();
    bool hasPhoto = url.isNotEmpty && url.toLowerCase() != 'none';
    if (!hasPhoto) url = 'https://img2.10bestmedia.com/static/img/placeholder-restaurants.jpg';
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(4.0),
        topRight: Radius.circular(4.0),
      ),
      child: Container(
        height: 120.0,
        color: Colors.white,
        child: Stack(
          children: <Widget>[
            CachedNetworkImage(
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
            ),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _photoAndDistance(restaurant.value['distance'] != null
                  ? '${double.parse(restaurant.value['distance'].toString()).toStringAsFixed(1)} km'
                  : '...'),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                child: Column(
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
                                value: restaurant.value['averagerating'],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    _tags(
                      context: context,
                      value: restaurant.value,
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
