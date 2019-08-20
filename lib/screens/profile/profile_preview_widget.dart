import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/models/data.dart';
import 'package:edibly/screens/profile/profile_screen.dart';
import 'package:edibly/values/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'search_profile_bloc.dart';

class ProfilePreviewWidget extends StatefulWidget {
  final FirebaseUser firebaseUser;
  final Data profile;

  ProfilePreviewWidget({
    @required this.firebaseUser,
    @required this.profile,
  }) : super(key: Key(profile.key.toString()));

  _ProfilePreviewWidget createState() => _ProfilePreviewWidget(profile: profile, firebaseUser: firebaseUser);
}

class _ProfilePreviewWidget extends State<ProfilePreviewWidget> {
  final FirebaseUser firebaseUser;
  final Data profile;

  _ProfilePreviewWidget({
    @required this.firebaseUser,
    @required this.profile,
  });
  

  Widget _followButton ({@required SearchProfileBloc profileBloc}) {
    return FutureBuilder<bool>(
      future: profileBloc.isFollowing(currentUid: firebaseUser.uid, profileUid: profile.value['uid']),
      builder: (context, isFollowing) {
        bool following = isFollowing.data;
        if (isFollowing.hasData) {
        return IconButton(
          icon: Icon(
            //TODO: Change to person_check
            following ? Icons.check : Icons.person_add,
            color: !following ? AppColors.primarySwatch.shade600 : Theme.of(context).disabledColor,
          ),
          onPressed: () async {
            await profileBloc.followUser(profileUid: profile.value['uid'], currentUid: firebaseUser.uid , isFollowing: isFollowing.data);
            setState(() {
              
            });
          },
        );
      }
      return Container();
      },
    );
  }
  Widget _photo() {
    String url = (profile.value['photo'] ?? '').toString();
    bool hasPhoto = url.isNotEmpty && url.toLowerCase() != 'none';
    if (!hasPhoto) return Container();
    return CustomCircleAvatar(
      radius: 25,
      imagePath: url,
      );
  }

  @override
  Widget build(BuildContext context) {
    final SearchProfileBloc profileBloc = Provider.of<SearchProfileBloc>(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
                  uid: profile.value['uid'],
                ),
          ),
        );
      },
      behavior: HitTestBehavior.translucent,
      child: Card(
        margin: EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(width: 10,),
            _photo(),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(12.0, 8.0, 0.0, 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: 48.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  profile.value['firstname'] +" " + profile.value['lastname'] ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _followButton(profileBloc: profileBloc),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
