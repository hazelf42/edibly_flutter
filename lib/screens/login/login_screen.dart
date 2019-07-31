import 'package:flutter/material.dart';

import 'package:edibly/screens/register/register_select_screen.dart';
import 'package:edibly/screens/login/login_bloc.dart';
import 'package:edibly/screens/home/home_screen.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/bloc_helper/app_error.dart';
import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/screens/register/register_bloc.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:edibly/screens/register/state_widget.dart';
import 'package:edibly/screens/register/register_info_screen.dart';

import '../../main_bloc.dart';

class LoginScreen extends StatelessWidget {
  Widget emailField(LoginBloc loginBloc, AppLocalizations localizations) {
    return StreamBuilder<String>(
      stream: loginBloc.email,
      builder: (context, emailSnapshot) {
        return StreamBuilder<LoginState>(
          stream: loginBloc.loginState,
          builder: (context, loginStateSnapshot) {
            return TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                labelText: localizations.email,
                prefixIcon: Icon(
                  Icons.person,
                  color: emailSnapshot.hasError
                      ? Theme.of(context).errorColor
                      : null,
                ),
                errorText: emailSnapshot.hasError &&
                        emailSnapshot.error == AppError.EMPTY
                    ? localizations.errorEmptyEmail
                    : null,
                hintText: localizations.emailExampleText,
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: loginBloc.setEmail,
              enabled:
                  loginStateSnapshot.data == LoginState.TRYING ? false : true,
            );
          },
        );
      },
    );
  }

  Widget passwordField(LoginBloc loginBloc, AppLocalizations localizations) {
    return StreamBuilder<String>(
      stream: loginBloc.password,
      builder: (context, passwordSnapshot) {
        return StreamBuilder<LoginState>(
          stream: loginBloc.loginState,
          builder: (context, loginStateSnapshot) {
            return TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                labelText: localizations.password,
                prefixIcon: Icon(
                  Icons.lock,
                  color: passwordSnapshot.hasError
                      ? Theme.of(context).errorColor
                      : null,
                ),
                errorText: passwordSnapshot.hasError &&
                        passwordSnapshot.error == AppError.EMPTY
                    ? localizations.errorEmptyPassword
                    : null,
              ),
              obscureText: true,
              onChanged: loginBloc.setPassword,
              enabled:
                  loginStateSnapshot.data == LoginState.TRYING ? false : true,
            );
          },
        );
      },
    );
  }

  Widget googleButton(RegisterBloc registerBloc, AppLocalizations localizations,
      BuildContext context) {
    return SignInButton(Buttons.Google,
        mini: true,
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
        mini: true,
        text: "Continue with Facebook",
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

  Widget submitButton(LoginBloc loginBloc, AppLocalizations localizations) {
    String loginStateToString(LoginState loginState) {
      switch (loginState) {
        case LoginState.INCORRECT_CREDENTIALS:
          return localizations.incorrectCredentials;
        case LoginState.FAILED:
          return localizations.networkRequestFailed;
        default:
          return '';
      }
    }

    return StreamBuilder<LoginState>(
      stream: loginBloc.loginState,
      builder: (context, snapshot) {
        if (snapshot.data == LoginState.SUCCESSFUL) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            loginBloc.getCurrentFirebaseUser().then((user) {
              if (user != null) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => HomeScreen(firebaseUser: user),
                  ),
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
                      loginStateToString(snapshot.error),
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
            snapshot.data == LoginState.TRYING
                ? CircularProgressIndicator()
                : RaisedButton(
                    color: Colors.orange.shade700,
                    onPressed: loginBloc.logIn,
                    child: SingleLineText(localizations.logIn),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
          ],
        );
      },
    );
  }

  Widget forgotPasswordButton(
      LoginBloc loginBloc, AppLocalizations localizations) {
    return StreamBuilder<LoginState>(
      stream: loginBloc.loginState,
      builder: (context, snapshot) {
        return FlatButton(
          onPressed: snapshot.data == LoginState.TRYING
              ? null
              : () {
                  showForgotPasswordDialog(context, loginBloc, localizations);
                },
          child: SingleLineText(
            localizations.forgotPassword,
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  void showForgotPasswordDialog(BuildContext context, LoginBloc loginBloc,
      AppLocalizations localizations) {
    String forgotPasswordStateToString(
        ForgotPasswordState forgotPasswordState) {
      switch (forgotPasswordState) {
        case ForgotPasswordState.EMPTY_EMAIL:
          return localizations.errorEmptyEmail;
        case ForgotPasswordState.INVALID_EMAIL:
          return localizations.errorInvalidEmail;
        case ForgotPasswordState.ACCOUNT_NOT_FOUND:
          return localizations.accountNotFound;
        default:
          return '';
      }
    }

    TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return StreamBuilder<ForgotPasswordState>(
            stream: loginBloc.forgotPasswordState,
            builder: (context, snapshot) {
              if (snapshot.data == ForgotPasswordState.SUCCESSFUL) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pop(true);
                });
              }
              return AlertDialog(
                title: Text(localizations.forgotPassword),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      localizations.forgotPasswordText,
                      style: TextStyle(
                        fontSize: 12.0,
                      ),
                    ),
                    SizedBox(
                      height: 16.0,
                    ),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        labelText: localizations.email,
                        prefixIcon: Icon(
                          Icons.person,
                        ),
                        errorText: snapshot.hasError
                            ? forgotPasswordStateToString(snapshot.error)
                            : null,
                        hintText: localizations.emailExampleText,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        loginBloc
                            .setForgotPasswordState(ForgotPasswordState.IDLE);
                      },
                      enabled: snapshot.data == ForgotPasswordState.TRYING
                          ? false
                          : true,
                    ),
                  ],
                ),
                contentPadding:
                    const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0.0),
                actions: <Widget>[
                  FlatButton(
                    child: Text(localizations.cancel.toUpperCase()),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  FlatButton(
                    child: Text(localizations.send.toUpperCase()),
                    onPressed: snapshot.data == ForgotPasswordState.TRYING
                        ? null
                        : () {
                            loginBloc.resetPassword(
                              email: emailController.text,
                            );
                          },
                  )
                ],
              );
            });
      },
    ).then((emailSent) {
      if (emailSent is bool && emailSent) {
        final snackBar = SnackBar(
          content: Text(localizations.resetPasswordSuccessText),
        );
        Scaffold.of(context).showSnackBar(snackBar);
      }
      loginBloc.setForgotPasswordState(ForgotPasswordState.IDLE);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DisposableProvider<LoginBloc>(
      packageBuilder: (context) => LoginBloc(),
      child: Builder(
        builder: (context) {
          final LoginBloc loginBloc = Provider.of<LoginBloc>(context);
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
                        SingleLineText(
                          localizations.appName,
                          style: TextStyle(
                            fontSize: 32.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 16.0),
                        Row(
                          children: <Widget>[
                            googleButton(
                                RegisterBloc(localizations: localizations),
                                localizations,
                                context),
                            facebookButton(
                                RegisterBloc(localizations: localizations),
                                localizations,
                                context),
                          ],
                        ),
                        SizedBox(height: 16.0),
                        emailField(loginBloc, localizations),
                        SizedBox(height: 16.0),
                        passwordField(loginBloc, localizations),
                        SizedBox(height: 16.0),
                        submitButton(loginBloc, localizations),
                        SizedBox(height: 16.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            SingleLineText(
                              localizations.signUpPreText,
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            Container(width: 10.0),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RegisterSelectScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                  horizontal: 10.0,
                                ),
                                child: SingleLineText(
                                  localizations.signUp,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        forgotPasswordButton(loginBloc, localizations),
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
