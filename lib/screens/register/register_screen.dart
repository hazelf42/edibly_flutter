import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/screens/register/register_bloc.dart';
import 'package:edibly/screens/register/register_info_screen.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:flutter/material.dart';

import 'state_widget.dart';

class RegisterScreen extends StatelessWidget {
  Widget firstNameField(
      RegisterBloc registerBloc, AppLocalizations localizations) {
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
                  color: passwordSnapshot.hasError
                      ? Theme.of(context).errorColor
                      : null,
                ),
                errorText: passwordSnapshot.error,
              ),
              onChanged: registerBloc.setFirstName,
              enabled:
                  firstNameSnapshot.data == RegisterState.TRYING ? false : true,
            );
          },
        );
      },
    );
  }

  Widget lastNameField(
      RegisterBloc registerBloc, AppLocalizations localizations) {
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
                  color: lastNameSnapshot.hasError
                      ? Theme.of(context).errorColor
                      : null,
                ),
                errorText: lastNameSnapshot.error,
              ),
              onChanged: registerBloc.setLastName,
              enabled: registerStateSnapshot.data == RegisterState.TRYING
                  ? false
                  : true,
            );
          },
        );
      },
    );
  }

  Widget passwordField(
      RegisterBloc registerBloc, AppLocalizations localizations) {
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
                  color: passwordSnapshot.hasError
                      ? Theme.of(context).errorColor
                      : null,
                ),
                errorText: passwordSnapshot.error,
              ),
              obscureText: true,
              onChanged: registerBloc.setPassword,
              enabled: registerStateSnapshot.data == RegisterState.TRYING
                  ? false
                  : true,
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
                  color: emailSnapshot.hasError
                      ? Theme.of(context).errorColor
                      : null,
                ),
                errorText: emailSnapshot.error,
                hintText: localizations.emailExampleText,
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: registerBloc.setEmail,
              enabled: registerStateSnapshot.data == RegisterState.TRYING
                  ? false
                  : true,
            );
          },
        );
      },
    );
  }

  Widget nextButton(RegisterBloc registerBloc, AppLocalizations localizations) {
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
          registerBloc.getCurrentFirebaseUser().then((user) {
            if (user != null) {
              {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => RegisterInfoScreen(user),
                ));
              }
            }
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
                        emailField(registerBloc, localizations),
                        SizedBox(height: 16.0),
                        passwordField(registerBloc, localizations),
                        SizedBox(height: 16.0),
                        firstNameField(registerBloc, localizations),
                        SizedBox(height: 16.0),
                        lastNameField(registerBloc, localizations),
                        SizedBox(height: 16.0),
                        nextButton(registerBloc, localizations),
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
