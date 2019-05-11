import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:edibly/l10n/messages_all.dart';
import 'package:edibly/values/constants.dart';

class AppLocalizations {
  static Future<AppLocalizations> load(Locale locale) {
    final String name = locale.countryCode.isEmpty ? locale.languageCode : locale.toString();
    final String localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      return AppLocalizations();
    });
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  String get appName => Intl.message('Edibly');

  String get home => Intl.message('Home');

  String get map => Intl.message('Map');

  String get like => Intl.message('Like');

  String get liked => Intl.message('Liked');

  String get comment => Intl.message('Comment');

  String get comments => Intl.message('Comments');

  String get wroteReview => Intl.message('wrote a review');

  String get wroteComment => Intl.message('wrote a comment');

  String get addedTip => Intl.message('added a tip');

  String get bookmarks => Intl.message('Bookmarks');

  String get feedback => Intl.message('Feedback');

  String get myProfile => Intl.message('My profile');

  String get profile => Intl.message('Profile');

  String get darkMode => Intl.message('Dark mode');

  String get vegan => Intl.message('Vegan');

  String get vegetarian => Intl.message('Vegetarian');

  String get disclaimerText =>
      Intl.message('We try our hardest to present correct information but we cannot guarantee it is perfect, accurate, or complete, '
          'so use Edibly at your own risk. Edibly is not a medical service and is not meant to replace the services '
          'of a physician - do not rely on Edibly if you have food allergies or for any other medical purposes. '
          'We recommend you always check for yourself just in case when dining and we do not assume any liability for any inaccuracies.');

  String get glutenFree => Intl.message('Gluten free');

  String get disclaimer => Intl.message('Disclaimer');

  String get resetPassword => Intl.message('Reset password');

  String get resetPasswordSuccessText => Intl.message('We have sent you an email containing a link to reset your password.');

  String get updatePasswordSuccessText => Intl.message('We have updated your password.');

  String get forgotPassword => Intl.message('Forgot password?');

  String get forgotPasswordText => Intl.message('Please enter the email address you used to sign up for an Edibly account. '
      'We will send you an email containing a link to reset your password.');

  String get logIn => Intl.message('Log in');

  String get logOut => Intl.message('Log out');

  String get logOutConfirmationText => Intl.message('Are you sure you want to log out?');

  String get about => Intl.message('About');

  String get email => Intl.message('Email');

  String get send => Intl.message('Send');

  String get search => Intl.message('Search');

  String get searchExampleText => Intl.message('e.g. Veggie burgers, brunch, Indian...');

  String get address => Intl.message('Address');

  String get reset => Intl.message('Reset');

  String get cancel => Intl.message('Cancel');

  String get ok => Intl.message('OK');

  String get errorEmptyEmail => Intl.message('Email cannot be empty.');

  String get errorInvalidEmail => Intl.message('Email is invalid.');

  String get errorEmptyPassword => Intl.message('Password cannot be empty.');

  String get errorInvalidPassword => Intl.message('Password is too short.');

  String get errorWrongPassword => Intl.message('Wrong password.');

  String get emailExampleText => Intl.message('you@example.com');

  String get password => Intl.message('Password');

  String get oldPassword => Intl.message('Old password');

  String get newPassword => Intl.message('New password');

  String get incorrectCredentials => Intl.message('Username or password is incorrect.');

  String get networkRequestFailed => Intl.message('Something went wrong. Check your Internet connection and try again.');

  String get accountNotFound => Intl.message('This email is not tied to any account.');

  String get noPostsByUserText => Intl.message('User has no posts yet.');

  String get noReviewsText => Intl.message('No reviews here yet.');

  String get noTipsText => Intl.message('No tips here yet.');

  String get noPhotosText => Intl.message('No photos here yet.');

  String get noRestaurantsFound => Intl.message('0 restaurants found.');

  String get restaurant => Intl.message('Restaurant');

  String get noBookmarksFound => Intl.message('0 bookmarks found.');

  String get filters => Intl.message('Filters');

  String get rating => Intl.message('Rating');

  String get distance => Intl.message('Distance');

  String get menu => Intl.message('Menu');

  String get reviews => Intl.message('Reviews');

  String get featuredTip => Intl.message('Featured tip');

  String get tips => Intl.message('Tips');

  String get photos => Intl.message('Photos');

  String get addReview => Intl.message('Add review');

  String get addTip => Intl.message('Add tip');

  String get addPhoto => Intl.message('Add photo');

  String get searchScreenFooterTitleText => Intl.message('That is all for now.');

  String get searchScreenFooterDescriptionText => Intl.message(
      'Our database is small, but growing! Adding a review for a new restaurant is quick and easy. We will do the rest on our end.');

  String ratingText(int rating) {
    if (rating == 0) {
      return Intl.message('Any rating');
    } else {
      return Intl.message(
        '$rating or above',
        args: [rating],
      );
    }
  }

  String distanceText(int distance) {
    if (distance == 30) {
      return Intl.message('Any distance');
    } else {
      return Intl.message(
        'Less than $distance km away',
        args: [distance],
      );
    }
  }

  String versionInfo(String version) {
    return Intl.message(
      'Version $version',
      args: [version],
    );
  }

  String get aboutText => Intl.message('Learn more about Edibly at ${Constants.website}.');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return [
      'en',
    ].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
