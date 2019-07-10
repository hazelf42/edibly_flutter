import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as TimeAgo;
import 'dart:convert';

import 'package:edibly/screens/post/post_screen.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/values/app_colors.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/models/data.dart';
import 'package:edibly/main_bloc.dart';

class PostPreviewWidget extends StatelessWidget {
  final String uid;
  final Data post;

  PostPreviewWidget({
    @required this.uid,
    @required this.post,
  });

  List<String> dynamicTagArrayToTagList(dynamic dynamicTagArray) {
    List<String> tagList = [];
    if (dynamicTagArray != null) {
      for (var item in dynamicTagArray) {
        if (item != null) tagList.add(item.toString());
      }
    }
    return tagList;
  }

  String _postTypeToText({
    @required int postType,
    @required AppLocalizations localizations,
  }) {
    switch (postType) {
      case 0:
        return localizations.wroteReview;
      case 1:
        return localizations.addedPhoto;
      case 2:
        return localizations.addedTip;
      default:
        return '';
    }
  }

  Widget _author({@required Map authorValue, @required AppLocalizations localizations, @required BuildContext context}) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 0.0, 12.0),
          child: Row(
            children: <Widget>[
              // CircleAvatar(
              //   radius: 24.0,
              //  backgroundImage: authorValue  == null ? null : NetworkImage(authorValue['photo']),
              //   child: authorValue == null
              //       ? SizedBox(
              //           width: 46.0,
              //           height: 46.0,
              //           child: CircularProgressIndicator(
              //             strokeWidth: 2.0,
              //           ),
              //         )
              //       : null,
              // ),
              Container(
                width: 16.0,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    authorValue == null
                        ? Container(height: 0,)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SingleChildScrollView(
                                physics: NeverScrollableScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: <Widget>[
                                    SingleLineText(
                                      '${authorValue['firstname']} ${authorValue['lastname']}   ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SingleLineText(
                                      
                                    ((authorValue['veglevel'] == 1) ? '${localizations.vegetarian}' : '${localizations.vegan}') + " " + ((authorValue['glutenfree'] == 1) ? 'glutenfree' : ''),
                                      style: TextStyle(
                                        color: Theme.of(context).hintColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 4.0,
                              ),
                              SingleLineText(
                                '${_postTypeToText(
                                  postType: post.value['type'],
                                  localizations: localizations,
                                )} ${TimeAgo.format(DateTime.fromMillisecondsSinceEpoch((double.parse(post.value['timestamp'].toString())).toInt() * 1000))}',
                                style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
              Container(
                width: 24.0,
              ),
            ],
          ),
        );
      }

  Widget _photo({@required MainBloc mainBloc, @required String photoURL}) {
    if (photoURL == null || photoURL.isEmpty) {
      return Container(height: 0,);

    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CachedNetworkImage(
          imageUrl: photoURL,
          height: 120.0,
          fit: BoxFit.cover,
          placeholder: (context, imageUrl) {
            return Container(
              height: 120.0,
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            );
          },
        ),
        Container(
          height: 12.0,
        ),
      ],
    );
  }

  Widget _rating({@required BuildContext context}) {
    if (post.value['stars'] == null) {
      return Container(height: 0);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          height: 8.0,
        ),
        Row(
          children: <Widget>[
            SmoothStarRating(
              allowHalfRating: true,
              starCount: 5,
              rating: post.value['stars'] / 2.0 - 0.1,
              size: 16.0,
              color: AppColors.primarySwatch.shade900,
              borderColor: AppColors.primarySwatch.shade900,
            ),
            Container(
              width: 8.0,
            ),
            SingleLineText(
              (post.value['stars'] / 2.0 as double).toStringAsFixed(1),
              style: TextStyle(
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _description() {
    if (post.value['text'] == "" || post.value['text'].toString().isEmpty || post.value['text'] == null) {
      return Container(height: 0,); 
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          height: 12.0,
        ),
        Text(post.value['text']),
      ],
    );
  }

  Widget _tags() {
    if ( post.value['tags'] == null || post.value['tags'] == [] || post.value['tags'].isEmpty) {
      return Container(height: 0);
    }
    List<String> tags = dynamicTagArrayToTagList(post.value['tags']);
    return Container(
      height: 32.0,
      margin: const EdgeInsets.only(top: 12.0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, position) {
          return Container(width: 8.0, height: 1.0);
        },
        itemCount: tags.length,
        itemBuilder: (context, position) {
          return CustomTag(tags.elementAt(position));
        },
      ),
    );
  }

 Widget _likeButton({@required MainBloc mainBloc, @required AppLocalizations localizations}) {
    bool isLiked = post.value['likes'].contains(post.value['iuid']); 
        if (isLiked) {
          return BoldFlatIconButton(
            onPressed: () {
              mainBloc.unlikePostByUser(
                postKey: post?.key.toString(),
                postType: post.value['type'],
                uid: post.value['iuid'],
              );
            },
            icon: Icon(
              Icons.favorite,
              color: Colors.red.shade600,
            ),
            text: localizations.liked.toUpperCase(),
            textColor: AppColors.primarySwatch.shade900,
          );
        } 
        return BoldFlatButton(
          onPressed: () {
            mainBloc.likePostByUser(
              postKey: post?.key.toString(),
              postType: post.value['type'],
                uid: post.value['iuid'],
            );
          },
          text: localizations.like.toUpperCase(),
          textColor: AppColors.primarySwatch.shade900,
        );
        
  }

  @override
  Widget build(BuildContext context) {
    final MainBloc mainBloc = Provider.of<MainBloc>(context);
    final AppLocalizations localizations = AppLocalizations.of(context);
    return GestureDetector(
      key: Key(post.key.toString()),
      behavior: HitTestBehavior.translucent,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PostScreen(
                    uid: uid,
                    post: post,
                  )),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _author(
            authorValue: post.value['profile'],
            localizations: localizations,
            context: context
          ),
          _photo(
            mainBloc: mainBloc,
            photoURL: post.value['photo'],
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  post.value['restaurant']['name'] ?? '', 
                  style: Theme.of(context).textTheme.title,
                ),
                _rating(
                  context: context,
                ),
                _description(),
                _tags(),
              ],
            ),
          ),
          ButtonTheme(
            minWidth: 0.0,
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 6.0,
                horizontal: 6.0,
              ),
              child: Row(
                children: <Widget>[
                  _likeButton(
                    mainBloc: mainBloc,
                    localizations: localizations,
                  ),
                  Container(
                    width: 8.0,
                  ),
                  BoldFlatButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PostScreen(
                                  uid: uid,
                                  post: post,
                                )),
                      );
                    },
                    text: localizations.comment.toUpperCase(),
                    textColor: AppColors.primarySwatch.shade900,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
