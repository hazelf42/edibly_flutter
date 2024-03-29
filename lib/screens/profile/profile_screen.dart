import 'dart:convert';

import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/main_bloc.dart';
import 'package:edibly/models/data.dart';
import 'package:edibly/screens/common/full_screen_image.dart';
import 'package:edibly/screens/post/post_preview_widget.dart';
import 'package:edibly/screens/profile/profile_bloc.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  final String uid;

  ProfileScreen({@required this.uid});

  @override
  _ProfileScreen createState() => _ProfileScreen(uid: uid);
}

class _ProfileScreen extends State<ProfileScreen> {
  final String uid;

  _ProfileScreen({@required this.uid});

  Widget _author(
      {@required MainBloc mainBloc, @required AppLocalizations localizations}) {
    return FutureBuilder<http.Response>(
      future: http.get("http://base.edibly.ca/api/profiles/$uid"),
      builder: (context, response) {
        Map<dynamic, dynamic> authorValue =
            (response.hasData) ? json.decode(response?.data?.body) : null;
        return Container(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  String url =
                      (authorValue == null ? null : (authorValue['photo']));
                  if (url == null || url.isEmpty) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FullScreenImageScreen(url)),
                  );
                },
                behavior: HitTestBehavior.translucent,
                child: CircleAvatar(
                  radius: 36.0,
                  backgroundImage: authorValue == null
                      ? null
                      : NetworkImage(authorValue['photo'] ?? ''),
                  child: authorValue == null
                      ? SizedBox(
                          width: 70.0,
                          height: 70.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                          ),
                        )
                      : null,
                ),
              ),
              Container(
                height: 10.0,
              ),
              authorValue == null
                  ? Container()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        SingleLineText(
                          '${authorValue['firstname']} ${authorValue['lastname']}',
                          style: Theme.of(context).textTheme.title,
                        ),
                        SingleLineText(
                          'hello',
                          //'${authorValue['dietName']}${(authorValue['isGlutenFree'] as bool ? ', ${localizations.glutenFree.toLowerCase()}' : '')}',
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ],
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
        title: SingleLineText(localizations.profile),
      ),
      body: DisposableProvider<ProfileBloc>(
        packageBuilder: (context) => ProfileBloc(
          uid: uid,
        ),
        child: Builder(
          builder: (context) {
            final MainBloc mainBloc = Provider.of<MainBloc>(context);
            final ProfileBloc profileBloc = Provider.of<ProfileBloc>(context);
            return FutureBuilder<FirebaseUser>(
              future: mainBloc.getCurrentFirebaseUser(),
              builder: (context, firebaseUserSnapshot) {
                return Container(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? null
                      : Colors.grey.shade300,
                  alignment: Alignment.center,
                  child: StreamBuilder<List<Data>>(
                    stream: profileBloc.posts,
                    builder: (context, postsSnapshot) {
                      if (firebaseUserSnapshot?.data == null ||
                          postsSnapshot?.data == null) {
                        profileBloc.getPosts();
                        return CircularProgressIndicator();
                      }
                      return RefreshIndicator(
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5.0,
                                  horizontal: 6.0,
                                ),
                                shrinkWrap: true,
                                itemCount: postsSnapshot.data.length + 1,
                                itemBuilder: (context, position) {
                                  if (position == 0) {
                                    return Column(
                                      children: <Widget>[
                                        _author(
                                          mainBloc: mainBloc,
                                          localizations: localizations,
                                        ),
                                        (firebaseUserSnapshot == null ||
                                                uid == null)
                                            ? FlatButton(
                                                onPressed: () {},
                                                color: Colors.grey,
                                                child: Text(""))
                                            : ((firebaseUserSnapshot.data.uid ==
                                                    uid)
                                                ? BoldFlatButton(
                                                    text: "Change Photo",
                                                    textColor:
                                                        Colors.deepOrangeAccent,
                                                    onPressed: () async {
                                                      await MainBloc()
                                                          .getCurrentFirebaseUser()
                                                          .then(
                                                              (firebaseUser) async {
                                                        await ProfileBloc(
                                                                uid: uid)
                                                            .getImage(
                                                                firebaseUser)
                                                            .then((_) {
                                                          setState(() {
                                                          });
                                                        });
                                                      });
                                                    })
                                                : FutureBuilder<bool>(
                                                    future: ProfileBloc(
                                                            uid: uid)
                                                        .isFollowing(
                                                            profileUid: uid,
                                                            currentUid:
                                                                firebaseUserSnapshot
                                                                    .data.uid),
                                                    builder: (context, future) {
                                                      if (future.hasData) {
                                                        return BoldFlatButton(
                                                            text: future.data
                                                                ? "Unfollow"
                                                                : "Follow",
                                                            textColor: Colors
                                                                .deepOrangeAccent,
                                                            onPressed:
                                                                () async {
                                                              await ProfileBloc(
                                                                      uid: uid)
                                                                  .followUser(
                                                                      currentUid:
                                                                          firebaseUserSnapshot
                                                                              .data
                                                                              .uid,
                                                                      profileUid:
                                                                          uid,
                                                                      isFollowing:
                                                                          future
                                                                              .data);
                                                              setState(() {});
                                                            });
                                                      }
                                                      return CircularProgressIndicator();
                                                    })),
                                        postsSnapshot.data.isEmpty
                                            ? Column(
                                                children: <Widget>[
                                                  Divider(
                                                    height: 10.0,
                                                  ),
                                                  Container(
                                                    height: 12.0,
                                                  ),
                                                  Icon(
                                                    Icons.warning,
                                                    color: Theme.of(context)
                                                        .hintColor,
                                                    size: 48.0,
                                                  ),
                                                  Container(
                                                    height: 12.0,
                                                  ),
                                                  Text(
                                                    localizations
                                                        .noPostsByUserText,
                                                    style: TextStyle(
                                                      fontSize: 18.0,
                                                      color: Theme.of(context)
                                                          .hintColor,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Container(),
                                      ],
                                    );
                                  }
                                  if (postsSnapshot.data
                                          .elementAt(position - 1) ==
                                      null) {
                                    profileBloc.getPosts();
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
                                        post: postsSnapshot.data
                                            .elementAt(position - 1),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        onRefresh: () {
                          profileBloc.clearPosts();
                          profileBloc.getPosts();
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
      ),
    );
  }

  //TODO: - move to bloc

}
