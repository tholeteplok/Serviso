import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Centralized pop-brutalism input field.
///
/// Follows `design (1).md §6.8` + Contra Kit visual:
/// - Resting border: 1.5px hairline `#ECE6DF`
/// - Focus border:  2px `accentPrimary` green
/// - Error border:  1.5px `statusCancelledBorder` red
/// - Radius: 10px (not pill — allows multi-line and labels to breathe)
/// - No hard shadow (hard shadow reserved for tap targets only)
class NeoTextField extends StatelessWidget {
  const NeoTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.minLines,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.autofocus = false,
    this.readOnly = false,
    this.enabled = true,
    this.isDense = false,
    this.prefixText,
    this.initialValue,
    this.textInputAction,
    this.obscureText = false,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final PhosphorIconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int? maxLines;
  final int? minLines;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool autofocus;
  final bool readOnly;
  final bool enabled;
  final bool isDense;
  final String? prefixText;
  final String? initialValue;
  final TextInputAction? textInputAction;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      autofocus: autofocus,
      readOnly: readOnly,
      enabled: enabled,
      textInputAction: textInputAction,
      obscureText: obscureText,
      style: const TextStyle(
        color: AppColors.ink900,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixText: prefixText,
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                size: 18,
                color: AppColors.textSecondary,
              )
            : null,
        suffixIcon: suffixIcon,
        isDense: isDense,
        // Resting border: hairline abu sesuai Contra Kit
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(
            color: AppColors.borderHairline,
            width: 1.5,
          ),
        ),
        // Focus border: accent primary hijau
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(
            color: AppColors.accentMint,
            width: 2,
          ),
        ),
        // Error border: merah
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(
            color: AppColors.statusCancelledBorder,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(
            color: AppColors.statusCancelledBorder,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(
            color: AppColors.borderHairline.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: enabled ? AppColors.bgSurface : AppColors.borderHairline.withValues(alpha: 0.3),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        contentPadding: isDense
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
