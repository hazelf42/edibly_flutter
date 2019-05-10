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
      child: Row(
        children: <Widget>[
          SmoothStarRating(
            allowHalfRating: true,
            starCount: 10,
            rating: value['numRating'] / 1.0,
            size: 16.0,
            color: AppColors.primarySwatch.shade900,
            borderColor: AppColors.primarySwatch.shade900,
          ),
          Container(
            width: 8.0,
          ),
          SingleLineText(
            value['numRating'].toString(),
            style: TextStyle(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _address() {
    if (restaurant?.value == null || restaurant.value['address'] == null) {
      return Container();
    }
    return Container(
      margin: const EdgeInsets.only(top: 4.0),
      child: Text(
        restaurant.value['address'].toString().trim() ?? '',
      ),
    );
  }

  Widget _tags({@required BuildContext context, @required dynamic value}) {
    if (value == null || value['tagDict'] == null || value['tagDict'].toString().isEmpty) {
      return Container();
    }
    return Container(
      margin: const EdgeInsets.only(top: 6.0),
      child: Wrap(
        spacing: 6.0,
        runSpacing: 6.0,
        children: dynamicTagArrayToTagList(value['tagDict']).map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(
              vertical: 4.0,
              horizontal: 8.0,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).chipTheme.backgroundColor,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: SingleLineText(
              '${tag.key} (${tag.value})',
              style: TextStyle(
                fontSize: 12.0,
              ),
            ),
          );
        }).toList(),
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
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4.0),
                bottomLeft: Radius.circular(4.0),
              ),
              child: Container(
                width: 70.0,
                height: 70.0,
                color: Colors.white,
                child: FadeInImage(
                  image: restaurant.value['photoUrl'] != null
                      ? (NetworkImage(restaurant.value['photoUrl'] ?? ''))
                      : AssetImage('assets/drawables/ic_launcher.png'),
                  placeholder: AssetImage('assets/drawables/ic_launcher.png'),
                  width: 70.0,
                  height: 70.0,
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(12.0, 8.0, 0.0, 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    _tags(
                      context: context,
                      value: restaurant.value['rating'],
                    ),
                  ],
                ),
              ),
            ),
            StreamBuilder<Event>(
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
            ),
          ],
        ),
      ),
    );
  }
}
