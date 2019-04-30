import 'package:flutter/material.dart';

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
