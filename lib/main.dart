import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:edibly/screens/home/home_screen.dart';
import 'package:edibly/values/app_colors.dart';
import 'package:edibly/screens/drawer/drawer_screen.dart';
import 'package:edibly/values/app_localizations.dart';
import 'package:edibly/main_bloc.dart';
import 'package:edibly/values/pref_keys.dart';
import 'package:edibly/bloc_helper/provider.dart';
import 'package:edibly/bloc_helper/app_error.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:edibly/custom/widgets.dart';
import 'package:edibly/screens/login/login_screen.dart';
import 'dart:async';
import 'package:edibly/values/constants.dart';
import 'dart:io';

void main() async {
  final FirebaseApp firebaseApp = await FirebaseApp.configure(
    name: Constants.firebaseAppName,
    options: Platform.isIOS
        ? const FirebaseOptions(
            googleAppID: Constants.firebaseIosAppId,
            gcmSenderID: Constants.firebaseGcmSenderId,
            databaseURL: Constants.database,
          )
        : const FirebaseOptions(
            googleAppID: Constants.firebaseAndroidAppId,
            apiKey: Constants.firebaseApiKey,
            databaseURL: Constants.database,
          ),
  );
  SharedPreferences preferences = await SharedPreferences.getInstance();
  bool darkModeEnabled = preferences.getBool(PrefKeys.darkModeEnabled) ?? MainBloc.darkModeEnabledDefaultValue;
  runApp(_AppWidget(darkModeEnabled));
//  runApp(MaterialApp(
//    title: 'Flutter Database Example',
//    home: MyHomePage(app: app),
//  ));
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
          MainBloc bloc = Provider.of<MainBloc>(context);
          return FutureBuilder(
            future: bloc.getCurrentUser(),
            builder: (context, userSnapshot) {
              return StreamBuilder<bool>(
                initialData: _darkModeEnabled,
                stream: bloc.darkModeEnabled,
                builder: (context, snapshot) {
                  return MaterialApp(
                    theme: ThemeData(
                      primarySwatch: AppColors.primarySwatch,
                      primaryColorBrightness: AppColors.primaryColorBrightness,
                      accentColor: AppColors.primarySwatch.shade300,
                      toggleableActiveColor: AppColors.primarySwatch.shade300,
                      brightness: snapshot.hasData && snapshot.data ? Brightness.dark : Brightness.light,
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
                    home: userSnapshot.data != null ? HomeScreen(userSnapshot.data) : LoginScreen(),
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

class MyHomePage extends StatefulWidget {
  MyHomePage({this.app});

  final FirebaseApp app;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter;
  DatabaseReference _counterRef;
  DatabaseReference _messagesRef;
  StreamSubscription<Event> _counterSubscription;
  StreamSubscription<Event> _messagesSubscription;
  bool _anchorToBottom = false;

  String _kTestKey = 'Hello';
  String _kTestValue = 'world!';
  DatabaseError _error;

  @override
  void initState() {
    super.initState();
    // Demonstrates configuring to the database using a file
    _counterRef = FirebaseDatabase.instance.reference().child('feedPosts');
    // Demonstrates configuring the database directly
    final FirebaseDatabase database = FirebaseDatabase(app: widget.app);
    _messagesRef = database.reference().child('feedPosts');
    database.reference().child('counter').once().then((DataSnapshot snapshot) {
      print('Connected to second database and read ${snapshot.value}');
    });
    database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(10000000);
    _counterRef.keepSynced(true);
    _counterSubscription = _counterRef.onValue.listen((Event event) {
      setState(() {
        _error = null;
        _counter = event.snapshot.value ?? 0;
      });
    }, onError: (Object o) {
      final DatabaseError error = o;
      setState(() {
        _error = error;
      });
    });
    _messagesSubscription = _messagesRef.limitToLast(10).onChildAdded.listen((Event event) {
      print('Child added: ${event.snapshot.value}');
    }, onError: (Object o) {
      final DatabaseError error = o;
      print('Error: ${error.code} ${error.message}');
    });
  }

  @override
  void dispose() {
    super.dispose();
    _messagesSubscription.cancel();
    _counterSubscription.cancel();
  }

  Future<void> _increment() async {
    // Increment counter in transaction.
    final TransactionResult transactionResult = await _counterRef.runTransaction((MutableData mutableData) async {
      mutableData.value = (mutableData.value ?? 0) + 1;
      return mutableData;
    });

    if (transactionResult.committed) {
      _messagesRef.push().set(<String, String>{_kTestKey: '$_kTestValue ${transactionResult.dataSnapshot.value}'});
    } else {
      print('Transaction not committed.');
      if (transactionResult.error != null) {
        print(transactionResult.error.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Database Example'),
      ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: Center(
              child: _error == null
                  ? Text(
                      'Button tapped $_counter time${_counter == 1 ? '' : 's'}.\n\n'
                          'This includes all devices, ever.',
                    )
                  : Text(
                      'Error retrieving button tap count:\n${_error.message}',
                    ),
            ),
          ),
          ListTile(
            leading: Checkbox(
              onChanged: (bool value) {
                setState(() {
                  _anchorToBottom = value;
                });
              },
              value: _anchorToBottom,
            ),
            title: const Text('Anchor to bottom'),
          ),
          Flexible(
            child: FirebaseAnimatedList(
              key: ValueKey<bool>(_anchorToBottom),
              query: _messagesRef,
              reverse: _anchorToBottom,
              sort: _anchorToBottom ? (DataSnapshot a, DataSnapshot b) => b.key.compareTo(a.key) : null,
              itemBuilder: (BuildContext context, DataSnapshot snapshot, Animation<double> animation, int index) {
                return SizeTransition(
                  sizeFactor: animation,
                  child: Text("$index: ${snapshot.value.toString()}"),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _increment,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
