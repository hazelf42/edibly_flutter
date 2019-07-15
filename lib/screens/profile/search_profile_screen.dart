import 'dart:async';

import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/models/data.dart';
import 'profile_preview_widget.dart';
import 'package:edibly/screens/profile/search_profile_bloc.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SearchProfileScreen extends StatelessWidget {
  final FirebaseUser firebaseUser;

  SearchProfileScreen({@required this.firebaseUser});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);

    return Scaffold(
        body: SafeArea(
            child: DisposableProvider<SearchProfileBloc>(
                packageBuilder: (context) =>
                    SearchProfileBloc(firebaseUser: firebaseUser),
                child: Builder(builder: (context) {
                  final SearchProfileBloc searchProfileBloc =
                      Provider.of<SearchProfileBloc>(context);
                  return Container(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? null
                        : Colors.grey.shade300,
                    alignment: Alignment.center,
                    child: StreamBuilder<List<Data>>(
                      stream: searchProfileBloc.profiles,
                      initialData: null,
                      builder: (context, filteredRestaurantsSnapshot) {
                        bool filteredRestaurantsValueIsNull =
                            filteredRestaurantsSnapshot?.data == null;
                        int listViewItemCount = (filteredRestaurantsValueIsNull
                                ? 0
                                : filteredRestaurantsSnapshot.data.length) +
                            1;
                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          separatorBuilder: (context, position) {
                            return Container(height: 10.0);
                          },
                          itemCount: listViewItemCount == 1 ? 2 : listViewItemCount-1,
                          itemBuilder: (context, position) {
                            return Column(
                              children: <Widget>[
                                Builder(builder: (context) {
                                  if (position == 0) { 
                                    
 return                                Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: TextField(
                                          autofocus: true,
                                          onChanged: (keyword) { 
                                            searchProfileBloc.autocomplete(keyword);
                                          },
                                          onSubmitted: (keyword) {
                                            searchProfileBloc
                                                .filterRestaurants(keyword);
                                          },
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            isDense: true,
                                            hintText: "Search by name",
                                            labelText: localizations.search,
                                            prefixIcon: Icon(Icons.search),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                  }
                                  else if (listViewItemCount == 1 &&
                                      filteredRestaurantsValueIsNull) {
                                    return Container(
                                      margin: const EdgeInsets.all(24.0),
                                      child: CircularProgressIndicator(),
                                    );} else if (filteredRestaurantsSnapshot.hasData && filteredRestaurantsSnapshot.data.length > 0) {
                                    listViewItemCount++; 
                                    return Container(
                                      margin: EdgeInsets.symmetric(
                                          horizontal: 10.0),
                                      child: ProfilePreviewWidget(
                                        firebaseUser: firebaseUser,
                                        profile: filteredRestaurantsSnapshot
                                            .data
                                            .elementAt(position - 1),
                                      ),
                                    );
                                  }
                                  return Container();
                                }),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  );
                }))));
  }
}
