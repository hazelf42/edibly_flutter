import 'dart:io';

import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/main_bloc.dart';
import 'package:edibly/screens/home/home_screen.dart';
import 'package:edibly/screens/register/register_bloc.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RegisterInfoScreen extends StatelessWidget {
  @override
  RegisterInfoScreen(this.firebaseUser);
  FirebaseUser firebaseUser;

  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);

    return DisposableProvider<RegisterBloc>(
      packageBuilder: (context) => RegisterBloc(
            localizations: localizations,
          ),
      child: Builder(
        builder: (context) {
          final RegisterBloc registerBloc = Provider.of<RegisterBloc>(context);
          final AppLocalizations localizations = AppLocalizations.of(context);
          return Scaffold(
            body: Theme(
                data: ThemeData(
                  errorColor: Colors.white,
                  primarySwatch: Colors.orange,
                  brightness: Brightness.dark,
                  accentColor: Colors.white,
                ),
                child: SafeArea(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade400, Colors.red.shade600],
                        begin: const FractionalOffset(0.5, 0.0),
                        end: const FractionalOffset(0.0, 0.5),
                        stops: [0.0, 1.0],
                        tileMode: TileMode.clamp,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: ListView(
                      padding: const EdgeInsets.all(20.0),
                      shrinkWrap: true,
                      children: <Widget>[
                        photoField(registerBloc, localizations),
                        SizedBox(height: 30),
                        veganField(registerBloc, localizations),
                        SizedBox(height: 30),
                        glutenFreeField(registerBloc, localizations),
                        SizedBox(height: 30),
                        submitButton(registerBloc, localizations, context)
                      ],
                    ),
                  ),
                )),
          );
        },
      ),
    );
  }

  Widget photoField(RegisterBloc registerBloc, AppLocalizations localizations) {
    return FutureBuilder(
        future: FirebaseAuth.instance.currentUser(),
        builder: (context, user) {
          return StreamBuilder<File>(
            stream: registerBloc.photo,
            builder: (context, snapshot) {
              return Center(
                child: PopupMenuButton(
                  onSelected: (ImageSource imageSource) async {
                    var image =
                        await ImagePicker.pickImage(source: imageSource);
                    if (image != null) {
                      registerBloc.setPhoto(image);
                      await user.data.updateProfile(UserUpdateInfo().photoUrl =
                          await registerBloc.getImageUrl(photo: image));
                    }
                    ;
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<ImageSource>>[
                        PopupMenuItem<ImageSource>(
                          value: ImageSource.gallery,
                          child: Text(localizations.pickFromGallery),
                        ),
                        PopupMenuItem<ImageSource>(
                          value: ImageSource.camera,
                          child: Text(localizations.takePicture),
                        ),
                      ],
                  child: CircleAvatar(
                    backgroundColor: Colors.orange.shade200,
                    radius: 36.0,
                    backgroundImage: snapshot.hasData
                        ? FileImage(snapshot.data)
                        : (user.hasData ? profilePic(user.data) : null),
                    child: !user.hasData ||
                            (snapshot.hasData || profilePic(user.data) != null)
                        ? null
                        : Icon(
                            Icons.person,
                            size: 48.0,
                            color: Colors.white,
                          ),
                  ),
                ),
              );
            },
          );
        });
  }

  ImageProvider<dynamic> profilePic(FirebaseUser user) {
    if (user.photoUrl == null) {
      return null;
    } else {
      return NetworkImage(user.photoUrl);
    }
  }

  Widget veganField(RegisterBloc registerBloc, AppLocalizations localizations) {
    return StreamBuilder<bool>(
      stream: registerBloc.vegan,
      builder: (context, snapshot) {
        return MenuSelector(
          option1Text: localizations.vegan,
          option2Text: localizations.vegetarian,
          selectedOption: snapshot?.data ?? true
              ? MenuSelectorOption.option1
              : MenuSelectorOption.option2,
          onSelect: (option) {
            registerBloc.setVegan(option == MenuSelectorOption.option1);
          },
        );
      },
    );
  }

  Widget glutenFreeField(
      RegisterBloc registerBloc, AppLocalizations localizations) {
    return StreamBuilder<bool>(
      stream: registerBloc.glutenFree,
      builder: (context, snapshot) {
        return MenuSwitchItem(
          onTap: () {
            registerBloc.setGlutenFree(!(snapshot?.data ?? false));
          },
          iconData: Icons.check_circle,
          string: localizations.glutenFree,
          value: snapshot?.data ?? false,
        );
      },
    );
  }

  Widget submitButton(RegisterBloc registerBloc, AppLocalizations localizations,
      BuildContext context) {
    return RaisedButton(
      color: Colors.orange.shade700,
      onPressed: (() async {
        FirebaseUser user;
        await MainBloc().getCurrentFirebaseUser().then((user) async {
          await registerBloc.submit(user);
          user = user;
        }).then((_) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) {
            return HomeScreen(firebaseUser: user);
          }));
        });
      }),
      child: SingleLineText(localizations.signUp),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class MenuSwitchItem extends StatelessWidget {
  final GestureTapCallback onTap;
  final IconData iconData;
  final String string;
  final bool value;

  const MenuSwitchItem({
    @required this.onTap,
    @required this.iconData,
    @required this.string,
    @required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final bool darkModeEnabled =
        Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4.0,
        horizontal: 8.0,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4.0),
        splashFactory: InkRipple.splashFactory,
        child: Container(
          height: 40.0,
          padding: const EdgeInsets.symmetric(
            horizontal: 8.0,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                iconData,
                color: darkModeEnabled ? null : Colors.black54,
              ),
              Container(
                width: 32.0,
              ),
              Expanded(
                child: SingleLineText(
                  string,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: null,
                inactiveThumbColor:
                    value ? Colors.orange.shade600 : Colors.white,
                inactiveTrackColor:
                    value ? Colors.orange.shade300 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum MenuSelectorOption {
  option1,
  option2,
}

class MenuSelector extends StatelessWidget {
  final String option1Text;
  final String option2Text;
  final MenuSelectorOption selectedOption;
  final Function(MenuSelectorOption) onSelect;

  MenuSelector({
    @required this.option1Text,
    @required this.option2Text,
    @required this.selectedOption,
    @required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          width: 1.0,
          color: Colors.white,
        ),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: FlatButton(
                onPressed: () {
                  if (selectedOption != MenuSelectorOption.option1) {
                    onSelect(MenuSelectorOption.option1);
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.horizontal(
                    left: const Radius.circular(4.0),
                  ),
                ),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textColor: selectedOption == MenuSelectorOption.option1
                    ? Colors.white
                    : Theme.of(context).hintColor,
                color: selectedOption == MenuSelectorOption.option1
                    ? Colors.orange.shade700
                    : null,
                child: SingleLineText(
                  option1Text,
                  style: TextStyle(
                    fontWeight: selectedOption == MenuSelectorOption.option1
                        ? FontWeight.bold
                        : null,
                  ),
                ),
              ),
            ),
            Container(
              width: 1.0,
              color: Colors.white,
            ),
            Expanded(
              child: FlatButton(
                onPressed: () {
                  if (selectedOption != MenuSelectorOption.option2) {
                    onSelect(MenuSelectorOption.option2);
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.horizontal(
                    right: const Radius.circular(4.0),
                  ),
                ),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textColor: selectedOption == MenuSelectorOption.option2
                    ? Colors.white
                    : Theme.of(context).hintColor,
                color: selectedOption == MenuSelectorOption.option2
                    ? Colors.orange.shade700
                    : null,
                child: SingleLineText(
                  option2Text,
                  style: TextStyle(
                    fontWeight: selectedOption == MenuSelectorOption.option2
                        ? FontWeight.bold
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
