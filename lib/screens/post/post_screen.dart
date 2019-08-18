import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/main_bloc.dart';
import 'package:edibly/models/data.dart';
import 'package:edibly/screens/common/full_screen_image.dart';
import 'package:edibly/screens/post/post_bloc.dart';
import 'package:edibly/screens/profile/profile_screen.dart';
import 'package:edibly/screens/restaurant/restaurant_screen.dart';
import 'package:edibly/values/app_colors.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:timeago/timeago.dart' as TimeAgo;

class PostScreen extends StatelessWidget {
  final TextEditingController commentController = TextEditingController();
  final String uid;
  final Data post;

  PostScreen({@required this.uid, @required this.post});

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
        title: SingleLineText(post.value['restaurant']['name'] ?? ''),
      ),
      body: DisposableProvider<PostBloc>(
        packageBuilder: (context) => PostBloc(post: post),
        child: Builder(
          builder: (context) {
            final PostBloc postBloc = Provider.of<PostBloc>(context);
            final AppLocalizations localizations = AppLocalizations.of(context);
            return Container(
                alignment: Alignment.center,
                child: StreamBuilder<List<dynamic>>(
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
                                        style:
                                            Theme.of(context).textTheme.title,
                                      ),
                                    );
                                  }
                                  return Divider();
                                },
                                itemCount: (postsSnapshot.data == null
                                        ? 0
                                        : postsSnapshot.data.length) +
                                    1,
                                itemBuilder: (context, position) {
                                  if (position == 0) {
                                    return PostWidget(
                                      uid: uid,
                                      post: post,
                                    );
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                      horizontal: 16.0,
                                    ),
                                    child: PostCommentWidget(
                                      comment: post.value['comments']
                                          .elementAt(position - 1),
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
                        },
                      );
                    }));
          },
        ),
      ),
    );
  }
}

class PostCommentWidget extends StatelessWidget {
  final Map comment;

  PostCommentWidget({
    @required this.comment,
  });

  Widget _author(
      {@required MainBloc mainBloc,
      @required AppLocalizations localizations,
      @required BuildContext context}) {
    final authorValue = comment['profile'];
    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 18.0,
          backgroundImage: (authorValue == null ||
                  authorValue['photo'] == null ||
                  authorValue['photo'] == "None")
              ? null
              : NetworkImage(authorValue['photo']),
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
                                '${authorValue['firstname']} ${authorValue['lastname']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              //   SingleLineText(
                              //       ' (${authorValue['dietName']}${(authorValue['isGlutenFree'] as bool ? ', ${localizations.glutenFree.toLowerCase()}' : '')})',
                              // style: TextStyle(
                              //     color: Theme.of(context).hintColor,
                              // fontSize: 14,
                              // fontWeight: FontWeight.w600,
                              //),
                              //),
                            ],
                          ),
                        ),
                        Container(
                          height: 4.0,
                        ),
                        SingleLineText(
                          (comment['timestamp'] != null)
                              ? '${TimeAgo.format(DateTime.fromMillisecondsSinceEpoch((double.parse(comment['timestamp'].toString())).toInt() * 1000))}'
                              : "Now",
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
  }

  @override
  Widget build(BuildContext context) {
    final MainBloc mainBloc = Provider.of<MainBloc>(context);
    final AppLocalizations localizations = AppLocalizations.of(context);
    return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(
                uid: comment['profile']['uid'],
              ),
            ),
          );
        },
        behavior: HitTestBehavior.translucent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _author(
                mainBloc: mainBloc,
                localizations: localizations,
                context: context),
            Container(
              height: 8.0,
            ),
            Text(comment['comment']),
          ],
        ));
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

  void _delete(
      {@required BuildContext context,
      @required MainBloc mainBloc,
      @required AppLocalizations localizations}) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: SingleLineText(localizations.delete),
          content: Text(localizations.deleteConfirmationText),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
          actions: <Widget>[
            FlatButton(
              child: Text(localizations.cancel.toUpperCase()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text(localizations.delete.toUpperCase()),
              onPressed: () {
                mainBloc.deletePost(
                  post: post,
                  firebaseUserId: uid,
                );
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _deleteButton(
      {@required BuildContext context,
      @required MainBloc mainBloc,
      @required AppLocalizations localizations}) {
    if (uid != post.value['uid']) {
      return Container();
    } else {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12.0),
        child: BoldFlatButton(
          onPressed: () {
            _delete(
              context: context,
              mainBloc: mainBloc,
              localizations: localizations,
            );
          },
          text: localizations.delete.toUpperCase(),
          textColor: Colors.red.shade600,
        ),
      );
    }
  }

  Widget _author(
      {@required MainBloc mainBloc, @required AppLocalizations localizations}) {
    return FutureBuilder<http.Response>(
      future: http.get(
          "http://base.edibly.ca/api/profiles/${post.value['profile']['uid'].toString()}"),
      builder: (context, response) {
        Map<dynamic, dynamic> authorValue = post.value['profile'];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProfileScreen(uid: post.value['profile']['uid']),
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
                  backgroundImage: authorValue == null
                      ? null
                      : NetworkImage(authorValue['photo'] ?? ''),
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
                                        '${authorValue['firstname']} ${authorValue['lastname']}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SingleLineText(
                                        "Hello",
                                        // ' (${authorValue['dietName']}${(authorValue['isGlutenFree'] as bool ? ', ${localizations.glutenFree.toLowerCase()}' : '')})',
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
                                  '${post.value['postType'] == 0 ? localizations.wroteReview : localizations.addedTip} ${TimeAgo.format(DateTime.fromMillisecondsSinceEpoch((double.parse(post.value['timestamp'].toString())).toInt() * 1000))}',
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

  Widget _restaurant(
      {@required MainBloc mainBloc, @required AppLocalizations localizations}) {
    Map<dynamic, dynamic> restaurantValue = post.value['restaurant'];
    print(restaurantValue);
    if (restaurantValue == null ||
        (restaurantValue['address'] ??
                restaurantValue['address1'] ??
                restaurantValue['address2']) ==
            null ||
        (restaurantValue['address'] ??
                restaurantValue['address1'] ??
                restaurantValue['address2'])
            .toString()
            .isEmpty) {
      return Container();
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 0.0),
      child: Text(
        '${localizations.address}: ${(restaurantValue['address'] ?? restaurantValue['address1'] ?? restaurantValue['address2'])}',
        style: TextStyle(
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _photo(
      {@required BuildContext context,
      @required MainBloc mainBloc,
      @required String photoURL}) {
    if (photoURL == null || photoURL.isEmpty || photoURL == "None") {
      return Container();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        GestureDetector(
          onTap: () {
            if (photoURL == null || photoURL.isEmpty) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => FullScreenImageScreen(photoURL)),
            );
          },
          behavior: HitTestBehavior.translucent,
          child: Container(
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
        ),
        Container(
          height: 12.0,
        ),
      ],
    );
  }

  Widget _rating({@required BuildContext context}) {
    if (post.value['stars'] == null) {
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
    if (post.value['text'] == null || post.value['text'].toString().isEmpty) {
      return Container();
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
    if (post.value['tags'] == null ||
        post.value['tags'] == [] ||
        post.value['tags'].isEmpty) {
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

  Widget _likeButton(
      {@required MainBloc mainBloc, @required AppLocalizations localizations}) {
    bool isLiked = post.value['likes'].contains(uid);
    if (isLiked) {
      return BoldFlatIconButton(
        onPressed: () {
          mainBloc.unlikePostByUser(
            postKey: post?.key.toString(),
            postType: post.value['type'],
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
          postType: post.value['type'],
          uid: uid,
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
          photoURL: post.value['photo'],
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RestaurantScreen(
                        firebaseUserId: uid,
                        restaurantKey: post.value['rid'].toString(),
                      ),
                    ),
                  );
                },
                behavior: HitTestBehavior.translucent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      post.value['restaurant']['name'] ?? '',
                      style: Theme.of(context).textTheme.title,
                    ),
                    _restaurant(
                      mainBloc: mainBloc,
                      localizations: localizations,
                    ),
                    _rating(
                      context: context,
                    ),
                  ],
                ),
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
                _deleteButton(
                  context: context,
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
