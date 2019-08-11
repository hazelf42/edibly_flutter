import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/screens/home/home_screen.dart';
import 'package:edibly/screens/register/register_bloc.dart';
import 'package:edibly/screens/register/register_info_screen.dart';
import 'package:edibly/screens/register/register_screen.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import '../../main_bloc.dart';
import 'state_widget.dart';

class RegisterSelectScreen extends StatelessWidget {
  Widget googleButton(RegisterBloc registerBloc, AppLocalizations localizations,
      BuildContext context) {
    return SignInButton(Buttons.Google,
        text: "Continue with Google",
        onPressed: () async =>
            await StateWidget.of(context).signInWithGoogle().then((_) async {
              await MainBloc().getCurrentFirebaseUser().then((user) {
                if (user.metadata.lastSignInTimestamp == null) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => RegisterInfoScreen(user)));
                } else {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              HomeScreen(firebaseUser: user)));
                }
              });
            }));
  }

  Widget facebookButton(RegisterBloc registerBloc,
      AppLocalizations localizations, BuildContext context) {
    return SignInButton(Buttons.Facebook,
        text: "Continue with Facebook",
        onPressed: () async =>
            await StateWidget.of(context).signInWithFacebook().then((_) async {
              await MainBloc().getCurrentFirebaseUser().then((user) {
                if ( (user.metadata.creationTimestamp - user.metadata.lastSignInTimestamp).abs() < 3000 ) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => RegisterInfoScreen(user)));
                } else {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              HomeScreen(firebaseUser: user)));
                }
              });
            }));
  }

  Widget emailButton(RegisterBloc registerBloc, AppLocalizations localizations,
      BuildContext context) {
    return SignInButtonBuilder(
      icon: Icons.email,
      text: "Sign Up With Email",
      backgroundColor: Colors.orange,
      textColor: Colors.white,
      onPressed: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => RegisterScreen())),
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
                        SizedBox(height: 16.0),
                        facebookButton(registerBloc, localizations, context),
                        SizedBox(height: 16.0),
                        emailButton(registerBloc, localizations, context),
                        SizedBox(height: 16.0),
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
