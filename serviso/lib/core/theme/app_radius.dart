import 'package:flutter/material.dart';

/// Centralized border radius tokens for Serviso Design System v2 (Soft Brutalism).
abstract final class AppRadius {
  /// Base values - aligned with DS v2 spec
  static const double cardValue = 20.0;
  static const double buttonValue = 14.0;
  static const double inputValue = 12.0;
  static const double chipValue = 999.0;
  static const double modalValue = 20.0;
  static const double badgeValue = 6.0;
  static const double chipSmallValue = 8.0;
  static const double navBarValue = 32.0;
  static const double chartBarValue = 4.0;

  /// BorderRadius objects
  static const BorderRadius card = BorderRadius.all(Radius.circular(cardValue));
  static const BorderRadius button = BorderRadius.all(Radius.circular(buttonValue));
  static const BorderRadius input = BorderRadius.all(Radius.circular(inputValue));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(chipValue));
  static const BorderRadius modal = BorderRadius.all(Radius.circular(modalValue));
  static const BorderRadius modalTop = BorderRadius.vertical(top: Radius.circular(modalValue));
  static const BorderRadius badge = BorderRadius.all(Radius.circular(badgeValue));
  static const BorderRadius chipSmall = BorderRadius.all(Radius.circular(chipSmallValue));
  static const BorderRadius navBar = BorderRadius.all(Radius.circular(navBarValue));
  static const BorderRadius chartBar = BorderRadius.vertical(top: Radius.circular(chartBarValue));
}