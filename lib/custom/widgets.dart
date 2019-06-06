import 'package:flutter/gestures.dart' show DragStartBehavior;
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
  final EdgeInsets padding;

  CustomTag(
    this.text, {
    this.disabled = false,
    this.selected = false,
    this.fontSize = 13.0,
    this.padding = const EdgeInsets.symmetric(
      vertical: 4.0,
      horizontal: 8.0,
    ),
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
        padding: padding,
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

class SingleChildScrollViewWithScrollbar extends StatefulWidget {
  const SingleChildScrollViewWithScrollbar({
    Key key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.padding,
    this.primary,
    this.physics,
    this.controller,
    this.child,
    this.dragStartBehavior = DragStartBehavior.down,
    this.scrollbarColor,
    this.scrollbarThickness = 6.0,
  }) : super(key: key);

  final Axis scrollDirection;
  final bool reverse;
  final EdgeInsets padding;
  final bool primary;
  final ScrollPhysics physics;
  final ScrollController controller;
  final Widget child;
  final DragStartBehavior dragStartBehavior;
  final Color scrollbarColor;
  final double scrollbarThickness;

  @override
  _SingleChildScrollViewWithScrollbarState createState() => _SingleChildScrollViewWithScrollbarState();
}

class _SingleChildScrollViewWithScrollbarState extends State<SingleChildScrollViewWithScrollbar> {
  AlwaysVisibleScrollbarPainter _scrollbarPainter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    rebuildPainter();
  }

  @override
  void didUpdateWidget(SingleChildScrollViewWithScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    rebuildPainter();
  }

  void rebuildPainter() {
    final theme = Theme.of(context);
    _scrollbarPainter = AlwaysVisibleScrollbarPainter(
      color: widget.scrollbarColor ?? theme.highlightColor.withOpacity(1.0),
      textDirection: Directionality.of(context),
      thickness: widget.scrollbarThickness,
    );
  }

  @override
  void dispose() {
    _scrollbarPainter?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        foregroundPainter: _scrollbarPainter,
        child: RepaintBoundary(
          child: SingleChildScrollView(
            scrollDirection: widget.scrollDirection,
            reverse: widget.reverse,
            padding: widget.padding,
            primary: widget.primary,
            physics: widget.physics,
            controller: widget.controller,
            dragStartBehavior: widget.dragStartBehavior,
            child: Builder(
              builder: (BuildContext context) {
                _scrollbarPainter.scrollable = Scrollable.of(context);
                return widget.child;
              },
            ),
          ),
        ),
      ),
    );
  }
}

class AlwaysVisibleScrollbarPainter extends ScrollbarPainter {
  AlwaysVisibleScrollbarPainter({
    @required Color color,
    @required TextDirection textDirection,
    @required double thickness,
  }) : super(
          color: color,
          textDirection: textDirection,
          thickness: thickness,
          fadeoutOpacityAnimation: const AlwaysStoppedAnimation(1.0),
        );

  ScrollableState _scrollable;

  ScrollableState get scrollable => _scrollable;

  set scrollable(ScrollableState value) {
    _scrollable?.position?.removeListener(_onScrollChanged);
    _scrollable = value;
    _scrollable?.position?.addListener(_onScrollChanged);
    _onScrollChanged();
  }

  void _onScrollChanged() {
    update(_scrollable.position, _scrollable.axisDirection);
  }

  @override
  void dispose() {
    _scrollable?.position?.removeListener(notifyListeners);
    super.dispose();
  }
}
