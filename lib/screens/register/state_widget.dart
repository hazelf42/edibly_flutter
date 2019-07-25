import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<GoogleSignInAccount> getSignedInAccount(
    GoogleSignIn googleSignIn) async {
  GoogleSignInAccount account = googleSignIn.currentUser;
  if (account == null) {
    account = await googleSignIn.signInSilently().catchError((e) {
      print(e);
    });
  }
  return account;
}

Future<FirebaseUser> signIntoFirebase(
    GoogleSignInAccount googleSignInAccount) async {
  FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignInAuthentication googleAuth =
      await googleSignInAccount.authentication;
  print(googleAuth.accessToken);
  final AuthCredential credential = GoogleAuthProvider.getCredential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );
  return await _auth.signInWithCredential(credential).catchError((e) {
    print(e);
  });
}

class StateModel {
  bool isLoading;
  FirebaseUser user;
  StateModel({
    this.isLoading = false,
    this.user,
  });
}

class StateWidget extends StatefulWidget {
  final StateModel state;
  final Widget child;

  StateWidget({
    @required this.child,
    this.state,
  });

  // Returns data of the nearest widget _StateDataWidget
  // in the widget tree.
  static _StateWidgetState of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(_StateDataWidget)
            as _StateDataWidget)
        .data;
  }

  @override
  _StateWidgetState createState() => _StateWidgetState();
}

class _StateWidgetState extends State<StateWidget> {
  StateModel state;
  GoogleSignInAccount googleAccount;
  final GoogleSignIn googleSignIn = GoogleSignIn(
      signInOption: SignInOption.standard,
      scopes: ['email', 'https://www.googleapis.com/auth/contacts.readonly']);

  @override
  void initState() {
    super.initState();
    if (widget.state != null) {
      state = widget.state;
    } else {
      state = new StateModel(isLoading: true);
      initUser();
    }
  }

  Future<Null> initUser() async {
    googleAccount = await getSignedInAccount(googleSignIn);
    if (googleAccount == null) {
      setState(() {
        state.isLoading = false;
      });
    } else {
      await signInWithGoogle();
    }
  }

  Future<Null> signInWithGoogle() async {
    if (googleAccount == null) {
      googleAccount = await googleSignIn.signIn();
    }
    await signIntoFirebase(googleAccount).then((firebaseUser) {
      state.user = firebaseUser; // new
      setState(() {
        state.isLoading = false;
        state.user = firebaseUser;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new _StateDataWidget(
      data: this,
      child: widget.child,
    );
  }
}

class _StateDataWidget extends InheritedWidget {
  final _StateWidgetState data;

  _StateDataWidget({
    Key key,
    @required Widget child,
    @required this.data,
  }) : super(key: key, child: child);

  // Rebuild the widgets that inherit from this widget
  // on every rebuild of _StateDataWidget:
  @override
  bool updateShouldNotify(_StateDataWidget old) => true;
}
