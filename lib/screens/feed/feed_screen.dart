import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as TimeAgo;

import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/screens/feed/feed_bloc.dart';
import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/values/app_colors.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/main_bloc.dart';

class FeedScreen extends StatelessWidget {
  Widget _authorInfo({
    @required MainBloc bloc,
    @required dynamic postInfo,
    @required AppLocalizations localizations,
  }) {
    return StreamBuilder<Event>(
      stream: bloc.getUserInfo(postInfo['reviewingUserId'].toString()),
      builder: (context, snapshot) {
        Map<dynamic, dynamic> map = snapshot?.data?.snapshot?.value;
        return Container(
          padding: EdgeInsets.fromLTRB(16.0, 12.0, 0.0, 12.0),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 24.0,
                backgroundImage: map == null ? null : NetworkImage(map['photoUrl']),
                child: map == null
                    ? SizedBox(
                        width: 46.0,
                        height: 46.0,
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    map == null
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
                                      '${map['firstName']} ${map['lastName']}',
                                      style: Theme.of(context).textTheme.body1.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    SingleLineText(
                                      ' (${map['dietName']})',
                                      style: Theme.of(context).textTheme.body1.copyWith(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).hintColor,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 4.0,
                              ),
                              SingleLineText(
                                '${postInfo['postType'] == 0 ? localizations.wroteReview : localizations.addedTip} ${TimeAgo.format(DateTime.fromMillisecondsSinceEpoch((postInfo['timeStamp'] as double).toInt() * 1000))}',
                                style: Theme.of(context).textTheme.body1.copyWith(
                                      fontSize: 12,
                                      color: Theme.of(context).hintColor,
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
      },
    );
  }

  Widget _photo(MainBloc mainBloc, String photoURL) {
    if (photoURL != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Image.network(
            photoURL,
            height: 120.0,
            fit: BoxFit.cover,
          ),
          Container(
            height: 12.0,
          ),
        ],
      );
    } else {
      return Container();
    }
  }

  List<String> dynamicToStrings(dynamic value) {
    List<String> strings = [];
    if (value != null) for (var item in value) strings.add(item.toString());
    return strings;
  }

  @override
  Widget build(BuildContext context) {
    return DisposableProvider<FeedBloc>(
      packageBuilder: (context) => FeedBloc(),
      child: Builder(
        builder: (context) {
          final MainBloc mainBloc = Provider.of<MainBloc>(context);
          final FeedBloc feedBloc = Provider.of<FeedBloc>(context);
          final AppLocalizations localizations = AppLocalizations.of(context);
          return FutureBuilder<FirebaseUser>(
            future: mainBloc.getCurrentUser(),
            builder: (context, firebaseUserSnapshot) {
              return Container(
                color: Theme.of(context).brightness == Brightness.dark ? null : Colors.grey.shade300,
                alignment: Alignment.center,
                child: StreamBuilder<List<Post>>(
                  stream: feedBloc.posts,
                  builder: (context, postsSnapshot) {
                    if (postsSnapshot?.data == null || postsSnapshot.data.isEmpty) {
                      feedBloc.getPosts();
                      return CircularProgressIndicator();
                    }
                    return RefreshIndicator(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          vertical: 3.0,
                          horizontal: 6.0,
                        ),
                        itemCount: postsSnapshot.data.length,
                        itemBuilder: (context, position) {
                          if (postsSnapshot.data.elementAt(position) == null) {
                            feedBloc.getPosts();
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
                            key: Key(postsSnapshot.data.elementAt(position).key),
                            margin: const EdgeInsets.symmetric(
                              vertical: 3.0,
                            ),
                            child: Card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  _authorInfo(
                                    bloc: mainBloc,
                                    postInfo: postsSnapshot.data.elementAt(position).value,
                                    localizations: localizations,
                                  ),
                                  _photo(mainBloc, postsSnapshot.data.elementAt(position).value['imageUrl']),
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          postsSnapshot.data.elementAt(position).value['restaurantName'],
                                          style: Theme.of(context).textTheme.title,
                                        ),
                                        postsSnapshot.data.elementAt(position).value['numRating'] == null
                                            ? Container()
                                            : Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Container(
                                                    height: 8.0,
                                                  ),
                                                  Row(
                                                    children: <Widget>[
                                                      SmoothStarRating(
                                                        allowHalfRating: true,
                                                        starCount: 10,
                                                        rating: postsSnapshot.data.elementAt(position).value['numRating'] / 1.0,
                                                        size: 16.0,
                                                        color: AppColors.primarySwatch.shade900,
                                                        borderColor: AppColors.primarySwatch.shade900,
                                                      ),
                                                      Container(
                                                        width: 8.0,
                                                      ),
                                                      SingleLineText(
                                                        postsSnapshot.data.elementAt(position).value['numRating'].toString(),
                                                        style: TextStyle(
                                                          color: Theme.of(context).hintColor,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                ],
                                              ),
                                        postsSnapshot.data.elementAt(position).value['description'] == null
                                            ? Container()
                                            : Column(
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: <Widget>[
                                                  Container(
                                                    height: 12.0,
                                                  ),
                                                  Text(postsSnapshot.data.elementAt(position).value['description']),
                                                ],
                                              ),
                                        postsSnapshot.data.elementAt(position).value['tagArray'] == null
                                            ? Container()
                                            : Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Container(
                                                    height: 12.0,
                                                  ),
                                                  Wrap(
                                                    spacing: 8.0,
                                                    runSpacing: 8.0,
                                                    children: dynamicToStrings(postsSnapshot.data.elementAt(position).value['tagArray'])
                                                        .map((tag) {
                                                      return Chip(
                                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                        label: SingleLineText(tag),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ],
                                              ),
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
                                          StreamBuilder<Event>(
                                            stream: feedBloc.isPostLikedByUser(
                                                postsSnapshot.data.elementAt(position).key?.toString(), firebaseUserSnapshot?.data?.uid),
                                            builder: (context, snapshot) {
                                              if (snapshot?.data?.snapshot?.value == 1) {
                                                return BoldFlatIconButton(
                                                  onPressed: () {
                                                    feedBloc.unlikePostByUser(
                                                      postsSnapshot.data.elementAt(position)?.key.toString(),
                                                      firebaseUserSnapshot?.data?.uid,
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
                                                  feedBloc.likePostByUser(
                                                    postsSnapshot.data.elementAt(position)?.key.toString(),
                                                    firebaseUserSnapshot?.data?.uid,
                                                  );
                                                },
                                                text: localizations.like.toUpperCase(),
                                                textColor: AppColors.primarySwatch.shade900,
                                              );
                                            },
                                          ),
                                          Container(
                                            width: 8.0,
                                          ),
                                          BoldFlatButton(
                                            onPressed: () {},
                                            text: localizations.comment.toUpperCase(),
                                            textColor: AppColors.primarySwatch.shade900,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      onRefresh: () {
                        feedBloc.clearPosts();
                        feedBloc.getPosts();
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
