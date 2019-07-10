import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:edibly/screens/search/bookmarks/bookmarks_screen.dart';
import 'package:edibly/screens/discover/discover_screen.dart';
import 'package:edibly/screens/drawer/drawer_screen.dart';
import 'package:edibly/screens/search/search_screen.dart';
import 'package:edibly/screens/feed/feed_screen.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/values/app_colors.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/main_bloc.dart';

class HomeScreen extends StatelessWidget {
  final FirebaseUser firebaseUser;

  HomeScreen({@required this.firebaseUser});

  Widget _body(int bottomNavigationCurrentIndex) {
    switch (bottomNavigationCurrentIndex) {
      case 0:
        return FeedScreen();
      case 1:
        return DiscoverScreen(firebaseUser: firebaseUser);
      case 2:
        return SearchScreen(
          firebaseUser: firebaseUser,
        );
      default: // case 2
        return BookmarksScreen(firebaseUser: firebaseUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MainBloc mainBloc = Provider.of<MainBloc>(context);
    final AppLocalizations localizations = AppLocalizations.of(context);
    final bool darkModeEnabled =
        Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<int>(
      stream: mainBloc.bottomNavigationBarCurrentIndex,
      initialData: MainBloc.bottomNavigationBarCurrentIndexDefaultValue,
      builder: (context, snapshot) {
        return Scaffold(
          drawer: DrawerScreen(firebaseUser),
          body: NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  PreferredSize(
                   preferredSize: Size.fromHeight(10.0), child:// here the desired height
                  SliverAppBar(
                    expandedHeight: 10.0,
                    floating: true,
                    flexibleSpace: FlexibleSpaceBar(
                        centerTitle: true,
                        title: Text("Edibly",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                            )),
                  )))];
              },
              body: _body(snapshot?.data)),
          bottomNavigationBar: BottomNavigationBar(
            fixedColor:
                darkModeEnabled ? null : AppColors.primarySwatch.shade700,
            currentIndex: snapshot.data,
            unselectedItemColor: Colors.grey,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                title: SingleLineText(localizations.home),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.location_on),
                title: SingleLineText(localizations.discover),
              ),
              BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  //TODO: Localization
                  title: SingleLineText("Search")),
              BottomNavigationBarItem(
                icon: Icon(Icons.bookmark),
                title: SingleLineText(localizations.bookmarks),
              ),
            ],
            onTap: mainBloc.setBottomNavigationBarCurrentIndex,
          ),
        );
      },
    );
  }
}
