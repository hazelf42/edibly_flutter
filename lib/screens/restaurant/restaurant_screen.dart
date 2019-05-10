import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:edibly/screens/restaurant/restaurant_bloc.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/values/app_colors.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/models/data.dart';
import 'package:edibly/main_bloc.dart';

class RestaurantScreen extends StatelessWidget {
  final String firebaseUserId;
  final String restaurantKey;

  RestaurantScreen({
    @required this.firebaseUserId,
    @required this.restaurantKey,
  });

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

  Widget _address({@required Data restaurant}) {
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
      margin: const EdgeInsets.only(top: 12.0),
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

  Widget _coverImage({@required Data restaurant}) {
    if (restaurant == null || restaurant.value['photoURL'] == null || restaurant.value['photoURL'].toString().isEmpty) {
      return Container();
    }
    return Image.network(
      restaurant.value['photoURL'],
      height: 150.0,
      fit: BoxFit.cover,
    );
  }

  Widget _bookmarkButton({@required RestaurantBloc restaurantBloc, @required Data restaurant}) {
    return StreamBuilder<Event>(
      stream: restaurantBloc.getRestaurantBookmarkValue(firebaseUserId, restaurant.key),
      builder: (context, bookmarkValueSnapshot) {
        bool bookmarked = bookmarkValueSnapshot?.data?.snapshot?.value == 1;
        return IconButton(
          icon: Icon(
            bookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: bookmarked ? AppColors.primarySwatch.shade600 : Theme.of(context).disabledColor,
          ),
          onPressed: () {
            restaurantBloc.setRestaurantBookmarkValue(firebaseUserId, restaurant.key, !bookmarked);
          },
        );
      },
    );
  }

  Widget _header({@required BuildContext context, @required RestaurantBloc restaurantBloc, @required Data restaurant}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _coverImage(restaurant: restaurant),
        Container(height: 8.0),
        Container(
          padding: const EdgeInsets.fromLTRB(12.0, 8.0, 0.0, 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          restaurant.value['name'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 22.0,
                          ),
                        ),
                        _rating(
                          context: context,
                          value: restaurant.value['rating'],
                        ),
                        _address(restaurant: restaurant),
                      ],
                    ),
                  ),
                  _bookmarkButton(
                    restaurantBloc: restaurantBloc,
                    restaurant: restaurant,
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
    );
  }

  Widget _buttonBar({@required AppLocalizations localizations}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          Container(width: 16.0),
          RaisedButton(
            onPressed: () {},
            child: Text(
              localizations.addReview.toUpperCase(),
              style: TextStyle(fontSize: 13.0),
            ),
          ),
          Container(width: 16.0),
          RaisedButton(
            onPressed: () {},
            child: Text(
              localizations.addTip.toUpperCase(),
              style: TextStyle(fontSize: 13.0),
            ),
          ),
          Container(width: 16.0),
          RaisedButton(
            onPressed: () {},
            child: Text(
              localizations.addPhoto.toUpperCase(),
              style: TextStyle(fontSize: 13.0),
            ),
          ),
          Container(width: 16.0),
        ],
      ),
    );
  }

  Widget _featuredTip({
    @required BuildContext context,
    @required MainBloc mainBloc,
    @required AppLocalizations localizations,
    @required Data restaurant,
  }) {
    if (restaurant == null || restaurant.value['featured_tip'] == null || restaurant.value['featured_tip'].toString().isEmpty) {
      return Container();
    }
    Map<dynamic, dynamic> featuredTipMap = restaurant.value['featured_tip'];
    if (featuredTipMap == null) return Container();
    featuredTipMap = featuredTipMap.values.elementAt(0);
    if (featuredTipMap == null) return Container();
    return StreamBuilder<Event>(
      stream: mainBloc.getUser(featuredTipMap['tipUserId'].toString()),
      builder: (context, snapshot) {
        Map<dynamic, dynamic> authorValue = snapshot?.data?.snapshot?.value;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SingleLineText(
                  localizations.featuredTip.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.0,
                  ),
                ),
                Container(height: 10.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 18.0,
                      backgroundImage: authorValue == null ? null : NetworkImage(authorValue['photoUrl']),
                      child: authorValue == null
                          ? SizedBox(
                              width: 34.0,
                              height: 34.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                              ),
                            )
                          : null,
                    ),
                    Container(
                      width: 16.0,
                    ),
                    Expanded(
                      child: authorValue == null
                          ? Container()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                SingleChildScrollView(
                                  physics: NeverScrollableScrollPhysics(),
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: <Widget>[
                                      SingleLineText(
                                        '${authorValue['firstName']} ${authorValue['lastName']}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SingleLineText(
                                        ' (${authorValue['dietName']}${(authorValue['isGlutenFree'] as bool ? ', ${localizations.glutenFree.toLowerCase()}' : '')})',
                                        style: TextStyle(
                                          color: Theme.of(context).hintColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                featuredTipMap['description'] != null
                                    ? Container(
                                        margin: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          featuredTipMap['description'],
                                          style: TextStyle(fontSize: 13.0),
                                        ),
                                      )
                                    : Container(),
                              ],
                            ),
                    ),
                    Container(
                      width: 24.0,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    return DisposableProvider<RestaurantBloc>(
      packageBuilder: (context) => RestaurantBloc(
            firebaseUserId: firebaseUserId,
            restaurantKey: restaurantKey,
          ),
      child: Builder(
        builder: (context) {
          final MainBloc mainBloc = Provider.of<MainBloc>(context);
          final RestaurantBloc restaurantBloc = Provider.of<RestaurantBloc>(context);
          return Scaffold(
            appBar: AppBar(
              title: SingleLineText(localizations.restaurant),
            ),
            body: Container(
              alignment: Alignment.center,
              child: StreamBuilder<Data>(
                  stream: restaurantBloc.restaurant,
                  builder: (context, restaurantSnapshot) {
                    if (restaurantSnapshot?.data == null) {
                      if (restaurantSnapshot.connectionState == ConnectionState.waiting) {
                        restaurantBloc.getRestaurant();
                      }
                      return CircularProgressIndicator();
                    } else {
                      return ListView(
                        children: <Widget>[
                          _header(context: context, restaurantBloc: restaurantBloc, restaurant: restaurantSnapshot?.data),
                          _featuredTip(
                            context: context,
                            mainBloc: mainBloc,
                            localizations: localizations,
                            restaurant: restaurantSnapshot?.data,
                          ),
                          Container(height: 6.0),
                          _buttonBar(localizations: localizations),
                          ListTile(
                            onTap: () {},
                            title: SingleLineText(localizations.menu),
                            leading: Icon(Icons.restaurant_menu),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16.0,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                          ListTile(
                            onTap: () {},
                            title: SingleLineText(localizations.reviews),
                            leading: Icon(Icons.comment),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16.0,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                          ListTile(
                            onTap: () {},
                            title: SingleLineText(localizations.tips),
                            leading: Icon(Icons.info),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16.0,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                          ListTile(
                            onTap: () {},
                            title: SingleLineText(localizations.photos),
                            leading: Icon(Icons.collections),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16.0,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                        ],
                      );
                    }
                  }),
            ),
          );
        },
      ),
    );
  }
}
