import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:edibly/screens/drawer/drawer_screen.dart';
import 'package:edibly/screens/feed/feed_screen.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/values/app_colors.dart';
import 'package:edibly/main_bloc.dart';

// TODO

class HomeScreen extends StatelessWidget {
  final FirebaseUser _firebaseUser;

  HomeScreen(this._firebaseUser);

  @override
  Widget build(BuildContext context) {
    final MainBloc mainBloc = Provider.of<MainBloc>(context);
    final AppLocalizations appLocalizations = AppLocalizations.of(context);
    final bool darkModeEnabled = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<int>(
      stream: mainBloc.bottomNavigationBarCurrentIndex,
      initialData: MainBloc.bottomNavigationBarCurrentIndexDefaultValue,
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              AppLocalizations.of(context).appName,
            ),
          ),
          drawer: DrawerScreen(_firebaseUser),
          body: FeedScreen(),
          bottomNavigationBar: BottomNavigationBar(
            fixedColor: darkModeEnabled ? null : AppColors.primarySwatch.shade700,
            currentIndex: snapshot.data,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                title: Text(appLocalizations.home),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.location_on),
                title: Text(appLocalizations.map),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bookmark),
                title: Text(appLocalizations.bookmarks),
              ),
            ],
            onTap: mainBloc.setBottomNavigationBarCurrentIndex,
          ),
        );
      },
    );
  }
}
