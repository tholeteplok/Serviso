import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// DS v2 Warm Industrial — Input Field
/// Spec: docs/serviso-design-system-v2.html § detail-input + §4 pressable
/// - Resting: 1.5px ink #111 (decision A — tegas)
/// - Focus: 2px ink + outer ring 3px #FFE9A6 (amberDim) + soft shadow
/// - Error: 1.5 #C0392B bg #FFF3EF • Success: 1.5 mint #3FBE85 bg #F0FAF5
/// - Radius 12, height 44, hover #FFFBF7
class NeoTextField extends StatefulWidget {
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
  State<NeoTextField> createState() => _NeoTextFieldState();
}

class _NeoTextFieldState extends State<NeoTextField> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(() {
      if (mounted) setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnim = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedContainer(
      duration: Duration(milliseconds: disableAnim ? 0 : 160),
      decoration: BoxDecoration(
        borderRadius: AppRadius.input,
        boxShadow: _hasFocus && widget.enabled
            ? const [
                BoxShadow(color: Color(0xFFFFE9A6), blurRadius: 0, spreadRadius: 3),
                BoxShadow(color: Color(0x12000000), offset: Offset(0, 4), blurRadius: 16),
              ]
            : null,
      ),
      child: TextFormField(
      controller: widget.controller,
      initialValue: widget.initialValue,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      textCapitalization: widget.textCapitalization,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      textInputAction: widget.textInputAction,
      obscureText: widget.obscureText,
      style: AppTypography.inter(
        color: AppColors.ink900,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixText: widget.prefixText,
        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                size: 18,
                color: AppColors.textSecondary,
              )
            : null,
        suffixIcon: widget.suffixIcon,
        isDense: widget.isDense,
        // DS v2: resting 1.5 ink — decision A
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(
            color: AppColors.borderInk,
            width: 1.5,
          ),
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.borderInk, width: 1.5),
        ),
        // Focus: 2px ink — ring drawn by outer AnimatedContainer (amberDim)
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(
            color: AppColors.borderInk,
            width: 2,
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(
            color: Color(0xFFC0392B),
            width: 1.5,
          ),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(
            color: Color(0xFFC0392B),
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
        fillColor: !widget.enabled
            ? AppColors.borderHairline.withValues(alpha: 0.3)
            : null,
        labelStyle: AppTypography.inter(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: AppTypography.inter(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        contentPadding: widget.isDense
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      ),
    );
  }
}
