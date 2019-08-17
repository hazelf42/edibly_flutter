import 'dart:io';

import 'package:edibly/screens/restaurant/restaurant_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:edibly/screens/new_post/new_post_bloc.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/values/app_colors.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/models/data.dart';

class NewPostDishesScreen extends StatelessWidget {
  final String firebaseUserId;
  final String restaurantName;
  final String restaurantKey;
  final List<String> tags;
  final double rating;
  final String review;
  final File photo;

  NewPostDishesScreen({
    @required this.firebaseUserId,
    @required this.restaurantName,
    @required this.restaurantKey,
    @required this.rating,
    @required this.review,
    @required this.photo,
    @required this.tags,
  });

  _emptyView({
    @required BuildContext context,
    @required AppLocalizations localizations,
  }) {
    return Container(
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
            localizations.nothingHereText,
            style: TextStyle(
              fontSize: 18.0,
              color: Theme.of(context).hintColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  _listView({
    @required List<Data> dishes,
    @required BuildContext context,
    @required AppLocalizations localizations,
  }) {
    if (dishes.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: _emptyView(
            context: context,
            localizations: localizations,
          ),
        ),
      );
    }
    return ListView.separated(
      separatorBuilder: (context, position) {
        return Divider(height: 1.0);
      },
      itemCount: dishes.length,
      itemBuilder: (context, position) {
        return DishWidget(dish: dishes.elementAt(position));
      },
    );
  }

  _tabView({
    @required List<Data> dishes,
    @required String category,
    @required BuildContext context,
    @required NewPostBloc newPostBloc,
    @required AppLocalizations localizations,
  }) {
    final TextEditingController textEditingController = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 8.0),
          child: TextField(
            controller: textEditingController,
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              hintText: localizations.addDish,
            ),
            onSubmitted: (text) {
              if (text == null || text.isEmpty) return;
              textEditingController.clear();
              newPostBloc.addDish(category, text);
            },
          ),
        ),
        Expanded(
          child: _listView(
            dishes: dishes,
            context: context,
            localizations: localizations,
          ),
        ),
      ],
    );
  }

  _loadingView() {
    return Scaffold(
      appBar: AppBar(
        title: SingleLineText(restaurantName),
      ),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  _submit(
      {@required BuildContext context,
      @required NewPostBloc newPostBloc,
      @required AppLocalizations localizations,}) async {
    newPostBloc.setDishes(null);

    String imageUrl;
    if (photo != null) {
      await newPostBloc.getImageUrl(photo: photo).then((fileName) {
        imageUrl = "http://base.edibly.ca/static/uploads/" +
            json.decode(fileName)['filename'];
        newPostBloc
            .submit(
                restaurantName: restaurantName,
                tags: tags,
                rating: rating,
                review: review,
                photoUrl: imageUrl)
            .then((succeeded) {
          if (succeeded) {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => RestaurantScreen(firebaseUserId: firebaseUserId, restaurantKey: restaurantKey)));
          } else {
            Scaffold.of(context).showSnackBar(
                SnackBar(content: Text(localizations.networkRequestFailed)));
            newPostBloc.resetLastDishes();
          }
        });
      });
    } else {
      newPostBloc
          .submit(
              restaurantName: restaurantName,
              tags: tags,
              rating: rating,
              review: review,
              photoUrl: imageUrl)
          .then((succeeded) {
        if (succeeded) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          Navigator.of(context).pop(true);
        } else {
          Scaffold.of(context).showSnackBar(
              SnackBar(content: Text(localizations.networkRequestFailed)));
          newPostBloc.resetLastDishes();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    return DisposableProvider<NewPostBloc>(
      packageBuilder: (context) => NewPostBloc(
        firebaseUserId: firebaseUserId,
        restaurantKey: restaurantKey,
      ),
      child: Builder(
        builder: (context) {
          final NewPostBloc newPostBloc = Provider.of<NewPostBloc>(context);
          return Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? null
                : Colors.grey.shade300,
            alignment: Alignment.center,
            child: StreamBuilder<List<Data>>(
              stream: newPostBloc.dishes,
              builder: (context, dishesSnapshot) {
                if (dishesSnapshot?.data == null) {
                  if (dishesSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    newPostBloc.getDishes();
                  }
                  return _loadingView();
                }
                return DefaultTabController(
                  length: 3,
                  initialIndex: 1,
                  child: Scaffold(
                    appBar: AppBar(
                      title: SingleLineText(localizations.addReview),
                      bottom: PreferredSize(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white),
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 12.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    SingleLineText(
                                      localizations.reviewDishesQuestionText,
                                      style: TextStyle(
                                        fontSize: 18.0,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(height: 4.0),
                                    Text(
                                      localizations.reviewDishesHelpText,
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.white,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Divider(height: 1.0),
                              TabBar(
                                indicatorWeight: 3.0,
                                indicatorColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? null
                                    : Colors.white,
                                tabs: [
                                  Tab(text: localizations.appetizers),
                                  Tab(text: localizations.entrees),
                                  Tab(text: localizations.sides),
                                ],
                              ),
                            ],
                          ),
                          preferredSize: Size.fromHeight(125.0)),
                    ),
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(
                          child: TabBarView(
                            physics: NeverScrollableScrollPhysics(),
                            children: [
                              _tabView(
                                context: context,
                                category: 'a',
                                newPostBloc: newPostBloc,
                                localizations: localizations,
                                dishes: dishesSnapshot.data
                                    .where((d) =>
                                        d.value['categories']
                                            .toString()
                                            .toLowerCase() ==
                                        'a')
                                    .toList(),
                              ),
                              _tabView(
                                context: context,
                                category: 'e',
                                newPostBloc: newPostBloc,
                                localizations: localizations,
                                dishes: dishesSnapshot.data
                                    .where((d) =>
                                        d.value['categories']
                                            .toString()
                                            .toLowerCase() !=
                                        'd' && d.value['categories']
                                            .toString()
                                            .toLowerCase() !=
                                        'a' && d.value['categories']
                                            .toString()
                                            .toLowerCase() !=
                                        's' )
                                    .toList(),
                              ),
                              _tabView(
                                context: context,
                                category: 'd',
                                newPostBloc: newPostBloc,
                                localizations: localizations,
                                dishes: dishesSnapshot.data
                                    .where((d) =>
                                        d.value['categories']
                                            .toString()
                                            .toLowerCase() ==
                                        'd' || d.value['categories']
                                            .toString()
                                            .toLowerCase() ==
                                        's')
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin:
                              const EdgeInsets.fromLTRB(12.0, 16.0, 12.0, 16.0),
                          child: RaisedButton(
                            color: AppColors.primarySwatch.shade400,
                            onPressed: () {
                              _submit(
                                context: context,
                                newPostBloc: newPostBloc,
                                localizations: localizations,
                              );
                            },
                            child: SingleLineText(
                              localizations.next,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class DishWidget extends StatelessWidget {
  final Data dish;

  DishWidget({@required this.dish});

  @override
  Widget build(BuildContext context) {
    final NewPostBloc newPostBloc = Provider.of<NewPostBloc>(context);
    return StreamBuilder<List<Data>>(
      stream: newPostBloc.likedDishes,
      builder: (context, likedDishesSnapshot) {
        return StreamBuilder<List<Data>>(
          stream: newPostBloc.dislikedDishes,
          builder: (context, dislikedDishesSnapshot) {
            bool liked = likedDishesSnapshot?.data != null &&
                likedDishesSnapshot.data
                    .where((d) => d.key == dish.key)
                    .isNotEmpty;
            bool disliked = dislikedDishesSnapshot?.data != null &&
                dislikedDishesSnapshot.data
                    .where((d) => d.key == dish.key)
                    .isNotEmpty;
            return GestureDetector(
              onTap: () {
                newPostBloc.resetDish(dish);
              },
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: liked ? Colors.green : (disliked ? Colors.red : null),
                child: Dismissible(
                  background: Container(color: Colors.green),
                  secondaryBackground: Container(color: Colors.red),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      newPostBloc.likeDish(dish);
                    } else if (direction == DismissDirection.endToStart) {
                      newPostBloc.dislikeDish(dish);
                    }
                    return false;
                  },
                  key: Key(dish.value['did'].toString()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 10.0,
                    ),
                    child: Text(
                      dish.value['name'],
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                        color: liked || disliked ? Colors.white : null,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
