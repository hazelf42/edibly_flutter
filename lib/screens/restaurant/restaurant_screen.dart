import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:edibly/screens/restaurant/reviews/restaurant_reviews_screen.dart';
import 'package:edibly/screens/restaurant/dishes/restaurant_dishes_screen.dart';
import 'package:edibly/screens/restaurant/photos/restaurant_photos_screen.dart';
import 'package:edibly/screens/restaurant/tips/restaurant_tips_screen.dart';
import 'package:edibly/screens/restaurant/restaurant_bloc.dart';
import 'package:edibly/screens/new_post/new_post_screen.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/values/app_colors.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/models/data.dart';
import 'package:edibly/main_bloc.dart';

class RestaurantScreen extends StatelessWidget {
  final String firebaseUserId;
  final String restaurantKey;

  RestaurantScreen({
    @required this.firebaseUserId,
    @required this.restaurantKey,
  });

  List<Data> dynamicTagArrayToTagList(dynamic dynamicTagArray) {
    List<Data> tagList = [];
    if (dynamicTagArray != null) {
      Map<dynamic, dynamic> map = dynamicTagArray;
      map.forEach((key, value) {
        tagList.add(Data(key, value));
      });
    }
    return tagList;
  }

  static void showAddTipDialog({
    @required BuildContext context,
    @required RestaurantBloc restaurantBloc,
    @required AppLocalizations localizations,
    @required String restaurantName,
  }) {
    TextEditingController textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return StreamBuilder<AddTipState>(
            stream: restaurantBloc.addTipState,
            builder: (context, snapshot) {
              if (snapshot.data == AddTipState.SUCCESSFUL) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pop(true);
                });
              }
              return AlertDialog(
                title: Text(localizations.addTip),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      maxLength: 140,
                      controller: textController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        errorText: snapshot.hasError ? localizations.errorEmptyTextField : null,
                        hintText: localizations.tipExampleText,
                        isDense: true,
                      ),
                      keyboardType: TextInputType.text,
                      onChanged: (value) {
                        restaurantBloc.setAddTipState(AddTipState.IDLE);
                      },
                      maxLines: 2,
                      enabled: snapshot.data == AddTipState.TRYING ? false : true,
                      buildCounter: (context, {currentLength, maxLength, isFocused}) {
                        return SingleLineText('$currentLength / $maxLength');
                      },
                    ),
                  ],
                ),
                contentPadding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0.0),
                actions: <Widget>[
                  FlatButton(
                    child: Text(localizations.cancel.toUpperCase()),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  FlatButton(
                    child: Text(localizations.add.toUpperCase()),
                    onPressed: snapshot.data == AddTipState.TRYING
                        ? null
                        : () {
                            restaurantBloc.addTip(
                              tip: textController.text,
                              restaurantName: restaurantName,
                            );
                          },
                  )
                ],
              );
            });
      },
    ).then((tipAdded) {
      if (tipAdded is bool && tipAdded) {
        final snackBar = SnackBar(
          content: Text(localizations.tipAddedSuccessText),
        );
        Scaffold.of(context).showSnackBar(snackBar);
      }
      restaurantBloc.setAddTipState(AddTipState.IDLE);
    });
  }

  static void showAddImageDialog({
    @required BuildContext context,
    @required RestaurantBloc restaurantBloc,
    @required AppLocalizations localizations,
    @required String restaurantName,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return StreamBuilder<PickedPhotoUploadState>(
            stream: restaurantBloc.pickedPhotoUploadState,
            builder: (context, pickedPhotoStateSnapshot) {
              if (pickedPhotoStateSnapshot.data == PickedPhotoUploadState.SUCCESSFUL) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pop(true);
                });
              }
              return StreamBuilder<File>(
                stream: restaurantBloc.pickedPhoto,
                builder: (context, pickedPhotoSnapshot) {
                  return AlertDialog(
                    title: Text(localizations.addPhoto),
                    content: Row(
                      children: <Widget>[
                        pickedPhotoSnapshot.hasData
                            ? Image.file(
                                pickedPhotoSnapshot?.data,
                                width: 90.0,
                                height: 90.0,
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.primarySwatch.shade400,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.image,
                                  color: AppColors.primarySwatch.shade400,
                                ),
                                width: 90.0,
                                height: 90.0,
                              ),
                        Container(width: 12.0, height: 1.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              RaisedButton(
                                color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white,
                                child: SingleLineText(localizations.takePicture),
                                onPressed: () {
                                  _getImage(
                                    imageSource: ImageSource.camera,
                                    restaurantBloc: restaurantBloc,
                                  );
                                },
                              ),
                              RaisedButton(
                                color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white,
                                child: SingleLineText(localizations.pickFromGallery),
                                onPressed: () {
                                  _getImage(
                                    imageSource: ImageSource.gallery,
                                    restaurantBloc: restaurantBloc,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    contentPadding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0.0),
                    actions: <Widget>[
                      FlatButton(
                        child: Text(localizations.cancel.toUpperCase()),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      pickedPhotoStateSnapshot.data == PickedPhotoUploadState.TRYING
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              child: SizedBox(
                                width: 24.0,
                                height: 24.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3.0,
                                ),
                              ),
                            )
                          : FlatButton(
                              child: Text(localizations.add.toUpperCase()),
                              onPressed: !pickedPhotoSnapshot.hasData
                                  ? null
                                  : () {
                                      restaurantBloc.uploadPhoto(restaurantName: restaurantName);
                                    },
                            )
                    ],
                  );
                },
              );
            });
      },
    ).then((tipAdded) {
      if (tipAdded is bool && tipAdded) {
        final snackBar = SnackBar(
          content: Text(localizations.photoAddedSuccessText),
        );
        Scaffold.of(context).showSnackBar(snackBar);
      }
      restaurantBloc.setPickedPhotoUploadState(PickedPhotoUploadState.IDLE);
      restaurantBloc.setPickedPhoto(null);
    });
  }

  static Future _getImage({
    @required ImageSource imageSource,
    @required RestaurantBloc restaurantBloc,
  }) async {
    var image = await ImagePicker.pickImage(source: imageSource);
    if (image != null) restaurantBloc.setPickedPhoto(image);
  }

  Widget _rating({@required BuildContext context, @required RestaurantBloc restaurantBloc}) {
    return StreamBuilder<Data>(
        stream: restaurantBloc.rating,
        builder: (context, snapshot) {
          if (snapshot?.data == null) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              restaurantBloc.getRating();
            }
            return Container();
          }
          if (snapshot?.data?.value == null) return Container();
          return Container(
            margin: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: <Widget>[
                SmoothStarRating(
                  allowHalfRating: true,
                  starCount: 5,
                  rating: snapshot.data.value['numRating'] / 2.0 - 0.1,
                  size: 16.0,
                  color: AppColors.primarySwatch.shade900,
                  borderColor: AppColors.primarySwatch.shade900,
                ),
                Container(
                  width: 8.0,
                ),
                SingleLineText(
                  (double.parse(snapshot.data.value['numRating'].toString()) / 2.0).toStringAsFixed(1),
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget _address({@required Data restaurant}) {
    if (restaurant?.value == null ||
        (restaurant.value['address'] ?? restaurant.value['address1'] ?? restaurant.value['address2']) == null) {
      return Container();
    }
    return Container(
      margin: const EdgeInsets.only(top: 4.0),
      child: Text(
        (restaurant.value['address'] ?? restaurant.value['address1'] ?? restaurant.value['address2']).toString().trim() ?? '',
      ),
    );
  }

  Widget _tags({@required BuildContext context, @required dynamic value}) {
    if (value == null || value['tagDict'] == null || value['tagDict'].toString().isEmpty) {
      return Container();
    }
    List<Data> tags = dynamicTagArrayToTagList(value['tagDict']);
    tags.sort((a, b) => b.value - a.value);
    return Container(
      height: 32.0,
      margin: const EdgeInsets.only(top: 12.0, right: 12.0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, position) {
          return Container(width: 8.0, height: 1.0);
        },
        itemCount: tags.length,
        itemBuilder: (context, position) {
          return CustomTag('${tags.elementAt(position).key} (${tags.elementAt(position).value})');
        },
      ),
    );
  }

  Widget _coverImage({@required Data restaurant}) {
    if (restaurant == null) return Container();
    String photoUrl = restaurant.value['photoUrl'] ?? restaurant.value['photoURL'];
    if (photoUrl == null || photoUrl.isEmpty) return Container();
    return Container(
      color: Colors.white,
      child: CachedNetworkImage(
        imageUrl: photoUrl,
        height: 150.0,
        fit: BoxFit.cover,
        placeholder: (context, imageUrl) {
          return Container(
            height: 120.0,
            alignment: Alignment.center,
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  Widget _bookmarkButton({@required RestaurantBloc restaurantBloc, @required Data restaurant}) {
    return StreamBuilder<Event>(
      stream: restaurantBloc.getRestaurantBookmarkValue(firebaseUserId, restaurant.key),
      builder: (context, bookmarkValueSnapshot) {
        bool bookmarked = bookmarkValueSnapshot?.data?.snapshot?.value == 1;
        return IconButton(
          icon: Icon(
            bookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: bookmarked ? AppColors.primarySwatch.shade600 : Theme.of(context).disabledColor,
          ),
          onPressed: () {
            restaurantBloc.setRestaurantBookmarkValue(firebaseUserId, restaurant.key, !bookmarked);
          },
        );
      },
    );
  }

  Widget _header({@required BuildContext context, @required RestaurantBloc restaurantBloc, @required Data restaurant}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _coverImage(restaurant: restaurant),
        Container(height: 8.0),
        Container(
          padding: const EdgeInsets.fromLTRB(12.0, 8.0, 0.0, 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          restaurant.value['name'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 22.0,
                          ),
                        ),
                        _rating(
                          context: context,
                          restaurantBloc: restaurantBloc,
                        ),
                        _address(restaurant: restaurant),
                      ],
                    ),
                  ),
                  _bookmarkButton(
                    restaurantBloc: restaurantBloc,
                    restaurant: restaurant,
                  ),
                ],
              ),
              _tags(
                context: context,
                value: restaurant.value['rating'],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buttonBar({
    @required BuildContext context,
    @required RestaurantBloc restaurantBloc,
    @required AppLocalizations localizations,
    @required String restaurantName,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          RaisedButton(
            color: AppColors.primarySwatch.shade400,
            onPressed: () async {
              final addedNewPost = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => NewPostScreen(
                        firebaseUserId: firebaseUserId,
                        restaurantName: restaurantName,
                        restaurantKey: restaurantKey,
                      ),
                ),
              );
              if (addedNewPost != null && addedNewPost is bool && addedNewPost) {
                final snackBar = SnackBar(
                  content: Text(localizations.reviewAddedSuccessText),
                );
                Scaffold.of(context).showSnackBar(snackBar);
              }
            },
            child: Text(
              localizations.addReview.toUpperCase(),
              style: TextStyle(
                fontSize: 13.0,
                color: Colors.white,
              ),
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: RaisedButton(
                  color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white,
                  onPressed: () {
                    showAddTipDialog(
                      context: context,
                      restaurantBloc: restaurantBloc,
                      localizations: localizations,
                      restaurantName: restaurantName,
                    );
                  },
                  child: Text(
                    localizations.addTip.toUpperCase(),
                    style: TextStyle(fontSize: 13.0),
                  ),
                ),
              ),
              Container(width: 16.0),
              Expanded(
                child: RaisedButton(
                  color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white,
                  onPressed: () {
                    showAddImageDialog(
                      context: context,
                      restaurantBloc: restaurantBloc,
                      localizations: localizations,
                      restaurantName: restaurantName,
                    );
                  },
                  child: Text(
                    localizations.addPhoto.toUpperCase(),
                    style: TextStyle(fontSize: 13.0),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _firstOneToAddTip({
    @required BuildContext context,
    @required MainBloc mainBloc,
    @required RestaurantBloc restaurantBloc,
    @required AppLocalizations localizations,
    @required Data restaurant,
  }) {
    return StreamBuilder<AddTipState>(
        stream: restaurantBloc.addTipState,
        builder: (context, snapshot) {
          if (snapshot.data == AddTipState.SUCCESSFUL) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final snackBar = SnackBar(
                content: Text(localizations.tipAddedSuccessText),
              );
              Scaffold.of(context).showSnackBar(snackBar);
              restaurantBloc.setAddTipState(AddTipState.IDLE);
              restaurantBloc.getRestaurant();
            });
          } else if (snapshot.data == AddTipState.TRYING) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    localizations.beTheFirstToLeaveTip,
                    style: TextStyle(fontSize: 20.0),
                  ),
                  Container(height: 4.0),
                  Text(
                    localizations.beTheFirstToLeaveTipHelpText,
                  ),
                  Container(height: 6.0),
                  TextField(
                    buildCounter: (context, {currentLength, maxLength, isFocused}) => Container(),
                    maxLength: 140,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      errorText: snapshot.hasError ? localizations.errorEmptyTextField : null,
                      hintText: localizations.tipExampleText,
                      isDense: true,
                    ),
                    keyboardType: TextInputType.text,
                    onChanged: (value) {
                      restaurantBloc.setAddTipState(AddTipState.IDLE);
                    },
                    onSubmitted: (tip) {
                      if (tip != null && tip.isNotEmpty) {
                        restaurantBloc.addTip(
                          tip: tip,
                          restaurantName: restaurant.value['name'],
                        );
                      }
                    },
                    maxLines: 1,
                    enabled: snapshot.data == AddTipState.TRYING ? false : true,
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _featuredTip({
    @required BuildContext context,
    @required MainBloc mainBloc,
    @required RestaurantBloc restaurantBloc,
    @required AppLocalizations localizations,
    @required Data restaurant,
  }) {
    if (restaurant == null || restaurant.value['featured_tip'] == null || restaurant.value['featured_tip'].toString().isEmpty) {
      return _firstOneToAddTip(
        context: context,
        mainBloc: mainBloc,
        restaurantBloc: restaurantBloc,
        localizations: localizations,
        restaurant: restaurant,
      );
    }
    dynamic featuredTip = restaurant.value['featured_tip'];
    return StreamBuilder<Event>(
      stream: mainBloc.getUser(featuredTip['tipUserId'].toString()),
      builder: (context, snapshot) {
        Map<dynamic, dynamic> authorValue = snapshot?.data?.snapshot?.value;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SingleLineText(
                  localizations.featuredTip.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.0,
                  ),
                ),
                Container(height: 10.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 18.0,
                      backgroundImage: authorValue == null ? null : NetworkImage(authorValue['photoUrl'] ?? authorValue['photoURL']),
                      child: authorValue == null
                          ? SizedBox(
                              width: 34.0,
                              height: 34.0,
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
                      child: authorValue == null
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
                                        '${authorValue['firstName']} ${authorValue['lastName']}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SingleLineText(
                                        ' (${authorValue['dietName']}${(authorValue['isGlutenFree'] as bool ? ', ${localizations.glutenFree.toLowerCase()}' : '')})',
                                        style: TextStyle(
                                          color: Theme.of(context).hintColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                featuredTip['description'] != null
                                    ? Container(
                                        margin: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          featuredTip['description'],
                                          style: TextStyle(fontSize: 13.0),
                                        ),
                                      )
                                    : Container(),
                              ],
                            ),
                    ),
                    Container(
                      width: 24.0,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _photos({@required BuildContext context, @required String restaurantName, @required RestaurantBloc restaurantBloc}) {
    return StreamBuilder<List<Data>>(
      stream: restaurantBloc.lastThreePhotos,
      builder: (context, snapshot) {
        if (snapshot?.data == null) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            restaurantBloc.getLastThreeRestaurantPhotos();
          }
          return Container();
        }
        if (snapshot.data.isEmpty) return Container();
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => RestaurantPhotosScreen(
                      firebaseUserId: firebaseUserId,
                      restaurantName: restaurantName,
                      restaurantKey: restaurantKey,
                    ),
              ),
            );
          },
          child: Container(
            height: 120.0,
            child: GridView.builder(
              itemCount: snapshot.data.length > 3 ? 3 : snapshot.data.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
              itemBuilder: (context, position) {
                return CachedNetworkImage(
                  key: Key(snapshot.data.elementAt(position).key),
                  imageUrl: snapshot.data.elementAt(position).value['imageUrl'],
                  fit: BoxFit.cover,
                  placeholder: (context, imageUrl) {
                    return Container(
                      height: 120.0,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    return DisposableProvider<RestaurantBloc>(
      packageBuilder: (context) => RestaurantBloc(
            firebaseUserId: firebaseUserId,
            restaurantKey: restaurantKey,
          ),
      child: Builder(
        builder: (context) {
          final MainBloc mainBloc = Provider.of<MainBloc>(context);
          final RestaurantBloc restaurantBloc = Provider.of<RestaurantBloc>(context);
          return Scaffold(
            appBar: AppBar(
              title: SingleLineText(localizations.restaurant),
            ),
            body: Container(
              alignment: Alignment.center,
              child: StreamBuilder<Data>(
                  stream: restaurantBloc.restaurant,
                  builder: (context, restaurantSnapshot) {
                    if (restaurantSnapshot?.data == null) {
                      if (restaurantSnapshot.connectionState == ConnectionState.waiting) {
                        restaurantBloc.getRestaurant();
                      }
                      return CircularProgressIndicator();
                    } else {
                      return ListView(
                        children: <Widget>[
                          _header(context: context, restaurantBloc: restaurantBloc, restaurant: restaurantSnapshot?.data),
                          _featuredTip(
                            context: context,
                            mainBloc: mainBloc,
                            restaurantBloc: restaurantBloc,
                            localizations: localizations,
                            restaurant: restaurantSnapshot?.data,
                          ),
                          Container(height: 6.0),
                          _buttonBar(
                            context: context,
                            restaurantBloc: restaurantBloc,
                            localizations: localizations,
                            restaurantName: restaurantSnapshot.data.value['name'],
                          ),
                          ListTile(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => RestaurantDishesScreen(
                                        restaurantName: restaurantSnapshot.data.value['name'],
                                        restaurantKey: restaurantKey,
                                      ),
                                ),
                              );
                            },
                            title: SingleLineText(localizations.menu),
                            leading: Icon(Icons.restaurant_menu),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16.0,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                          ListTile(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => RestaurantReviewsScreen(
                                        firebaseUserId: firebaseUserId,
                                        restaurantName: restaurantSnapshot.data.value['name'],
                                        restaurantKey: restaurantKey,
                                      ),
                                ),
                              );
                            },
                            title: SingleLineText(localizations.reviews),
                            leading: Icon(Icons.comment),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16.0,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                          ListTile(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => RestaurantTipsScreen(
                                        firebaseUserId: firebaseUserId,
                                        restaurantName: restaurantSnapshot.data.value['name'],
                                        restaurantKey: restaurantKey,
                                      ),
                                ),
                              );
                            },
                            title: SingleLineText(localizations.tips),
                            leading: Icon(Icons.info),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16.0,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                          ListTile(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => RestaurantPhotosScreen(
                                        firebaseUserId: firebaseUserId,
                                        restaurantName: restaurantSnapshot.data.value['name'],
                                        restaurantKey: restaurantKey,
                                      ),
                                ),
                              );
                            },
                            title: SingleLineText(localizations.photos),
                            leading: Icon(Icons.collections),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16.0,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                          _photos(
                            context: context,
                            restaurantName: restaurantSnapshot.data.value['name'],
                            restaurantBloc: restaurantBloc,
                          ),
                        ],
                      );
                    }
                  }),
            ),
          );
        },
      ),
    );
  }
}
