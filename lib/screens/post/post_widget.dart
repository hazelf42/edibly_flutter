import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as TimeAgo;

import 'package:edibly/screens/profile/profile_screen.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/screens/post/post_bloc.dart';
import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/values/app_colors.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/models/data.dart';
import 'package:edibly/main_bloc.dart';

class PostCommentsWidget extends StatelessWidget {
  final TextEditingController commentController = TextEditingController();
  final String uid;
  final Data post;

  PostCommentsWidget({@required this.uid, @required this.post});

  Widget _textField(PostBloc postBloc, AppLocalizations localizations) {
    return Container(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: 100.0,
        ),
        child: SingleChildScrollView(
          child: TextField(
            maxLines: null,
            controller: commentController,
            textInputAction: TextInputAction.send,
            onSubmitted: (comment) {
              postBloc.addComment(comment, uid);
            },
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 16.0,
              ),
              border: InputBorder.none,
              hintText: localizations.comment,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SingleLineText(post.value['restaurantName']),
      ),
      body: DisposableProvider<PostBloc>(
        packageBuilder: (context) => PostBloc(post: post),
        child: Builder(
          builder: (context) {
            final PostBloc postBloc = Provider.of<PostBloc>(context);
            final AppLocalizations localizations = AppLocalizations.of(context);
            return Container(
              alignment: Alignment.center,
              child: StreamBuilder<List<Data>>(
                stream: postBloc.comments,
                builder: (context, postsSnapshot) {
                  if (postsSnapshot?.data == null) {
                    postBloc.getComments();
                    return CircularProgressIndicator();
                  }
                  return RefreshIndicator(
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              bottom: 8.0,
                            ),
                            separatorBuilder: (context, position) {
                              if (position == 0) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                    horizontal: 16.0,
                                  ),
                                  child: Text(
                                    localizations.comments,
                                    style: Theme.of(context).textTheme.title,
                                  ),
                                );
                              }
                              return Divider();
                            },
                            itemCount: (postsSnapshot.data == null ? 0 : postsSnapshot.data.length) + 1,
                            itemBuilder: (context, position) {
                              if (position == 0) {
                                return PostWidget(
                                  uid: uid,
                                  post: post,
                                );
                              }
                              if (postsSnapshot.data.elementAt(position - 1) == null) {
                                postBloc.getComments();
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                    horizontal: 16.0,
                                  ),
                                  alignment: Alignment.center,
                                  child: CircularProgressIndicator(),
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                  horizontal: 16.0,
                                ),
                                child: PostCommentWidget(
                                  comment: postsSnapshot.data.elementAt(position - 1),
                                ),
                              );
                            },
                          ),
                        ),
                        Divider(
                          height: 1.0,
                        ),
                        _textField(postBloc, localizations),
                      ],
                    ),
                    onRefresh: () {
                      postBloc.clearComments();
                      postBloc.getComments();
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

class PostCommentWidget extends StatelessWidget {
  final Data comment;

  PostCommentWidget({
    @required this.comment,
  });

  Widget _author({@required MainBloc mainBloc, @required AppLocalizations localizations}) {
    return StreamBuilder<Event>(
      stream: mainBloc.getUser(comment.value['userId'].toString()),
      builder: (context, snapshot) {
        Map<dynamic, dynamic> authorValue = snapshot?.data?.snapshot?.value;
        return Row(
          children: <Widget>[
            CircleAvatar(
              radius: 18.0,
              backgroundImage: authorValue == null ? null : NetworkImage(authorValue['photoUrl']),
              child: authorValue == null
                  ? SizedBox(
                      width: 36.0,
                      height: 36.0,
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
                                      fontSize: 14,
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
                              '${localizations.wroteComment} ${TimeAgo.format(DateTime.fromMillisecondsSinceEpoch((double.parse(comment.value['timeStamp'].toString())).toInt() * 1000))}',
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
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final MainBloc mainBloc = Provider.of<MainBloc>(context);
    final AppLocalizations localizations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _author(
          mainBloc: mainBloc,
          localizations: localizations,
        ),
        Container(
          height: 8.0,
        ),
        Text(comment.value['commentText']),
      ],
    );
  }
}

class PostWidget extends StatelessWidget {
  final String uid;
  final Data post;

  PostWidget({
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
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(uid: post.value['reviewingUserId']),
              ),
            );
          },
          behavior: HitTestBehavior.translucent,
          child: Container(
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
          ),
        );
      },
    );
  }

  Widget _restaurant({@required MainBloc mainBloc, @required AppLocalizations localizations}) {
    return StreamBuilder<Event>(
      stream: mainBloc.getRestaurant(post.value['restaurantKey'].toString()),
      builder: (context, snapshot) {
        Map<dynamic, dynamic> restaurantValue = snapshot?.data?.snapshot?.value;
        if (restaurantValue == null || restaurantValue['address'] == null || restaurantValue['address'].toString().isEmpty) {
          return Container();
        }
        return Container(
          padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 0.0),
          child: Text(
            '${localizations.address}: ${restaurantValue['address']}',
            style: TextStyle(
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      },
    );
  }

  Widget _photo({@required BuildContext context, @required MainBloc mainBloc, @required String photoURL}) {
    if (photoURL == null || photoURL.isEmpty) {
      return Container();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          height: MediaQuery.of(context).size.width,
          child: ClipRect(
            child: PhotoView(
              imageProvider: NetworkImage(photoURL),
              loadingChild: Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              backgroundDecoration: BoxDecoration(color: Colors.black),
              minScale: PhotoViewComputedScale.contained * 1.0,
              maxScale: PhotoViewComputedScale.covered * 4.0,
            ),
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _author(
          mainBloc: mainBloc,
          localizations: localizations,
        ),
        _photo(
          context: context,
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
              _restaurant(
                mainBloc: mainBloc,
                localizations: localizations,
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}
