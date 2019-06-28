import 'package:flutter/material.dart';

import 'package:edibly/screens/restaurant/reviews/restaurant_reviews_bloc.dart';
import 'package:edibly/screens/new_post/new_post_screen.dart';
import 'package:edibly/screens/post/post_preview_widget.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/models/data.dart';

class RestaurantReviewsScreen extends StatelessWidget {
  final String firebaseUserId;
  final String restaurantName;
  final String restaurantKey;

  RestaurantReviewsScreen({
    @required this.firebaseUserId,
    @required this.restaurantName,
    @required this.restaurantKey,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: SingleLineText(localizations.reviews),
      ),
      body: DisposableProvider<RestaurantReviewsBloc>(
        packageBuilder: (context) => RestaurantReviewsBloc(
              restaurantKey: restaurantKey,
            ),
        child: Builder(
          builder: (context) {
            final RestaurantReviewsBloc restaurantReviewsBloc = Provider.of<RestaurantReviewsBloc>(context);
            return Container(
              color: Theme.of(context).brightness == Brightness.dark ? null : Colors.grey.shade300,
              alignment: Alignment.center,
              child: StreamBuilder<List<Data>>(
                stream: restaurantReviewsBloc.reviews,
                builder: (context, reviewsSnapshot) {
                  if (reviewsSnapshot?.data == null) {
                    if (reviewsSnapshot.connectionState == ConnectionState.waiting) {
                      restaurantReviewsBloc.getReviews();
                    }
                    return CircularProgressIndicator();
                  }
                  if (reviewsSnapshot.data.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.warning,
                            color: Theme.of(context).hintColor,
                            size: 48.0,
                          ),
                          Container(
                            height: 12.0,
                          ),
                          Text(
                            localizations.noReviewsText,
                            style: TextStyle(
                              fontSize: 18.0,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          Container(
                            height: 12.0,
                          ),
                          RaisedButton(
                            onPressed: () async{
                              final addedNewPost = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => NewPostScreen(
                                    firebaseUserId: firebaseUserId,
                                    restaurantName: restaurantName,
                                    restaurantKey: restaurantKey,
                                  ),
                                ),
                              );
                              if (addedNewPost != null && addedNewPost is bool && addedNewPost) {
                                final snackBar = SnackBar(
                                  content: Text(localizations.reviewAddedSuccessText),
                                );
                                Scaffold.of(context).showSnackBar(snackBar);
                              }
                            },
                            child: SingleLineText(localizations.addReview.toUpperCase()),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: 5.0,
                        horizontal: 6.0,
                      ),
                      itemCount: reviewsSnapshot.data.length,
                      itemBuilder: (context, position) {
                        if (reviewsSnapshot.data.elementAt(position) == null) {
                          restaurantReviewsBloc.getReviews();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(),
                          );
                        }
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 5.0,
                            horizontal: 4.0,
                          ),
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: PostPreviewWidget(
                              uid: reviewsSnapshot.data.elementAt(position).value['uid'],
                              post: reviewsSnapshot.data.elementAt(position),
                            ),
                          ),
                        );
                      },
                    ),
                    onRefresh: () {
                      restaurantReviewsBloc.clearReviews();
                      restaurantReviewsBloc.getReviews();
                      return Future.delayed(Duration(seconds: 1));
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
