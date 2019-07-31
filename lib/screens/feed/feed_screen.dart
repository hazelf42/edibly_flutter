import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/main_bloc.dart';
import 'package:edibly/models/data.dart';
import 'package:edibly/screens/feed/feed_bloc.dart';
import 'package:edibly/screens/post/post_preview_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edibly/screens/profile/search_profile_screen.dart';

class FeedScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        initialIndex: 1,
        child: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(50.0), // here the desired height
              child: TabBar(
                indicatorWeight: 3.0,
                indicatorColor: Theme.of(context).brightness == Brightness.dark
                    ? null
                    : Colors.deepOrange,
                tabs: [
                  Tab(
                      child: (Stack(
                    alignment: Alignment.centerLeft,
                    children: <Widget>[
                      Icon(
                        Icons.near_me,
                        color: Colors.deepOrange,
                      ),
                      Text("        Nearby",
                          style: TextStyle(color: Colors.deepOrange))
                    ],
                  ))),
                  Tab(
                      child: (Stack(
                    fit: StackFit.loose,
                    alignment: Alignment.centerLeft,
                    children: <Widget>[
                      Icon(Icons.person_pin, color: Colors.deepOrange),
                      Text("        Following",
                          style: TextStyle(color: Colors.deepOrange))
                    ],
                  ))),
                ],
              ),
            ),
            body: TabBarView(children: [
              feedScreenBody(context, 'nearby'),
              feedScreenBody(context, 'following')
            ])));
  }
}

Widget feedScreenBody(BuildContext context, String feedType) {
  return DisposableProvider<FeedBloc>(
    packageBuilder: (context) => FeedBloc(feedType: feedType),
    child: Builder(
      builder: (context) {
        final MainBloc mainBloc = Provider.of<MainBloc>(context);
        final FeedBloc feedBloc = Provider.of<FeedBloc>(context);
        return FutureBuilder<FirebaseUser>(
          future: mainBloc.getCurrentFirebaseUser(),
          builder: (context, firebaseUserSnapshot) {
            return Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? null
                  : Colors.grey.shade300,
              alignment: Alignment.center,
              child: StreamBuilder<List<Data>>(
                stream: feedBloc.posts,
                builder: (context, postsSnapshot) {
                  if (firebaseUserSnapshot?.data == null || !postsSnapshot.hasData) {
                    feedBloc.getPosts(feedType);
                    return CircularProgressIndicator();
                  }
                  if ((postsSnapshot.hasData && postsSnapshot.data.length == 0)) {
                    return Center(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        RaisedButton(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).cardColor
                                    : Colors.white,
                            child: Text("Find people to follow"),
                            onPressed: (() {
                              
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchProfileScreen(
                                firebaseUser: firebaseUserSnapshot.data,
                              ),
                            ));
                            })),
                        Text("OR"),
                        RaisedButton(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).cardColor
                                    : Colors.white,
                            child: Text("See nearby"),
                            onPressed: (() {
                              feedBloc.clearPosts();
                              feedBloc.getPosts('nearby'); 
                              //TODO: - change this to also highlight the nearby tab - pref without making stateful :')
                            })),
                      ],
                    ));
                  }
                  return RefreshIndicator(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: 5.0,
                        horizontal: 6.0,
                      ),
                      itemCount: postsSnapshot.data.length,
                      itemBuilder: (context, position) {
                        if (postsSnapshot.data.elementAt(position) == null) {
                          feedBloc.getPosts(feedType);
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
                          margin: const EdgeInsets.symmetric(
                            vertical: 5.0,
                            horizontal: 4.0,
                          ),
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: PostPreviewWidget(
                              uid: firebaseUserSnapshot?.data?.uid,
                              post: postsSnapshot.data.elementAt(position),
                            ),
                          ),
                        );
                      },
                    ),
                    onRefresh: () {
                      feedBloc.clearPosts();
                      feedBloc.getPosts(feedType);
                      return Future.delayed(Duration(seconds: 1));
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
