import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:edibly/screens/login/login_screen.dart';
import 'package:edibly/screens/home/home_screen.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/values/app_colors.dart';
import 'package:edibly/values/pref_keys.dart';
import 'package:edibly/main_bloc.dart';
import 'screens/register/state_widget.dart';
void main() async {

  SharedPreferences preferences = await SharedPreferences.getInstance();
  bool darkModeEnabled = preferences.getBool(PrefKeys.darkModeEnabled) ?? MainBloc.darkModeEnabledDefaultValue;
  StateWidget stateWidget = StateWidget(child: _AppWidget(darkModeEnabled));
  runApp(stateWidget);
}

class _AppWidget extends StatelessWidget {
  final bool _darkModeEnabled;

  _AppWidget(this._darkModeEnabled);

  @override
  Widget build(BuildContext context) {
    return DisposableProvider<MainBloc>(
      packageBuilder: (context) => MainBloc(),
      child: Builder(
        builder: (context) {
          MainBloc mainBloc = Provider.of<MainBloc>(context);
          return FutureBuilder<FirebaseUser>(
            future: mainBloc.getCurrentFirebaseUser(),
            builder: (context, firebaseUserSnapshot) {
              return StreamBuilder<bool>(
                stream: mainBloc.darkModeEnabled,
                initialData: _darkModeEnabled,
                builder: (context, snapshot) {
                  return MaterialApp(
                    theme: ThemeData(
                      primarySwatch: AppColors.primarySwatch,
                      primaryColorBrightness: AppColors.primaryColorBrightness,
                      accentColor: AppColors.primarySwatch.shade300,
                      toggleableActiveColor: AppColors.primarySwatch.shade300,
                      brightness: snapshot.hasData
                          ? (snapshot.data == true ? Brightness.dark : Brightness.light)
                          : MainBloc.darkModeEnabledDefaultValue,
                    ),
                    localizationsDelegates: [
                      const AppLocalizationsDelegate(),
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                    ],
                    supportedLocales: [
                      const Locale('en', ''),
                    ],
                    onGenerateTitle: (context) => AppLocalizations.of(context).appName,
                    home: firebaseUserSnapshot.connectionState == ConnectionState.waiting
                        ? Scaffold(
                            body: Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : (firebaseUserSnapshot.data != null ? HomeScreen(firebaseUser: firebaseUserSnapshot.data) : LoginScreen()),
                    debugShowCheckedModeBanner: false,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
