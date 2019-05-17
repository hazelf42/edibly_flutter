import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:flutter/material.dart';

import 'package:edibly/screens/restaurant/dishes/restaurant_dishes_bloc.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/values/app_colors.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/models/data.dart';
import 'package:edibly/main_bloc.dart';

class RestaurantDishesScreen extends StatelessWidget {
  final String restaurantName;
  final String restaurantKey;

  RestaurantDishesScreen({
    @required this.restaurantName,
    @required this.restaurantKey,
  });

  _emptyView({
    @required Diet diet,
    @required BuildContext context,
    @required AppLocalizations localizations,
    @required RestaurantDishesBloc restaurantDishesBloc,
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
          Container(
            height: 12.0,
          ),
          Text(
            diet == Diet.VEGAN ? localizations.noVeganOptionsText : localizations.noVegetarianOptionsText,
            style: TextStyle(
              fontSize: 15.0,
              color: Theme.of(context).hintColor,
            ),
            textAlign: TextAlign.center,
          ),
          diet == Diet.VEGAN
              ? Container(
                  margin: const EdgeInsets.only(top: 12.0),
                  child: FlatButton(
                    onPressed: () {
                      restaurantDishesBloc.setForcedDiet(Diet.VEGETARIAN);
                    },
                    child: SingleLineText(localizations.showVegetarianOptions.toUpperCase()),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }

  _dietToConstantString(Diet diet) {
    switch (diet) {
      case Diet.VEGAN:
        return 'vegan';
      case Diet.VEGETARIAN:
        return 'vegetarian';
    }
  }

  _listView({
    @required Diet diet,
    @required List<Data> dishes,
    @required BuildContext context,
    @required AppLocalizations localizations,
    @required RestaurantDishesBloc restaurantDishesBloc,
  }) {
    if (dishes.isEmpty) {
      return _emptyView(
        diet: diet,
        context: context,
        localizations: localizations,
        restaurantDishesBloc: restaurantDishesBloc,
      );
    }
    return ListView.separated(
      separatorBuilder: (context, position) {
        if (position == 0) {
          return Container(
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 10.0,
            ),
            margin: const EdgeInsets.only(bottom: 8.0),
            child: SingleLineText(
              diet == Diet.VEGAN ? localizations.vegan : localizations.vegetarian,
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          );
        } else if (dishes.elementAt(position - 1).value[_dietToConstantString(diet)] == true &&
            dishes.elementAt(position).value[_dietToConstantString(diet)] == false) {
          return Container(
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 10.0,
            ),
            margin: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: SingleLineText(
              diet == Diet.VEGAN ? localizations.veganUponRequest : localizations.vegetarianUponRequest,
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          );
        }
        return Divider();
      },
      padding: const EdgeInsets.only(bottom: 8.0),
      itemCount: dishes.length + 1,
      itemBuilder: (context, position) {
        if (position == 0) {
          return Container();
        }
        return Container(
          padding: const EdgeInsets.symmetric(
            vertical: 5.0,
            horizontal: 10.0,
          ),
          child: DishWidget(
            dish: dishes.elementAt(position - 1),
          ),
        );
      },
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

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    return DisposableProvider<RestaurantDishesBloc>(
      packageBuilder: (context) => RestaurantDishesBloc(restaurantKey: restaurantKey),
      child: Builder(
        builder: (context) {
          final MainBloc mainBloc = Provider.of<MainBloc>(context);
          final RestaurantDishesBloc restaurantDishesBloc = Provider.of<RestaurantDishesBloc>(context);
          return Container(
            color: Theme.of(context).brightness == Brightness.dark ? null : Colors.grey.shade300,
            alignment: Alignment.center,
            child: StreamBuilder<List<Data>>(
              stream: restaurantDishesBloc.dishes,
              builder: (context, dishesSnapshot) {
                if (dishesSnapshot?.data == null) {
                  if (dishesSnapshot.connectionState == ConnectionState.waiting) {
                    restaurantDishesBloc.getDishes();
                  }
                  return _loadingView();
                }

                /// get users chosen diet
                return StreamBuilder<Diet>(
                  stream: mainBloc.diet,
                  builder: (context, originalDietSnapshot) {
                    if (originalDietSnapshot?.data == null) {
                      return _loadingView();
                    }

                    /// see if user has chosen to see vegetarian dishes in case there are no vegan dishes
                    return StreamBuilder<Diet>(
                      stream: restaurantDishesBloc.forcedDiet,
                      builder: (context, forcedDietSnapshot) {
                        /// what diet have user chosen?
                        Diet diet = originalDietSnapshot?.data;
                        if (forcedDietSnapshot.hasData) diet = forcedDietSnapshot?.data;
                        if (diet == null) diet = Diet.VEGETARIAN;

                        /// only get relevant dishes considering the diet
                        List<Data> filteredDishes = [];
                        if (diet == Diet.VEGETARIAN) {
                          dishesSnapshot.data.forEach((d) => d.value['vegetarian'] == true ? filteredDishes.add(d) : null);
                          dishesSnapshot.data.forEach((d) => d.value['canBeMadeVegetarian'] == true ? filteredDishes.add(d) : null);
                        } else {
                          dishesSnapshot.data.forEach((d) => d.value['vegan'] == true ? filteredDishes.add(d) : null);
                          dishesSnapshot.data.forEach((d) => d.value['canBeMadeVegan'] == true ? filteredDishes.add(d) : null);
                        }

                        return DefaultTabController(
                          length: 3,
                          initialIndex: 1,
                          child: Scaffold(
                            appBar: AppBar(
                              title: SingleLineText(restaurantName),
                              bottom: TabBar(
                                indicatorWeight: 3.0,
                                indicatorColor: Theme.of(context).brightness == Brightness.dark ? null : Colors.white,
                                tabs: [
                                  Tab(icon: Icon(Icons.local_pizza), text: localizations.appetizers),
                                  Tab(icon: Icon(Icons.restaurant), text: localizations.entrees),
                                  Tab(icon: Icon(Icons.fastfood), text: localizations.sides),
                                ],
                              ),
                            ),
                            body: TabBarView(
                              children: [
                                _listView(
                                  diet: diet,
                                  context: context,
                                  localizations: localizations,
                                  restaurantDishesBloc: restaurantDishesBloc,
                                  dishes: filteredDishes.where((d) => d.value['category'].toString().toLowerCase() == 'a').toList(),
                                ),
                                _listView(
                                  diet: diet,
                                  context: context,
                                  localizations: localizations,
                                  restaurantDishesBloc: restaurantDishesBloc,
                                  dishes: filteredDishes.where((d) => d.value['category'].toString().toLowerCase() == 'e').toList(),
                                ),
                                _listView(
                                  diet: diet,
                                  context: context,
                                  localizations: localizations,
                                  restaurantDishesBloc: restaurantDishesBloc,
                                  dishes: filteredDishes.where((d) => d.value['category'].toString().toLowerCase() == 'd').toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
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

class DishWidget extends StatelessWidget {
  final Data dish;

  DishWidget({@required this.dish});

  Widget _rating({@required BuildContext context}) {
    if (dish.value['rating'] == null) {
      return Container();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          height: 8.0,
        ),
        Row(
          children: <Widget>[
            SmoothStarRating(
              allowHalfRating: true,
              starCount: 10,
              rating:
                  (dish.value['rating']['isGoodCount'] / (dish.value['rating']['isBadCount'] + dish.value['rating']['isGoodCount'])) * 10,
              size: 16.0,
              color: AppColors.primarySwatch.shade900,
              borderColor: AppColors.primarySwatch.shade900,
            ),
            Container(
              width: 8.0,
            ),
            SingleLineText(
              ((dish.value['rating']['isGoodCount'] / (dish.value['rating']['isBadCount'] + dish.value['rating']['isGoodCount'])) * 10
                      as double)
                  .toStringAsFixed(1),
              style: TextStyle(
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    dish.value['name'],
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  _rating(context: context),
                  Container(height: 8.0),
                  Text(dish.value['description']),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
