import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:edibly/screens/post/post_widget.dart';
import 'package:edibly/screens/feed/feed_bloc.dart';
import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/screens/post/post.dart';
import 'package:edibly/main_bloc.dart';

class FeedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DisposableProvider<FeedBloc>(
      packageBuilder: (context) => FeedBloc(),
      child: Builder(
        builder: (context) {
          final MainBloc mainBloc = Provider.of<MainBloc>(context);
          final FeedBloc feedBloc = Provider.of<FeedBloc>(context);
          return FutureBuilder<FirebaseUser>(
            future: mainBloc.getCurrentFirebaseUser(),
            builder: (context, firebaseUserSnapshot) {
              return Container(
                color: Theme.of(context).brightness == Brightness.dark ? null : Colors.grey.shade300,
                alignment: Alignment.center,
                child: StreamBuilder<List<Post>>(
                  stream: feedBloc.posts,
                  builder: (context, postsSnapshot) {
                    if (firebaseUserSnapshot?.data == null || postsSnapshot?.data == null || postsSnapshot.data.isEmpty) {
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
                          return PostWidget(
                            uid: firebaseUserSnapshot?.data?.uid,
                            post: postsSnapshot.data.elementAt(position),
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
