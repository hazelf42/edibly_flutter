import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

import 'package:edibly/bloc_helper/validators.dart';
import 'package:edibly/bloc_helper/app_error.dart';

enum LoginState {
  INCORRECT_CREDENTIALS,
  SUCCESSFUL,
  FAILED,
  TRYING,
  IDLE,
}

enum ForgotPasswordState {
  ACCOUNT_NOT_FOUND,
  INVALID_EMAIL,
  EMPTY_EMAIL,
  SUCCESSFUL,
  FAILED,
  TRYING,
  IDLE,
}

class LoginBloc extends Object with Validators {
  /// Subjects
  final _forgotPasswordState = BehaviorSubject<ForgotPasswordState>();
  final _loginState = BehaviorSubject<LoginState>();
  final _password = BehaviorSubject<String>();
  final _email = BehaviorSubject<String>();

  /// Stream getters
  Stream<ForgotPasswordState> get forgotPasswordState => _forgotPasswordState.stream;

  Stream<LoginState> get loginState => _loginState.stream;

  Stream<String> get password => _password.stream;

  Stream<String> get email => _email.stream;

  /// Setters
  Function(ForgotPasswordState) get setForgotPasswordState => _forgotPasswordState.add;

  /// Functions
  Future<FirebaseUser> getCurrentUser() async {
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
    return await _firebaseAuth.currentUser();
  }

  void resetPassword(String email) {
    ForgotPasswordState forgotPasswordState = _forgotPasswordState.value;

    if (forgotPasswordState == ForgotPasswordState.TRYING) return;
    _forgotPasswordState.add(ForgotPasswordState.TRYING);

    bool credentialsAreEmpty = false;
    bool credentialsAreInvalid = false;

    if (email == null || email.isEmpty) {
      _forgotPasswordState.addError(ForgotPasswordState.EMPTY_EMAIL);
      credentialsAreEmpty = true;
    }
    if (!credentialsAreEmpty && (Validators.isEmailValid(email) != null)) {
      credentialsAreInvalid = true;
    }

    if (!credentialsAreEmpty && !credentialsAreInvalid) {
      final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
      _firebaseAuth.sendPasswordResetEmail(email: email).then((firebaseUser) {
        _forgotPasswordState.add(ForgotPasswordState.SUCCESSFUL);
      }).catchError((error) {
        if (error is PlatformException && error.code == 'ERROR_NETWORK_REQUEST_FAILED') {
          _forgotPasswordState.addError(ForgotPasswordState.FAILED);
        } else {
          _forgotPasswordState.addError(ForgotPasswordState.ACCOUNT_NOT_FOUND);
        }
      });
    } else if (credentialsAreEmpty) {
      _forgotPasswordState.addError(ForgotPasswordState.EMPTY_EMAIL);
    } else if (credentialsAreInvalid) {
      _forgotPasswordState.addError(ForgotPasswordState.INVALID_EMAIL);
    }
  }

  void setEmail(String email) {
    _email.add(email);
    _loginState.add(LoginState.IDLE);
  }

  void setPassword(String password) {
    _password.add(password);
    _loginState.add(LoginState.IDLE);
  }

  void logIn() {
    final email = _email.value;
    final password = _password.value;
    final loginState = _loginState.value;

    if (loginState == LoginState.TRYING) return;
    _loginState.add(LoginState.TRYING);

    bool credentialsAreEmpty = false;
    bool credentialsAreInvalid = false;

    if (email == null || email.isEmpty) {
      _email.addError(AppError.EMPTY);
      credentialsAreEmpty = true;
    }
    if (password == null || password.isEmpty) {
      _password.addError(AppError.EMPTY);
      credentialsAreEmpty = true;
    }
    if (!credentialsAreEmpty && (Validators.isEmailValid(email) != null || Validators.isPasswordValid(password) != null)) {
      credentialsAreInvalid = true;
    }

    if (!credentialsAreEmpty && !credentialsAreInvalid) {
      final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
      _firebaseAuth.signInWithEmailAndPassword(email: email, password: password).then((firebaseUser) {
        _loginState.add(LoginState.SUCCESSFUL);
      }).catchError((error) {
        if (error is PlatformException && error.code == 'ERROR_NETWORK_REQUEST_FAILED') {
          _loginState.addError(LoginState.FAILED);
        } else {
          _loginState.addError(LoginState.INCORRECT_CREDENTIALS);
        }
      });
    } else if (credentialsAreEmpty) {
      _loginState.add(LoginState.IDLE);
    } else if (credentialsAreInvalid) {
      _loginState.addError(LoginState.INCORRECT_CREDENTIALS);
    }
  }

  void dispose() {
    _forgotPasswordState.close();
    _loginState.close();
    _password.close();
    _email.close();
  }
}