import 'dart:io';

import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:edibly/screens/new_post/new_post_dishes_screen.dart';
import 'package:edibly/screens/new_post/new_post_bloc.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/values/app_colors.dart';
import 'package:edibly/custom/widgets.dart';

class NewPostDescriptionScreen extends StatelessWidget {
  final TextEditingController textEditingController = TextEditingController();
  final String firebaseUserId;
  final String restaurantName;
  final String restaurantKey;
  final List<String> tags;
  final double rating;
  final File photo;

  NewPostDescriptionScreen({
    @required this.firebaseUserId,
    @required this.restaurantName,
    @required this.restaurantKey,
    @required this.rating,
    @required this.photo,
    @required this.tags,
  });

  Widget _rating({
    @required BuildContext context,
    @required NewPostBloc newPostBloc,
  }) {
    return Container(
      child: Row(
        children: <Widget>[
          SmoothStarRating(
            allowHalfRating: true,
            starCount: 5,
            rating: rating / 2.0 - 0.1,
            size: (MediaQuery.of(context).size.width - 64.0) / 10,
            color: AppColors.primarySwatch.shade900,
            borderColor: AppColors.primarySwatch.shade900,
          ),
          Container(
            margin: const EdgeInsets.only(left: 8.0),
            width: 32.0,
            child: SingleLineText(
              (rating / 2.0).toStringAsFixed(1),
              style: TextStyle(
                color: AppColors.primarySwatch.shade900,
                fontSize: (MediaQuery.of(context).size.width - 64.0) / 12.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: SingleLineText(localizations.addReview),
      ),
      body: DisposableProvider<NewPostBloc>(
        packageBuilder: (context) => NewPostBloc(
              restaurantKey: restaurantKey,
            ),
        child: Builder(
          builder: (context) {
            final NewPostBloc newPostBloc = Provider.of<NewPostBloc>(context);
            return Container(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    restaurantName,
                    style: Theme.of(context).textTheme.headline,
                  ),
                  Container(height: 6.0),
                  _rating(
                    context: context,
                    newPostBloc: newPostBloc,
                  ),
                  Container(height: 16.0),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 1.5,
                          color: Theme.of(context).disabledColor,
                        ),
                        borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                      ),
                      child: TextField(
                        controller: textEditingController,
                        expands: true,
                        maxLines: null,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(10000),
                        ],
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: localizations.yourCanWriteYourReviewHere,
                        ),
                      ),
                    ),
                  ),
                  Container(height: 16.0),
                  RaisedButton(
                    color: AppColors.primarySwatch.shade400,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) {
                            return NewPostDishesScreen(
                              firebaseUserId: firebaseUserId,
                              restaurantName: restaurantName,
                              restaurantKey: restaurantKey,
                              rating: rating,
                              review: textEditingController.text,
                              photo: photo,
                              tags: tags,
                            );
                          },
                        ),
                      );
                    },
                    child: SingleLineText(
                      localizations.next,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
