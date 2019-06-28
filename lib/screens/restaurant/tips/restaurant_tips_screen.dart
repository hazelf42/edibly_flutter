import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:edibly/screens/restaurant/tips/restaurant_tips_bloc.dart';
import 'package:edibly/screens/restaurant/restaurant_screen.dart';
import 'package:edibly/screens/restaurant/restaurant_bloc.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/models/data.dart';
import 'package:edibly/main_bloc.dart';
import 'package:http/http.dart';

class RestaurantTipsScreen extends StatelessWidget {
  final String firebaseUserId;
  final String restaurantName;
  final String restaurantKey;

  RestaurantTipsScreen({
    @required this.firebaseUserId,
    @required this.restaurantName,
    @required this.restaurantKey,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: SingleLineText(localizations.tips),
      ),
      body: MultiProvider(
        providers: [
          DisposableProvider<RestaurantBloc>(
              packageBuilder: (context) => RestaurantBloc(firebaseUserId: firebaseUserId, restaurantKey: restaurantKey)),
          DisposableProvider<RestaurantTipsBloc>(packageBuilder: (context) => RestaurantTipsBloc(restaurantKey: restaurantKey)),
        ],
        child: Builder(
          builder: (context) {
            final RestaurantBloc restaurantBloc = Provider.of<RestaurantBloc>(context);
            final RestaurantTipsBloc restaurantTipsBloc = Provider.of<RestaurantTipsBloc>(context);
            return Container(
              color: Theme.of(context).brightness == Brightness.dark ? null : Colors.grey.shade300,
              alignment: Alignment.center,
              child: StreamBuilder<List<Data>>(
                stream: restaurantTipsBloc.tips,
                builder: (context, tipsSnapshot) {
                  if (tipsSnapshot?.data == null) {
                    if (tipsSnapshot.connectionState == ConnectionState.waiting) {
                      restaurantTipsBloc.getTips();
                    }
                    return CircularProgressIndicator();
                  }
                  if (tipsSnapshot.data.isEmpty) {
                    return Center(
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
                            localizations.noTipsText,
                            style: TextStyle(
                              fontSize: 18.0,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          Container(
                            height: 12.0,
                          ),
                          RaisedButton(
                            onPressed: () {
                              RestaurantScreen.showAddTipDialog(
                                context: context,
                                restaurantBloc: restaurantBloc,
                                localizations: localizations,
                                restaurantName: restaurantName,
                              ).then((added) {
                                restaurantTipsBloc.clearTips();
                                restaurantTipsBloc.getTips();
                              });
                            },
                            child: SingleLineText(localizations.addTip.toUpperCase()),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    child: ListView.separated(
                      separatorBuilder: (context, position) {
                        return Divider();
                      },
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 6.0,
                      ),
                      itemCount: tipsSnapshot.data.length,
                      itemBuilder: (context, position) {
                        if (tipsSnapshot.data.elementAt(position) == null) {
                          restaurantTipsBloc.getTips();
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
                          child: TipWidget(
                            tip: tipsSnapshot.data.elementAt(position),
                          ),
                        );
                      },
                    ),
                    onRefresh: () {
                      restaurantTipsBloc.clearTips();
                      restaurantTipsBloc.getTips();
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

class TipWidget extends StatelessWidget {
  final Data tip;

  TipWidget({@required this.tip});

  @override
  Widget build(BuildContext context) {
    final MainBloc mainBloc = Provider.of<MainBloc>(context);
    final AppLocalizations localizations = AppLocalizations.of(context);
    
    return FutureBuilder<Response>(
      future: mainBloc.getUser(tip.value['tipUserId'].toString()),
      builder: (context, response) {
        final userMap = json.decode(response.data.body);
        Map<dynamic, dynamic> authorValue = userMap;
        return Row(
          children: <Widget>[
            CircleAvatar(
              radius: 18.0,
              backgroundImage: authorValue == null ? null : NetworkImage(authorValue['photoUrl'] ?? authorValue['photoURL'] ?? ''),
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
                                    '${authorValue['firstname']} ${authorValue['lastName']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SingleLineText(
                                    ' (${authorValue['dietName']}${(authorValue['isGlutenFree'] as bool ? ', ${localizations.glutenFree.toLowerCase()}' : '')})',
                                    style: TextStyle(
                                      color: Theme.of(context).hintColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(height: 6.0),
                            Text(tip.value['description']),
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
}
