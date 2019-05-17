import 'dart:io';

import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/screens/new_post/new_post_bloc.dart';
import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/values/app_colors.dart';
import 'package:edibly/custom/widgets.dart';

class NewPostDescriptionScreen extends StatelessWidget {
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

  static Future _getImage({
    @required ImageSource imageSource,
    @required NewPostBloc newPostBloc,
  }) async {
    var image = await ImagePicker.pickImage(source: imageSource);
    if (image != null) newPostBloc.setPhoto(image);
  }

  Widget _rating({
    @required BuildContext context,
    @required NewPostBloc newPostBloc,
  }) {
    return StreamBuilder<double>(
      stream: newPostBloc.rating,
      builder: (context, snapshot) {
        return Container(
          child: Row(
            children: <Widget>[
              SmoothStarRating(
                allowHalfRating: true,
                starCount: 10,
                rating: snapshot?.data ?? 0,
                size: (MediaQuery.of(context).size.width - 64.0) / 10,
                color: AppColors.primarySwatch.shade900,
                borderColor: AppColors.primarySwatch.shade900,
                onRatingChanged: (rating) {
                  if (rating < 1) rating = 1;
                  newPostBloc.setRating(rating.floor().toDouble());
                },
              ),
              Container(
                margin: const EdgeInsets.only(left: 8.0),
                width: 32.0,
                child: SingleLineText(
                  (snapshot?.data ?? 0).toStringAsFixed(0),
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
      },
    );
  }

  Widget _tags({
    @required NewPostBloc newPostBloc,
    @required AppLocalizations localizations,
  }) {
    var tagArray = localizations.tagArray;
    return StreamBuilder<List<String>>(
      stream: newPostBloc.tags,
      builder: (context, snapshot) {
        return Container(
          height: 32.0,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (context, position) {
              return Container(width: 8.0, height: 1.0);
            },
            itemCount: tagArray.length + 1,
            itemBuilder: (context, position) {
              if (position == 0) {
                return Center(
                  child: Container(
                    width: 120.0,
                    height: 30.0,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(
                        width: 1.5,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                    child: TextField(
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: localizations.other,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(30),
                      ],
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                );
              }
              String tag = tagArray.elementAt(position - 1);
              return GestureDetector(
                onTap: () {
                  if ((snapshot?.data ?? []).contains(tag)) {
                    newPostBloc.removeTag(tag);
                  } else {
                    newPostBloc.addTag(tag);
                  }
                },
                behavior: HitTestBehavior.translucent,
                child: CustomTag(
                  tag,
                  disabled: !(snapshot?.data ?? []).contains(tag),
                  selected: (snapshot?.data ?? []).contains(tag),
                  fontSize: 16.0,
                ),
              );
            },
          ),
        );
      },
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
            return ListView(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 12.0,
              ),
              children: <Widget>[
                Text(
                  restaurantName,
                  style: Theme.of(context).textTheme.headline,
                ),
                Container(height: 16.0),
                SingleLineText(
                  localizations.rateTheRestaurant,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                Container(height: 6.0),
                _rating(
                  context: context,
                  newPostBloc: newPostBloc,
                ),
                Container(height: 16.0),
                SingleLineText(
                  localizations.addPhoto,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                Container(height: 6.0),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          RaisedButton(
                            onPressed: () {},
                            child: SingleLineText(localizations.takePicture),
                          ),
                          RaisedButton(
                            onPressed: () {},
                            child: SingleLineText(localizations.takePicture),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 12.0),
                    Expanded(
                      child: StreamBuilder(builder: (context, photoSnapshot) {
                        return photoSnapshot.hasData
                            ? Image.file(
                                photoSnapshot?.data,
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.primarySwatch.shade400,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.image,
                                  color: AppColors.primarySwatch.shade400,
                                ),
                                width: 90.0,
                                height: 90.0,
                              );
                      }),
                    ),
                  ],
                ),
                Container(height: 16.0),
                SingleLineText(
                  localizations.addTags,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                Container(height: 8.0),
                _tags(
                  newPostBloc: newPostBloc,
                  localizations: localizations,
                ),
                Container(height: 16.0),
                StreamBuilder<double>(
                  stream: newPostBloc.rating,
                  builder: (context, snapshot) {
                    return RaisedButton(
                      color: AppColors.primarySwatch.shade400,
                      onPressed: (snapshot?.data ?? 0.0) == 0.0
                          ? null
                          : () {
                              double rating = snapshot.data ?? 0;
                              File photo = newPostBloc.photoValue();
                              List<String> tags = newPostBloc.tagsValue() ?? [];
                              if(rating != 0) {

                              }
                            },
                      child: SingleLineText(
                        localizations.next,
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
