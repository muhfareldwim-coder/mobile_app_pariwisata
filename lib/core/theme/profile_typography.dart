import 'package:flutter/material.dart';

class ProfileTypography {
  static const String fontFamily = 'Poppins';

  static ThemeData apply(ThemeData theme) {
    return theme.copyWith(
      textTheme: theme.textTheme.apply(fontFamily: fontFamily),
      primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: fontFamily),
    );
  }
}
