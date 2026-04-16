import 'package:flutter/material.dart';

class AppTheme {
  static const Color bg = Color(0xFF000000);
  static const Color card = Color(0xFF181818);
  static const Color accentRed = Color(0xFFD71921);
  static const Color border = Color(0x14FFFFFF);
}

class PatternTokens {
  static const List<List<int>> dotUpArrow = [
    [2, 0], [1, 1], [2, 1], [3, 1], [0, 2],
    [2, 2], [4, 2], [2, 3], [2, 4],
  ];

  static const List<List<int>> dotDownArrow = [
    [2, 4], [1, 3], [2, 3], [3, 3], [0, 2],
    [2, 2], [4, 2], [2, 1], [2, 0],
  ];

  static const List<List<int>> dotLeftArrow = [
    [0, 2], [1, 1], [1, 2], [1, 3], [2, 0],
    [2, 2], [2, 4], [3, 2], [4, 2],
  ];

  static const List<List<int>> dotRightArrow = [
    [4, 2], [3, 1], [3, 2], [3, 3], [2, 0],
    [2, 2], [2, 4], [1, 2], [0, 2],
  ];
}
