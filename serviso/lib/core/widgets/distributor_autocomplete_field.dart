import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/inventori/controllers/part_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Centralized Autocomplete Field for Distributor/Supplier name inputs.
/// Automatically queries previously saved distributors and provides fuzzy
/// suggestions while allowing free-form input of new distributors.
class DistributorAutocompleteField extends ConsumerStatefulWidget {
  const DistributorAutocompleteField({
    super.key,
    required this.controller,
    this.focusNode,
    this.labelText = 'Distributor / Pemasok (Opsional)',
    this.hintText = 'Misal: cv. Tirta Nugraha',
    this.prefixIcon,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSelected,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSelected;

  @override
  ConsumerState<DistributorAutocompleteField> createState() =>
      _DistributorAutocompleteFieldState();
}

class _DistributorAutocompleteFieldState
    extends ConsumerState<DistributorAutocompleteField> {
  late FocusNode _focusNode;
  bool _internalFocus = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _focusNode = FocusNode();
      _internalFocus = true;
    } else {
      _focusNode = widget.focusNode!;
    }
  }

  @override
  void dispose() {
    if (_internalFocus) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    final asyncDistributors = ref.watch(distributorsProvider);
    final suggestions = asyncDistributors.valueOrNull ?? const <String>[];

    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) {
          return const Iterable<String>.empty();
        }
        return suggestions.where((option) {
          return option.toLowerCase().contains(query);
        });
      },
      onSelected: (String selection) {
        widget.controller.text = selection;
        widget.onChanged?.call(selection);
        widget.onSelected?.call(selection);
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon ?? Icon(AppIcons.truck),
          ),
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<String> onSelected,
        Iterable<String> options,
      ) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: AppRadius.input,
            color: AppColors.bgSurface,
            child: Container(
              width: MediaQuery.of(context).size.width - 32,
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: AppRadius.input,
                border: Border.all(
                  color: AppColors.borderStrong,
                  width: 1.5,
                ),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  color: AppColors.borderHairline,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    borderRadius: AppRadius.chipSmall,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            AppIcons.truck,
                            size: 16,
                            color: AppColors.inkMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              option,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink900,
                              ),
                            ),
                          ),
                          Icon(
                            AppIcons.arrowRight,
                            size: 14,
                            color: AppColors.inkMuted,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
