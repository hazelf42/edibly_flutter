import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:edibly/screens/search/restaurant_preview_widget.dart';
import 'package:edibly/screens/search/search_bloc.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/models/data.dart';

class BookmarksScreen extends StatelessWidget {
  final FirebaseUser firebaseUser;

  BookmarksScreen({@required this.firebaseUser});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    return DisposableProvider<SearchBloc>(
      packageBuilder: (context) => SearchBloc(firebaseUser: firebaseUser),
      child: Builder(
        builder: (context) {
          final SearchBloc searchBloc = Provider.of<SearchBloc>(context);
          return Container(
            color: Theme.of(context).brightness == Brightness.dark ? null : Colors.grey.shade300,
            alignment: Alignment.center,
            child: StreamBuilder<List<Data>>(
              stream: searchBloc.bookmarkedRestaurants,
              builder: (context, restaurantsSnapshot) {
                if (restaurantsSnapshot?.data == null) {
                  if (restaurantsSnapshot.connectionState == ConnectionState.waiting) {
                    searchBloc.getBookmarkedRestaurants();
                  }
                  return CircularProgressIndicator();
                }
                return RefreshIndicator(
                  child: restaurantsSnapshot.data.isNotEmpty
                      ? ListView.separated(
                          padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                          separatorBuilder: (context, position) {
                            return Container(height: 10.0);
                          },
                          itemCount: restaurantsSnapshot.data.length,
                          itemBuilder: (context, position) {
                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: 10.0),
                              child: RestaurantPreviewWidget(
                                firebaseUser: firebaseUser,
                                restaurant: restaurantsSnapshot.data.elementAt(position),
                              ),
                            );
                          },
                        )
                      : Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.warning,
                                color: Theme.of(context).hintColor,
                                size: 48.0,
                              ),
                              Container(
                                height: 12.0,
                              ),
                              Text(
                                localizations.noBookmarksFound,
                                style: TextStyle(
                                  fontSize: 18.0,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                  onRefresh: () {
                    searchBloc.getBookmarkedRestaurants();
                    return Future.delayed(Duration(seconds: 1));
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
