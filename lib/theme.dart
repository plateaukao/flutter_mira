

import 'package:flutter/material.dart';

final darkTheme = ThemeData.dark().copyWith(
  sliderTheme: SliderThemeData(
    activeTrackColor: Colors.white,
    inactiveTrackColor: Colors.white.withOpacity(0.3),
    thumbColor: Colors.white,
    overlayColor: Colors.white.withOpacity(0.3),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: ButtonStyle(
      foregroundColor: MaterialStateProperty.all(Colors.white),
    ),
  ),
  iconTheme: const IconThemeData(
    color: Colors.white,
  ),
);

final lightTheme = ThemeData.light().copyWith(
  iconTheme: const IconThemeData(
    color: Colors.blue,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      fontSize: 16,
      color: Colors.blue,
    ),
    bodySmall: TextStyle(
      fontSize: 14,
      color: Colors.blue,
    ),
  ),
);
