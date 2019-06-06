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

  String get discover => Intl.message('Discover');

  String get like => Intl.message('Like');

  String get liked => Intl.message('Liked');

  String get comment => Intl.message('Comment');

  String get comments => Intl.message('Comments');

  String get wroteReview => Intl.message('wrote a review');

  String get addedPhoto => Intl.message('added a photo');

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

  String get tipAddedSuccessText => Intl.message('Thanks for the tip.');

  String get reviewAddedSuccessText => Intl.message('Thanks for the review.');

  String get photoAddedSuccessText => Intl.message('Thanks for the photo.');

  String get updatePasswordSuccessText => Intl.message('We have updated your password.');

  String get forgotPassword => Intl.message('Forgot password?');

  String get forgotPasswordText => Intl.message('Please enter the email address you used to sign up for an Edibly account. '
      'We will send you an email containing a link to reset your password.');

  String get logIn => Intl.message('Log in');

  String get logOut => Intl.message('Log out');

  String get logOutConfirmationText => Intl.message('Are you sure you want to log out?');

  String get deleteConfirmationText => Intl.message('Are you sure you want delete this item?');

  String get about => Intl.message('About');

  String get email => Intl.message('Email');

  String get events => Intl.message('Events');

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

  String get errorEmptyTextField => Intl.message('Text field cannot be empty.');

  String get errorEmptyField => Intl.message('This field cannot be empty.');

  String get errorInvalidPassword => Intl.message('Password is too short.');

  String get errorWrongPassword => Intl.message('Wrong password.');

  String get emailExampleText => Intl.message('you@example.com');

  String get tipExampleText => Intl.message('e.g. \"You can substitute a veggie patty for any burger.');

  String get beTheFirstToLeaveTip => Intl.message('Be the first to leave a tip.');

  String get beTheFirstToLeaveTipHelpText => Intl.message('Helpful hint for eating here? Share it below.');

  String get password => Intl.message('Password');

  String get oldPassword => Intl.message('Old password');

  String get newPassword => Intl.message('New password');

  String get next => Intl.message('Next');

  String get nearby => Intl.message('Nearby');

  String get delete => Intl.message('Delete');

  String get incorrectCredentials => Intl.message('Username or password is incorrect.');

  String get signUpPreText => Intl.message('Don\'t have an account?');

  String get signUp => Intl.message('Sign up!');

  String get networkRequestFailed => Intl.message('Something went wrong. Check your Internet connection and try again.');

  String get emailIsAlreadyInUse => Intl.message('Email is already in use.');

  String get accountNotFound => Intl.message('This email is not tied to any account.');

  String get noPostsByUserText => Intl.message('User has no posts yet.');

  String get noReviewsText => Intl.message('No reviews here yet.');

  String get noTipsText => Intl.message('No tips here yet.');

  String get nothingHereText => Intl.message('Nothing here yet.');

  String get noEvents => Intl.message('No events.');

  String get other => Intl.message('Other');

  String get noVeganOptionsText => Intl.message('Either there are no vegan options, or an error has occured.');

  String get noVegetarianOptionsText => Intl.message('Either there are no vegetarian options, or an error has occured.');

  String get showVegetarianOptions => Intl.message('Show vegetarian options');

  String get noPhotosText => Intl.message('No photos here yet.');

  String get noRestaurantsFound => Intl.message('0 restaurants found.');

  String get restaurant => Intl.message('Restaurant');

  String get restaurantName => Intl.message('Restaurant name');

  String get restaurantLocation => Intl.message('Restaurant location');

  String get firstName => Intl.message('First name');

  String get lastName => Intl.message('Last name');

  String get noBookmarksFound => Intl.message('0 bookmarks found.');

  String get filters => Intl.message('Filters');

  String get rating => Intl.message('Rating');

  String get distance => Intl.message('Distance');

  String get menu => Intl.message('Menu');

  String get reviews => Intl.message('Reviews');

  String get featuredTip => Intl.message('Featured tip');

  String get featured => Intl.message('Featured');

  String get tips => Intl.message('Tips');

  String get photos => Intl.message('Photos');

  String get photo => Intl.message('Photo');

  String get addReview => Intl.message('Add review');

  String get addTip => Intl.message('Add tip');

  String get addDish => Intl.message('Add a dish');

  String get addTags => Intl.message('Add tags (max: 3)');

  String get add => Intl.message('Add');

  String get appetizers => Intl.message('Appetizers');

  String get entrees => Intl.message('Entrees');

  String get sides => Intl.message('Sides');

  String get addPhoto => Intl.message('Add photo');

  String get rateTheRestaurant => Intl.message('Rate the restaurant *');

  String get pickFromGallery => Intl.message('Pick from gallery');

  String get takePicture => Intl.message('Take a picture');

  String get yourCanWriteYourReviewHere => Intl.message('You can write your review here.');

  String get searchScreenFooterTitleText => Intl.message('That is all for now.');

  String get searchScreenFooterDescriptionText => Intl.message(
      'Our database is small, but growing! Adding a review for a new restaurant is quick and easy. We will do the rest on our end.');

  String get vegetarianUponRequest => Intl.message('Vegetarian upon request');

  String get veganUponRequest => Intl.message('Vegan upon request');

  String get reviewDishesQuestionText => Intl.message('What did you have to eat?');

  String get reviewDishesHelpText => Intl.message('Swipe right to upvote, left to downvote, tap to deselect.');

  String get tagMaximumReached => Intl.message('You have selected maximum number of tags.');

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

  List<String> get tagArray {
    return [
      Intl.message('Variety'),
      Intl.message('Great Food'),
      Intl.message('Service'),
      Intl.message('Atmosphere'),
      Intl.message('Price'),
      Intl.message('Healthy'),
    ];
  }
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
