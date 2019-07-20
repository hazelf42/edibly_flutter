import 'dart:io';

import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/screens/home/home_screen.dart';
import 'package:edibly/screens/register/register_bloc.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'state_widget.dart';

class RegisterScreen extends StatelessWidget {
  Widget glutenFreeField(RegisterBloc registerBloc, AppLocalizations localizations) {
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

  Widget firstNameField(RegisterBloc registerBloc, AppLocalizations localizations) {
    return StreamBuilder<String>(
      stream: registerBloc.firstName,
      builder: (context, passwordSnapshot) {
        return StreamBuilder<RegisterState>(
          stream: registerBloc.registerState,
          builder: (context, firstNameSnapshot) {
            return TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                labelText: localizations.firstName,
                prefixIcon: Icon(
                  Icons.short_text,
                  color: passwordSnapshot.hasError ? Theme.of(context).errorColor : null,
                ),
                errorText: passwordSnapshot.error,
              ),
              onChanged: registerBloc.setFirstName,
              enabled: firstNameSnapshot.data == RegisterState.TRYING ? false : true,
            );
          },
        );
      },
    );
  }

  Widget lastNameField(RegisterBloc registerBloc, AppLocalizations localizations) {
    return StreamBuilder<String>(
      stream: registerBloc.lastName,
      builder: (context, lastNameSnapshot) {
        return StreamBuilder<RegisterState>(
          stream: registerBloc.registerState,
          builder: (context, registerStateSnapshot) {
            return TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                labelText: localizations.lastName,
                prefixIcon: Icon(
                  Icons.short_text,
                  color: lastNameSnapshot.hasError ? Theme.of(context).errorColor : null,
                ),
                errorText: lastNameSnapshot.error,
              ),
              onChanged: registerBloc.setLastName,
              enabled: registerStateSnapshot.data == RegisterState.TRYING ? false : true,
            );
          },
        );
      },
    );
  }

  Widget passwordField(RegisterBloc registerBloc, AppLocalizations localizations) {
    return StreamBuilder<String>(
      stream: registerBloc.password,
      builder: (context, passwordSnapshot) {
        return StreamBuilder<RegisterState>(
          stream: registerBloc.registerState,
          builder: (context, registerStateSnapshot) {
            return TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                labelText: localizations.password,
                prefixIcon: Icon(
                  Icons.lock,
                  color: passwordSnapshot.hasError ? Theme.of(context).errorColor : null,
                ),
                errorText: passwordSnapshot.error,
              ),
              obscureText: true,
              onChanged: registerBloc.setPassword,
              enabled: registerStateSnapshot.data == RegisterState.TRYING ? false : true,
            );
          },
        );
      },
    );
  }

  Widget emailField(RegisterBloc registerBloc, AppLocalizations localizations) {
    return StreamBuilder<String>(
      stream: registerBloc.email,
      builder: (context, emailSnapshot) {
        return StreamBuilder<RegisterState>(
          stream: registerBloc.registerState,
          builder: (context, registerStateSnapshot) {
            return TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                labelText: localizations.email,
                prefixIcon: Icon(
                  Icons.person,
                  color: emailSnapshot.hasError ? Theme.of(context).errorColor : null,
                ),
                errorText: emailSnapshot.error,
                hintText: localizations.emailExampleText,
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: registerBloc.setEmail,
              enabled: registerStateSnapshot.data == RegisterState.TRYING ? false : true,
            );
          },
        );
      },
    );
  }
  Widget googleButton(RegisterBloc registerBloc, AppLocalizations localizations, BuildContext context) { return
 
RaisedButton(
    onPressed: () => StateWidget.of(context).signInWithGoogle(),
    padding: EdgeInsets.only(top: 3.0, bottom: 3.0, left: 3.0),
    color: const Color(0xFFFFFFFF),
    child: new Row( 
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        new Image.asset(
          'asset/google_button.jpg',
          height: 40.0,
        ),
        new Container(
            padding: EdgeInsets.only(left: 10.0, right: 10.0),
            child: new Text( 
              "Sign in with Google",
              style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold),
            )
        ),
      ],
    ),
);}


  Widget veganField(RegisterBloc registerBloc, AppLocalizations localizations) {
    return StreamBuilder<bool>(
      stream: registerBloc.vegan,
      builder: (context, snapshot) {
        return MenuSelector(
          option1Text: localizations.vegan,
          option2Text: localizations.vegetarian,
          selectedOption: snapshot?.data ?? true ? MenuSelectorOption.option1 : MenuSelectorOption.option2,
          onSelect: (option) {
            registerBloc.setVegan(option == MenuSelectorOption.option1);
          },
        );
      },
    );
  }

  Widget photoField(RegisterBloc registerBloc, AppLocalizations localizations) {
    return StreamBuilder<File>(
      stream: registerBloc.photo,
      builder: (context, snapshot) {
        return Center(
          child: PopupMenuButton(
            onSelected: (ImageSource imageSource) async {
              var image = await ImagePicker.pickImage(source: imageSource);
              if (image != null) registerBloc.setPhoto(image);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<ImageSource>>[
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
              backgroundImage: snapshot.hasData ? FileImage(snapshot.data) : null,
              child: snapshot.hasData
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
  }

  Widget submitButton(RegisterBloc registerBloc, AppLocalizations localizations) {
    String registerStateToString(RegisterState loginState) {
      switch (loginState) {
        case RegisterState.FAILED:
          return localizations.networkRequestFailed;
        case RegisterState.EMAIL_IN_USE:
          return localizations.emailIsAlreadyInUse;
        default:
          return '';
      }
    }

    return StreamBuilder<RegisterState>(
      stream: registerBloc.registerState,
      builder: (context, snapshot) {
        if (snapshot.data == RegisterState.SUCCESSFUL) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            registerBloc.getCurrentFirebaseUser().then((user) {
              if (user != null) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(firebaseUser: user),
                  ),
                  (Route<dynamic> route) => false,
                );
              }
            });
          });
        }
        return Column(
          children: <Widget>[
            snapshot.hasError
                ? Column(children: <Widget>[
                    Text(
                      registerStateToString(snapshot.error),
                      style: TextStyle(
                        color: Theme.of(context).errorColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 16.0,
                    ),
                  ])
                : SizedBox(),
            snapshot.data == RegisterState.TRYING
                ? CircularProgressIndicator()
                : RaisedButton(
                    color: Colors.orange.shade700,
                    onPressed: registerBloc.register,
                    child: SingleLineText(localizations.signUp),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
          ],
        );
      },
    );
  }

  @override
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
            appBar: AppBar(
              title: Text(localizations.signUp),
            ),
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
                        googleButton(registerBloc, localizations, context),
                        photoField(registerBloc, localizations),
                        SizedBox(height: 16.0),
                        emailField(registerBloc, localizations),
                        SizedBox(height: 16.0),
                        passwordField(registerBloc, localizations),
                        SizedBox(height: 16.0),
                        firstNameField(registerBloc, localizations),
                        SizedBox(height: 16.0),
                        lastNameField(registerBloc, localizations),
                        SizedBox(height: 16.0),
                        veganField(registerBloc, localizations),
                        SizedBox(height: 16.0),
                        glutenFreeField(registerBloc, localizations),
                        SizedBox(height: 16.0),
                        submitButton(registerBloc, localizations),
                      ],
                    ),
                  ),
                )),
          );
        },
      ),
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
    final bool darkModeEnabled = Theme.of(context).brightness == Brightness.dark;
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
                inactiveThumbColor: value ? Colors.orange.shade600 : Colors.white,
                inactiveTrackColor: value ? Colors.orange.shade300 : Colors.black26,
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
                textColor: selectedOption == MenuSelectorOption.option1 ? Colors.white : Theme.of(context).hintColor,
                color: selectedOption == MenuSelectorOption.option1 ? Colors.orange.shade700 : null,
                child: SingleLineText(
                  option1Text,
                  style: TextStyle(
                    fontWeight: selectedOption == MenuSelectorOption.option1 ? FontWeight.bold : null,
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
                textColor: selectedOption == MenuSelectorOption.option2 ? Colors.white : Theme.of(context).hintColor,
                color: selectedOption == MenuSelectorOption.option2 ? Colors.orange.shade700 : null,
                child: SingleLineText(
                  option2Text,
                  style: TextStyle(
                    fontWeight: selectedOption == MenuSelectorOption.option2 ? FontWeight.bold : null,
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