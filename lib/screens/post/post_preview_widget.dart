import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as TimeAgo;

import 'package:edibly/screens/post/post_widget.dart';
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

  Widget _author({@required MainBloc mainBloc, @required AppLocalizations localizations}) {
    return StreamBuilder<Event>(
      stream: mainBloc.getUser(post.value['reviewingUserId'].toString()),
      builder: (context, snapshot) {
        Map<dynamic, dynamic> authorValue = snapshot?.data?.snapshot?.value;
        return Container(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 0.0, 12.0),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 24.0,
                backgroundImage: authorValue == null ? null : NetworkImage(authorValue['photoUrl']),
                child: authorValue == null
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
                    authorValue == null
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SingleLineText(
                                      ' (${authorValue['dietName']}${(authorValue['isGlutenFree'] as bool ? ', ${localizations.glutenFree.toLowerCase()}' : '')})',
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
                                '${post.value['postType'] == 0 ? localizations.wroteReview : localizations.addedTip} ${TimeAgo.format(DateTime.fromMillisecondsSinceEpoch((double.parse(post.value['timeStamp'].toString())).toInt() * 1000))}',
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
      },
    );
  }

  Widget _photo({@required MainBloc mainBloc, @required String photoURL}) {
    if (photoURL == null || photoURL.isEmpty) {
      return Container();
    }
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
  }

  Widget _rating({@required BuildContext context}) {
    if (post.value['numRating'] == null) {
      return Container();
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
              starCount: 10,
              rating: post.value['numRating'] / 1.0,
              size: 16.0,
              color: AppColors.primarySwatch.shade900,
              borderColor: AppColors.primarySwatch.shade900,
            ),
            Container(
              width: 8.0,
            ),
            SingleLineText(
              post.value['numRating'].toString(),
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
    if (post.value['description'] == null || post.value['description'].toString().isEmpty) {
      return Container();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          height: 12.0,
        ),
        Text(post.value['description']),
      ],
    );
  }

  Widget _tags() {
    if (post.value['tagArray'] == null || post.value['tagArray'].toString().isEmpty) {
      return Container();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          height: 12.0,
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: dynamicTagArrayToTagList(post.value['tagArray']).map((tag) {
            return Chip(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              label: SingleLineText(tag),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _likeButton({@required MainBloc mainBloc, @required AppLocalizations localizations}) {
    return StreamBuilder<Event>(
      stream: mainBloc.isPostLikedByUser(
        postKey: post.key?.toString(),
        uid: uid,
      ),
      builder: (context, snapshot) {
        if (snapshot?.data?.snapshot?.value == 1) {
          return BoldFlatIconButton(
            onPressed: () {
              mainBloc.unlikePostByUser(
                postKey: post?.key.toString(),
                uid: uid,
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
              uid: uid,
            );
          },
          text: localizations.like.toUpperCase(),
          textColor: AppColors.primarySwatch.shade900,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final MainBloc mainBloc = Provider.of<MainBloc>(context);
    final AppLocalizations localizations = AppLocalizations.of(context);
    return GestureDetector(
      key: Key(post.key),
      behavior: HitTestBehavior.translucent,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PostCommentsWidget(
                    uid: uid,
                    post: post,
                  )),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _author(
            mainBloc: mainBloc,
            localizations: localizations,
          ),
          _photo(
            mainBloc: mainBloc,
            photoURL: post.value['imageUrl'],
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  post.value['restaurantName'],
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
    );
  }
}
