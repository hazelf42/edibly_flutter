import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:edibly/screens/restaurant/restaurant_screen.dart';
import 'package:edibly/screens/search/search_bloc.dart';
import 'package:edibly/bloc_helper/provider.dart';
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
      margin: const EdgeInsets.only(top: 4.0),
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

  Widget _address() {
    if (restaurant?.value == null ||
        (restaurant.value['address'] ?? restaurant.value['address1'] ?? restaurant.value['address2']) == null) {
      return Container();
    }
    return Container(
      margin: const EdgeInsets.only(top: 4.0),
      child: Text(
        (restaurant.value['address'] ?? restaurant.value['address1'] ?? restaurant.value['address2']).toString().trim() ?? '',
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
      height: 32.0,
      margin: const EdgeInsets.only(top: 6.0, right: 12.0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, position) {
          return Container(width: 8.0, height: 1.0);
        },
        itemCount: tags.length,
        itemBuilder: (context, position) {
          return CustomTag('${tags.elementAt(position).key} (${tags.elementAt(position).value})');
        },
      ),
    );
  }

  Widget _bookmarkButton({@required SearchBloc searchBloc}) {
    return StreamBuilder<Event>(
      stream: searchBloc.getRestaurantBookmarkValue(firebaseUser.uid, restaurant.key),
      builder: (context, bookmarkValueSnapshot) {
        bool bookmarked = bookmarkValueSnapshot?.data?.snapshot?.value == 1;
        return IconButton(
          icon: Icon(
            bookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: bookmarked ? AppColors.primarySwatch.shade600 : Theme.of(context).disabledColor,
          ),
          onPressed: () {
            searchBloc.setRestaurantBookmarkValue(firebaseUser.uid, restaurant.key, !bookmarked);
          },
        );
      },
    );
  }

  Widget _photo() {
    bool hasPhoto = (restaurant.value['photoUrl'] ?? restaurant.value['photoURL'] ?? '').toString().isNotEmpty;
    if (!hasPhoto) return Container();
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(4.0),
        bottomLeft: Radius.circular(4.0),
      ),
      child: Container(
        width: 70.0,
        height: 70.0,
        color: Colors.white,
        child: CachedNetworkImage(
          imageUrl: restaurant.value['photoUrl'] ?? restaurant.value['photoURL'] ?? '',
          width: 70.0,
          height: 70.0,
          fit: BoxFit.cover,
          placeholder: (context, imageUrl) {
            return Container(
              width: 70.0,
              height: 70.0,
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SearchBloc searchBloc = Provider.of<SearchBloc>(context);
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
      child: Card(
        margin: EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _photo(),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(12.0, 8.0, 0.0, 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: 48.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
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
                                _address(),
                              ],
                            ),
                          ),
                        ),
                        _bookmarkButton(searchBloc: searchBloc),
                      ],
                    ),
                    _tags(
                      context: context,
                      value: restaurant.value['rating'],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
