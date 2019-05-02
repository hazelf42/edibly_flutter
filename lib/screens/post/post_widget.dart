import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as TimeAgo;

import 'package:edibly/screens/post/post_preview_widget.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/screens/post/post_bloc.dart';
import 'package:edibly/bloc_helper/provider.dart';
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
                                return PostPreviewWidget(
                                  uid: uid,
                                  post: post,
                                  clickable: false,
                                  showCommentButton: false,
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
                                    ' (${authorValue['dietName']})',
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
                              '${localizations.wroteComment} ${TimeAgo.format(DateTime.fromMillisecondsSinceEpoch((comment.value['timeStamp']).toInt() * 1000))}',
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
