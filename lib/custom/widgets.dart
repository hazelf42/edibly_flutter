import 'package:flutter/material.dart';

import 'package:edibly/values/app_colors.dart';

class SingleLineText extends StatelessWidget {
  final String data;
  final TextStyle style;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final Locale locale;
  final double textScaleFactor;
  final String semanticsLabel;

  const SingleLineText(
    this.data, {
    this.style,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.textScaleFactor,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: style,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: false,
      overflow: TextOverflow.fade,
      textScaleFactor: textScaleFactor,
      maxLines: 1,
      semanticsLabel: semanticsLabel,
    );
  }
}

class BoldFlatButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Color textColor;

  BoldFlatButton({
    @required this.onPressed,
    @required this.text,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      onPressed: onPressed,
      child: SingleLineText(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

class BoldFlatIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Icon icon;
  final Color textColor;

  BoldFlatIconButton({
    @required this.onPressed,
    @required this.text,
    @required this.icon,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return FlatButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: SingleLineText(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

class CustomTag extends StatelessWidget {
  final String text;
  final bool disabled;
  final bool selected;
  final double fontSize;

  CustomTag(
    this.text, {
    this.disabled = false,
    this.selected = false,
    this.fontSize = 13.0,
  });

  BoxDecoration _boxDecoration({@required BuildContext context}) {
    if (disabled) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          width: 1.5,
          color: Theme.of(context).disabledColor,
        ),
      );
    } else if (selected) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          width: 1.5,
          color: AppColors.primarySwatch.shade600,
        ),
        color: AppColors.primarySwatch.shade600,
      );
    } else {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          width: 1.5,
          color: AppColors.primarySwatch.shade600,
        ),
      );
    }
  }

  Color _textColor({@required BuildContext context}) {
    if (disabled) {
      return Theme.of(context).disabledColor;
    } else if (selected) {
      return Colors.white;
    } else {
      return AppColors.primarySwatch.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 4.0,
          horizontal: 8.0,
        ),
        decoration: _boxDecoration(context: context),
        child: SingleLineText(
          text,
          style: TextStyle(
            color: _textColor(context: context),
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}
