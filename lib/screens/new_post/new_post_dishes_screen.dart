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

class NewPostDishesScreen extends StatelessWidget {
  final String firebaseUserId;
  final String restaurantName;
  final String restaurantKey;
  final List<String> tags;
  final double rating;
  final String review;
  final File photo;

  NewPostDishesScreen({
    @required this.firebaseUserId,
    @required this.restaurantName,
    @required this.restaurantKey,
    @required this.rating,
    @required this.review,
    @required this.photo,
    @required this.tags,
  });

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
            return Container();
          },
        ),
      ),
    );
  }
}
