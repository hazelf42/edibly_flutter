import 'dart:async';

import 'package:edibly/bloc_helper/app_error.dart';

class Validators {
  /// returns null if valid, otherwise returns error
  static AppError isEmailValid(String email) {
    if (email.isEmpty) {
      return AppError.EMPTY;
    } else if (email.length < 3 || !email.contains("@") || !email.contains(".")) {
      return AppError.INVALID;
    } else {
      return null;
    }
  }

  /// returns null if valid, otherwise returns error
  static AppError isPasswordValid(String password) {
    if (password.length < 6) {
      return AppError.INVALID;
    } else {
      return null;
    }
  }

  final emailValidator = StreamTransformer<String, String>.fromHandlers(
    handleData: (email, sink) {
      AppError error = isEmailValid(email);
      if (error == null) {
        sink.add(email);
      } else {
        sink.addError(error);
      }
    },
  );

  final passwordValidator = StreamTransformer<String, String>.fromHandlers(
    handleData: (password, sink) {
      AppError error = isPasswordValid(password);
      if (error == null) {
        sink.add(password);
      } else {
        sink.addError(error);
      }
    },
  );
}
