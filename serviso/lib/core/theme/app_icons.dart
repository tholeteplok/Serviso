import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Centralized icon registry using Phosphor Icons (Bold for passive, Fill for active/accent)
/// to match the Pastel Pop-Brutalism design system.
abstract final class AppIcons {
  // ---------------------------------------------------------------------------
  // Navigation Icons
  // ---------------------------------------------------------------------------
  static final IconData home = PhosphorIcons.house(PhosphorIconsStyle.bold);
  static final IconData homeFill = PhosphorIcons.house(PhosphorIconsStyle.fill);

  static final IconData queue = PhosphorIcons.clipboardText(PhosphorIconsStyle.bold);
  static final IconData queueFill = PhosphorIcons.clipboardText(PhosphorIconsStyle.fill);

  static final IconData inventory = PhosphorIcons.package(PhosphorIconsStyle.bold);
  static final IconData inventoryFill = PhosphorIcons.package(PhosphorIconsStyle.fill);

  static final IconData report = PhosphorIcons.chartLineUp(PhosphorIconsStyle.bold);
  static final IconData reportFill = PhosphorIcons.chartLineUp(PhosphorIconsStyle.fill);

  // ---------------------------------------------------------------------------
  // Actions & Controls
  // ---------------------------------------------------------------------------
  static final IconData add = PhosphorIcons.plus(PhosphorIconsStyle.bold);
  static final IconData search = PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold);
  static final IconData filter = PhosphorIcons.slidersHorizontal(PhosphorIconsStyle.bold);
  static final IconData back = PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold);
  static final IconData close = PhosphorIcons.x(PhosphorIconsStyle.bold);
  static final IconData check = PhosphorIcons.check(PhosphorIconsStyle.bold);
  static final IconData checkCircle = PhosphorIcons.checkCircle(PhosphorIconsStyle.bold);
  static final IconData checkCircleFill = PhosphorIcons.checkCircle(PhosphorIconsStyle.fill);
  static final IconData trash = PhosphorIcons.trash(PhosphorIconsStyle.bold);
  static final IconData edit = PhosphorIcons.pencilSimple(PhosphorIconsStyle.bold);
  static final IconData share = PhosphorIcons.shareNetwork(PhosphorIconsStyle.bold);
  static final IconData print = PhosphorIcons.printer(PhosphorIconsStyle.bold);
  static final IconData refresh = PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.bold);

  // ---------------------------------------------------------------------------
  // Workshop & POS Domain
  // ---------------------------------------------------------------------------
  static final IconData wallet = PhosphorIcons.wallet(PhosphorIconsStyle.bold);
  static final IconData walletFill = PhosphorIcons.wallet(PhosphorIconsStyle.fill);
  static final IconData money = PhosphorIcons.money(PhosphorIconsStyle.bold);
  static final IconData receipt = PhosphorIcons.receipt(PhosphorIconsStyle.bold);
  static final IconData wrench = PhosphorIcons.wrench(PhosphorIconsStyle.bold);
  static final IconData wrenchFill = PhosphorIcons.wrench(PhosphorIconsStyle.fill);
  static final IconData motorcycle = PhosphorIcons.motorcycle(PhosphorIconsStyle.bold);
  static final IconData car = PhosphorIcons.car(PhosphorIconsStyle.bold);
  static final IconData part = PhosphorIcons.cube(PhosphorIconsStyle.bold);
  static final IconData partFill = PhosphorIcons.cube(PhosphorIconsStyle.fill);
  static final IconData user = PhosphorIcons.user(PhosphorIconsStyle.bold);
  static final IconData userFill = PhosphorIcons.user(PhosphorIconsStyle.fill);
  static final IconData warning = PhosphorIcons.warning(PhosphorIconsStyle.bold);
  static final IconData clock = PhosphorIcons.clock(PhosphorIconsStyle.bold);
}
