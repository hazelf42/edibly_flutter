import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info/package_info.dart';
import 'package:flutter/material.dart';

import 'package:edibly/screens/profile/profile_screen.dart';
import 'package:edibly/screens/drawer/drawer_bloc.dart';
import 'package:edibly/screens/login/login_screen.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/bloc_helper/app_error.dart';
import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/values/app_colors.dart';
import 'package:edibly/values/constants.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/main_bloc.dart';

class DrawerScreen extends StatelessWidget {
  final FirebaseUser _firebaseUser;

  DrawerScreen(this._firebaseUser);

  Widget _userInfo(DrawerBloc drawerBloc) {
    return StreamBuilder<Event>(
      stream: drawerBloc.getUser(
        uid: _firebaseUser.uid,
      ),
      builder: (context, snapshot) {
        Map<dynamic, dynamic> map = snapshot.hasData ? snapshot?.data?.snapshot?.value : null;
        return Container(
          padding: EdgeInsets.fromLTRB(16.0, 12.0, 0.0, 12.0),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 24.0,
                backgroundImage: map == null ? null : NetworkImage(map['photoUrl']),
                child: map == null
                    ? SizedBox(
                        width: 46.0,
                        height: 46.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                        ),
                      )
                    : null,
              ),
              Container(
                width: 24.0,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    map == null
                        ? Container()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SingleLineText(
                                '${map['firstName']} ${map['lastName']}',
                                style: Theme.of(context).textTheme.body1.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
                              ),
                              Container(
                                height: 4.0,
                              ),
                            ],
                          ),
                    SingleLineText(
                      _firebaseUser.email,
                      style: Theme.of(context).textTheme.body1.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24.0,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _oldPasswordField(DrawerBloc drawerBloc, AppLocalizations localizations) {
    return StreamBuilder<String>(
      stream: drawerBloc.oldPassword,
      builder: (context, oldPasswordSnapshot) {
        return StreamBuilder<UpdatePasswordState>(
          stream: drawerBloc.updatePasswordState,
          builder: (context, updatePasswordStateSnapshot) {
            return TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                labelText: localizations.oldPassword,
                prefixIcon: Icon(
                  Icons.lock,
                  color: oldPasswordSnapshot.hasError ? Theme.of(context).errorColor : null,
                ),
                errorText:
                    oldPasswordSnapshot.hasError && oldPasswordSnapshot.error == AppError.EMPTY ? localizations.errorEmptyPassword : null,
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: drawerBloc.setOldPassword,
              enabled: updatePasswordStateSnapshot.data == UpdatePasswordState.TRYING ? false : true,
              obscureText: true,
            );
          },
        );
      },
    );
  }

  Widget _newPasswordField(DrawerBloc drawerBloc, AppLocalizations localizations) {
    return StreamBuilder<String>(
      stream: drawerBloc.newPassword,
      builder: (context, newPasswordSnapshot) {
        return StreamBuilder<UpdatePasswordState>(
          stream: drawerBloc.updatePasswordState,
          builder: (context, updatePasswordStateSnapshot) {
            return TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                labelText: localizations.newPassword,
                prefixIcon: Icon(
                  Icons.lock,
                  color: newPasswordSnapshot.hasError ? Theme.of(context).errorColor : null,
                ),
                errorText:
                    newPasswordSnapshot.hasError && newPasswordSnapshot.error == AppError.EMPTY ? localizations.errorEmptyPassword : null,
              ),
              onChanged: drawerBloc.setNewPassword,
              enabled: updatePasswordStateSnapshot.data == UpdatePasswordState.TRYING ? false : true,
              obscureText: true,
            );
          },
        );
      },
    );
  }

  Widget _submitButton(DrawerBloc drawerBloc, AppLocalizations localizations) {
    return StreamBuilder<UpdatePasswordState>(
      stream: drawerBloc.updatePasswordState,
      builder: (context, snapshot) {
        if (snapshot.data == UpdatePasswordState.SUCCESSFUL) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pop(context, true);
          });
        }
        return snapshot.data == UpdatePasswordState.TRYING
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
                onPressed: () {
                  drawerBloc.updatePassword(
                    firebaseUser: _firebaseUser,
                  );
                },
                child: SingleLineText(localizations.reset.toUpperCase()),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
      },
    );
  }

  void _logOut(BuildContext context, DrawerBloc drawerBloc, AppLocalizations localizations) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: SingleLineText(localizations.logOut),
          content: Text(localizations.logOutConfirmationText),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
          actions: <Widget>[
            FlatButton(
              child: Text(localizations.cancel.toUpperCase()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text(localizations.logOut.toUpperCase()),
              onPressed: () {
                drawerBloc.logOut();
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(),
                    ),
                    (Route<dynamic> route) => false);
              },
            ),
          ],
        );
      },
    );
  }

  void _showFeedback() async {
    if (await canLaunch(Constants.feedbackForm)) {
      await launch(Constants.feedbackForm);
    }
  }

  void _showDisclaimer(BuildContext context, AppLocalizations localizations) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: SingleLineText(localizations.disclaimer),
          content: SingleChildScrollView(
            child: Text(localizations.disclaimerText),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
          actions: <Widget>[
            FlatButton(
              child: Text(MaterialLocalizations.of(context).closeButtonLabel),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showAbout(BuildContext context, AppLocalizations localizations) {
    PackageInfo.fromPlatform().then((packageInfo) {
      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AboutDialog(
            applicationName: localizations.appName,
            applicationVersion: localizations.versionInfo(packageInfo.version),
            applicationIcon: Image.asset('assets/drawables/ic_launcher.png'),
            children: <Widget>[
              Linkify(
                onOpen: (link) async {
                  if (await canLaunch(link.url)) {
                    await launch(link.url);
                  }
                },
                text: localizations.aboutText,
                humanize: true,
              ),
            ],
          );
        },
      );
    });
  }

  void _showUpdatePasswordDialog(BuildContext context, DrawerBloc drawerBloc, AppLocalizations localizations) {
    String updatePasswordStateToString(UpdatePasswordState resetPasswordState) {
      switch (resetPasswordState) {
        case UpdatePasswordState.EMPTY_PASSWORD:
          return localizations.errorEmptyPassword;
        case UpdatePasswordState.INVALID_PASSWORD:
          return localizations.errorInvalidPassword;
        case UpdatePasswordState.WRONG_PASSWORD:
          return localizations.errorWrongPassword;
        default:
          return localizations.networkRequestFailed;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
          title: SingleLineText(localizations.resetPassword),
          content: Container(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                _oldPasswordField(drawerBloc, localizations),
                SizedBox(height: 16.0),
                _newPasswordField(drawerBloc, localizations),
                StreamBuilder<UpdatePasswordState>(
                  stream: drawerBloc.updatePasswordState,
                  builder: (context, snapshot) {
                    return snapshot.hasError
                        ? Column(children: <Widget>[
                            SizedBox(
                              height: 16.0,
                            ),
                            Text(
                              updatePasswordStateToString(snapshot.error),
                              style: TextStyle(
                                color: Theme.of(context).errorColor,
                                fontSize: 13.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ])
                        : SizedBox();
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(localizations.cancel.toUpperCase()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            _submitButton(drawerBloc, localizations),
          ],
        );
      },
    ).then((passwordUpdated) {
      if (passwordUpdated is bool && passwordUpdated) {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                content: Text(localizations.updatePasswordSuccessText),
                contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
                actions: <Widget>[
                  FlatButton(
                    child: Text(localizations.ok.toUpperCase()),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            });
      }
      drawerBloc.setOldPassword('');
      drawerBloc.setNewPassword('');
      drawerBloc.setUpdatePasswordState(UpdatePasswordState.IDLE);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DisposableProvider<DrawerBloc>(
      packageBuilder: (context) => DrawerBloc(),
      child: Builder(
        builder: (context) {
          final MainBloc mainBloc = Provider.of<MainBloc>(context);
          final DrawerBloc drawerBloc = Provider.of<DrawerBloc>(context);
          final AppLocalizations localizations = AppLocalizations.of(context);
          return Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                Container(height: MediaQuery.of(context).padding.top + 8.0),
                _userInfo(drawerBloc),
                MenuItem(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(
                              uid: _firebaseUser.uid,
                            ),
                      ),
                    );
                  },
                  iconData: Icons.account_circle,
                  string: localizations.myProfile,
                ),
                MenuItem(
                  onTap: () => _showUpdatePasswordDialog(context, drawerBloc, localizations),
                  iconData: Icons.lock,
                  string: localizations.resetPassword,
                ),
                MenuItem(
                  onTap: () => _logOut(context, drawerBloc, localizations),
                  iconData: Icons.exit_to_app,
                  string: localizations.logOut,
                ),
                Divider(),
                MenuItem(
                  onTap: () => _showFeedback(),
                  iconData: Icons.feedback,
                  string: localizations.feedback,
                ),
                MenuItem(
                  onTap: () => _showDisclaimer(context, localizations),
                  iconData: Icons.warning,
                  string: localizations.disclaimer,
                ),
                MenuItem(
                  onTap: () => _showAbout(context, localizations),
                  iconData: Icons.info,
                  string: localizations.about,
                ),
                Divider(),
                StreamBuilder<Diet>(
                  stream: mainBloc.diet,
                  initialData: MainBloc.dietDefaultValue,
                  builder: (context, snapshot) {
                    return MenuSelector(
                      option1Text: localizations.vegetarian,
                      option2Text: localizations.vegan,
                      selectedOption: snapshot.data == Diet.VEGETARIAN ? MenuSelectorOption.option1 : MenuSelectorOption.option2,
                      onSelect: (option) {
                        mainBloc.setDiet(_firebaseUser.uid, option == MenuSelectorOption.option1 ? Diet.VEGETARIAN : Diet.VEGAN);
                      },
                    );
                  },
                ),
                StreamBuilder<bool>(
                  stream: mainBloc.glutenFree,
                  initialData: MainBloc.glutenFreeDefaultValue,
                  builder: (context, snapshot) {
                    return MenuSwitchItem(
                      iconData: Icons.check_circle,
                      string: AppLocalizations.of(context).glutenFree,
                      onTap: () {
                        mainBloc.toggleGlutenFree(_firebaseUser.uid);
                      },
                      value: snapshot.data,
                    );
                  },
                ),
                MenuSwitchItem(
                  iconData: Icons.invert_colors,
                  string: AppLocalizations.of(context).darkMode,
                  onTap: () {
                    mainBloc.toggleDarkMode();
                  },
                  value: Theme.of(context).brightness == Brightness.dark,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class MenuItem extends StatelessWidget {
  final GestureTapCallback onTap;
  final IconData iconData;
  final String string;

  const MenuItem({
    @required this.onTap,
    @required this.iconData,
    @required this.string,
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
              SingleLineText(
                string,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: null,
                inactiveThumbColor: value ? Theme.of(context).toggleableActiveColor : Colors.grey.shade50,
                inactiveTrackColor: value ? Theme.of(context).toggleableActiveColor.withOpacity(0.5) : Colors.black26,
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
    final bool darkModeEnabled = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 4.0,
        horizontal: 16.0,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          width: 0.5,
          color: Theme.of(context).dividerColor,
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
                    ? (darkModeEnabled ? AppColors.primarySwatch.shade300 : AppColors.primarySwatch.shade900)
                    : null,
                color: selectedOption == MenuSelectorOption.option1
                    ? (darkModeEnabled
                        ? AppColors.primarySwatch.shade50.withOpacity(0.08)
                        : AppColors.primarySwatch.shade500.withOpacity(0.12))
                    : null,
                child: SingleLineText(option1Text),
              ),
            ),
            Container(
              width: 0.5,
              color: Theme.of(context).dividerColor,
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
                    ? (darkModeEnabled ? AppColors.primarySwatch.shade300 : AppColors.primarySwatch.shade900)
                    : null,
                color: selectedOption == MenuSelectorOption.option2
                    ? (darkModeEnabled
                        ? AppColors.primarySwatch.shade50.withOpacity(0.08)
                        : AppColors.primarySwatch.shade500.withOpacity(0.12))
                    : null,
                child: SingleLineText(option2Text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*
class MenuRouteItem extends StatelessWidget {
  final AppRoute routeName;
  final IconData iconData;
  final String string;

  const MenuRouteItem({
    @required this.routeName,
    @required this.iconData,
    @required this.string,
  });

  @override
  Widget build(BuildContext context) {
    final bool darkModeEnabled = Theme.of(context).brightness == Brightness.dark;
    final bool isSelected = ModalRoute.of(context).settings.name.startsWith(routeName.name);
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4.0,
        horizontal: 8.0,
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamedAndRemoveUntil(context, routeName.name, (_) => false);
        },
        borderRadius: BorderRadius.circular(4.0),
        splashFactory: InkRipple.splashFactory,
        child: Container(
          height: 40.0,
          padding: const EdgeInsets.symmetric(
            horizontal: 8.0,
          ),
          decoration: isSelected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: darkModeEnabled
                      ? AppColors.primarySwatch.shade50.withOpacity(0.08)
                      : AppColors.primarySwatch.shade900.withOpacity(0.12),
                )
              : null,
          child: Row(
            children: <Widget>[
              Icon(
                iconData,
                color: darkModeEnabled ? null : (isSelected ? AppColors.primarySwatch.shade900 : Colors.black54),
              ),
              Container(
                width: 32.0,
              ),
              SingleLineText(
                string,
                style: TextStyle(
                  color: isSelected && !darkModeEnabled ? AppColors.primarySwatch.shade900 : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
