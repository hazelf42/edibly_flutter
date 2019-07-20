import 'dart:math';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/bloc_helper/validators.dart';

enum RegisterState {
  EMAIL_IN_USE,
  SUCCESSFUL,
  FAILED,
  TRYING,
  IDLE,
}

class RegisterBloc extends Object with Validators {
  final AppLocalizations localizations;

  RegisterBloc({@required this.localizations});

  /// Local  variables
  final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;
  final List<String> _defaultPhotos = [
    'https://i.imgur.com/UNBOnUa.png',
    'https://i.imgur.com/fkzgNDn.png',
    'https://i.imgur.com/rsdDzFO.png',
    'https://i.imgur.com/3AbGr5v.png',
    'https://i.imgur.com/092Far6.png',
  ];

  /// Subjects
  final _registerState = BehaviorSubject<RegisterState>();
  final _glutenFree = BehaviorSubject<bool>();
  final _firstName = BehaviorSubject<String>();
  final _lastName = BehaviorSubject<String>();
  final _password = BehaviorSubject<String>();
  final _email = BehaviorSubject<String>();
  final _vegan = BehaviorSubject<bool>();
  final _photo = BehaviorSubject<File>();

  /// Stream getters

  Stream<RegisterState> get registerState => _registerState.stream;

  Stream<bool> get glutenFree => _glutenFree.stream;

  Stream<String> get firstName => _firstName.stream;

  Stream<String> get lastName => _lastName.stream;

  Stream<String> get password => _password.stream;

  Stream<String> get email => _email.stream;

  Stream<bool> get vegan => _vegan.stream;

  Stream<File> get photo => _photo.stream;

  /// Functions
  Future<FirebaseUser> getCurrentFirebaseUser() async {
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
    return await _firebaseAuth.currentUser();
  }

  void setGlutenFree(bool value) {
    _glutenFree.add(value);
  }

  void setFirstName(String firstName) {
    _firstName.add(firstName);
    _registerState.add(RegisterState.IDLE);
  }

  void setLastName(String lastName) {
    _lastName.add(lastName);
    _registerState.add(RegisterState.IDLE);
  }

  void setPassword(String password) {
    _password.add(password);
    _registerState.add(RegisterState.IDLE);
  }

  void setEmail(String email) {
    _email.add(email);
    _registerState.add(RegisterState.IDLE);
  }

  void setVegan(bool value) {
    _vegan.add(value);
  }

  void setPhoto(File photo) {
    _photo.add(photo);
  }

  void register() async {
    final photo = _photo.value;
    final vegan = _vegan.value ?? true;
    final email = _email.value;
    final password = _password.value;
    final lastName = _lastName.value;
    final firstName = _firstName.value;
    final glutenFree = _glutenFree.value ?? false;
    final registerState = _registerState.value;

    if (registerState == RegisterState.TRYING) return;
    _registerState.add(RegisterState.TRYING);

    bool formIsValid = true;

    /// empty?
    if (email == null || email.isEmpty) {
      _email.addError(localizations.errorEmptyField);
      formIsValid = false;
    }
    if (password == null || password.isEmpty) {
      _password.addError(localizations.errorEmptyField);
      formIsValid = false;
    }
    if (lastName == null || lastName.isEmpty) {
      _lastName.addError(localizations.errorEmptyField);
      formIsValid = false;
    }
    if (firstName == null || firstName.isEmpty) {
      _firstName.addError(localizations.errorEmptyField);
      formIsValid = false;
    }

    /// invalid?
    if (email != null && email.isNotEmpty && Validators.isEmailValid(email) != null) {
      _email.addError(localizations.errorInvalidEmail);
      formIsValid = false;
    }
    if (password != null && password.isNotEmpty && Validators.isPasswordValid(password) != null) {
      _password.addError(localizations.errorInvalidPassword);
      formIsValid = false;
    }

    if (formIsValid)  {
      final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
      _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password).then((firebaseUser) async {
        /// upload photo
        String photoUrl;
        

        if (photo != null) {
          photoUrl = await getImageUrl(photo: photo);

        } else {
          photoUrl = _defaultPhotos.elementAt(Random().nextInt(_defaultPhotos.length));
        }

        _firebaseDatabase.reference().child('userProfiles').child(firebaseUser.uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'photoUrl': photoUrl,
          'dietName': vegan ? 'Vegan' : 'Vegetarian',
          'isGlutenFree': glutenFree,
        }).then((_) async
        {
          await http.post("http://edibly.vassi.li/api/profiles/add", body: json.encode({
            'firstname' : firstName,
            'lastname' : lastName,
            'photo' : photoUrl,
            'veglevel' : vegan ? 2 : 1,
            'glutenfree' : glutenFree ? 1 : 0,
            'uid' : firebaseUser.uid
            }
          ));
        }
        ).then(
          
          (_) {
          _registerState.add(RegisterState.SUCCESSFUL);
        }).catchError((error) {
          _registerState.addError(RegisterState.FAILED);
        });
      }).catchError((error) {
        if (error is PlatformException && error.code == 'ERROR_EMAIL_ALREADY_IN_USE') {
          _registerState.addError(RegisterState.EMAIL_IN_USE);
        } else {
          _registerState.addError(RegisterState.FAILED);
        }
      });
    } else {
      _registerState.add(RegisterState.IDLE);
    }
  }

Future<String> getImageUrl({
     @required File photo,
  }) async {
    /// upload photo
    Future<String> photoUrl;
    if (photo != null) {
      var request =  http.MultipartRequest("POST", Uri.parse("http://edibly.vassi.li/api/upload"));
        request.files.add(http.MultipartFile.fromBytes('file', await photo.readAsBytes(), contentType: MediaType('image', 'jpeg')));
       await request.send().then((response) {
        if (response.statusCode == 200) { photoUrl =  response.stream.bytesToString();}
        else {
          SnackBar(content: Text("An error occurred."));
        }
      });
    }
    return photoUrl;
  }

  void dispose() {
    _registerState.close();
    _glutenFree.close();
    _firstName.close();
    _lastName.close();
    _password.close();
    _email.close();
    _vegan.close();
    _photo.close();
  }
}