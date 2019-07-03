import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

import 'package:edibly/bloc_helper/validators.dart';
import 'package:edibly/bloc_helper/app_error.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

enum UpdatePasswordState {
  INVALID_PASSWORD,
  EMPTY_PASSWORD,
  WRONG_PASSWORD,
  SUCCESSFUL,
  FAILED,
  TRYING,
  IDLE,
}

class DrawerBloc {
  DrawerBloc() {
    _firebaseDatabase.setPersistenceEnabled(true);
    _firebaseDatabase.setPersistenceCacheSizeBytes(10000000);
  }

  /// Variables
  final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;

  /// Subjects
  final _updatePasswordState = BehaviorSubject<UpdatePasswordState>();
  final _oldPassword = BehaviorSubject<String>();
  final _newPassword = BehaviorSubject<String>();

  /// Stream getters
  Stream<UpdatePasswordState> get updatePasswordState => _updatePasswordState.stream;

  Stream<String> get oldPassword => _oldPassword.stream;

  Stream<String> get newPassword => _newPassword.stream;

  // Stream<File> get photo => _photo.stream;

  /// Setters
  Function(UpdatePasswordState) get setUpdatePasswordState => _updatePasswordState.add;

  // Function(File) get setPhoto => _photo.add;

  // Value getters

  // File photoValue() {
  //   return _photo.value;
  // }f


  /// Void functions
  /// 
  
  void setOldPassword(String password) {
    _oldPassword.add(password);
    _updatePasswordState.add(UpdatePasswordState.IDLE);
  }

  void setNewPassword(String password) {
    _newPassword.add(password);
    _updatePasswordState.add(UpdatePasswordState.IDLE);
  }

  void updatePassword({@required FirebaseUser firebaseUser}) {
    final oldPassword = _oldPassword.value;
    final newPassword = _newPassword.value;
    final updatePasswordState = _updatePasswordState.value;

    if (updatePasswordState == UpdatePasswordState.TRYING) return;
    _updatePasswordState.add(UpdatePasswordState.TRYING);

    bool credentialsAreEmpty = false;
    bool credentialsAreInvalid = false;

    if (oldPassword == null || oldPassword.isEmpty) {
      _oldPassword.addError(AppError.EMPTY);
      credentialsAreEmpty = true;
    }
    if (newPassword == null || newPassword.isEmpty) {
      _newPassword.addError(AppError.EMPTY);
      credentialsAreEmpty = true;
    }
    if (!credentialsAreEmpty && (Validators.isPasswordValid(oldPassword) != null || Validators.isPasswordValid(newPassword) != null)) {
      credentialsAreInvalid = true;
    }

    if (!credentialsAreEmpty && !credentialsAreInvalid) {
      firebaseUser
          .reauthenticateWithCredential(EmailAuthProvider.getCredential(
        email: firebaseUser.email,
        password: oldPassword,
      ))
          .then((user) {
        user.updatePassword(newPassword).then((_) {
          _updatePasswordState.add(UpdatePasswordState.SUCCESSFUL);
        });
      }).catchError((error) {
        if (error is PlatformException && error.code == 'ERROR_NETWORK_REQUEST_FAILED') {
          _updatePasswordState.addError(UpdatePasswordState.FAILED);
        } else if (error is PlatformException && error.code == 'ERROR_WRONG_PASSWORD') {
          _updatePasswordState.addError(UpdatePasswordState.WRONG_PASSWORD);
        } else {
          _updatePasswordState.addError(UpdatePasswordState.FAILED);
        }
      });
    } else if (credentialsAreEmpty) {
      _updatePasswordState.add(UpdatePasswordState.IDLE);
    } else if (credentialsAreInvalid) {
      _updatePasswordState.addError(UpdatePasswordState.INVALID_PASSWORD);
    }
  }

  /// Other functions
  Stream<Event> getUser({@required String uid}) {
    //Returns stuff like email, password until we have a better way of storing

    return _firebaseDatabase.reference().child('userProfiles/$uid').onValue;
  }

  Future<http.Response> getVassilibaseUser(String uid) async {
    //Returns all other info: Name, diet, image, etc.

    final url = "http://edibly.vassi.li/api/profiles/$uid";
    final response = await http.get(url);
    return response;
  }


  Future<void> logOut() async {
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
    return _firebaseAuth.signOut();
  }

  Future<bool> changeProfilePicture({
    @required File photo,
  }) async {
    /// upload photo
    String photoUrl;
    if (photo != null) {
      var request = new http.MultipartRequest("POST", Uri.parse("http://edibly.vassi.li/api/upload"));
      request.files.add(http.MultipartFile.fromBytes('file', await photo.readAsBytes(), contentType: MediaType('image', 'jpeg')));
      request.send().then((response) {
        if (response.statusCode == 200) { print("Uploaded!"); }
        else {
          print(response.statusCode);
        }
        photoUrl = "http://edibly.vassi.li/images/${response.request}";
      });
    }
  }


  /// Dispose function
  void dispose() {
    _updatePasswordState.close();
    _oldPassword.close();
    _newPassword.close();
  }
}
