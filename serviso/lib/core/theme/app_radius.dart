import 'package:flutter/material.dart';

/// Centralized border radius tokens for Serviso Neo-Brutalism system.
abstract final class AppRadius {
  /// Base values
  static const double cardValue = 16.0;
  static const double buttonValue = 12.0;
  static const double inputValue = 10.0;
  static const double chipValue = 999.0;
  static const double modalValue = 20.0;

  /// BorderRadius objects
  static const BorderRadius card = BorderRadius.all(Radius.circular(cardValue));
  static const BorderRadius button = BorderRadius.all(Radius.circular(buttonValue));
  static const BorderRadius input = BorderRadius.all(Radius.circular(inputValue));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(chipValue));
  static const BorderRadius modalTop = BorderRadius.vertical(top: Radius.circular(modalValue));
}
