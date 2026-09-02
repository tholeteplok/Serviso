import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Tactile Toggle Switch styled after the Contra Pop-Brutalism Design Kit.
/// Pill track with solid 1.5px black border and animated black knob.
class NeoSwitch extends StatefulWidget {
  const NeoSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = AppColors.accentPrimary, // DS v2 ON = mint #3FBE85
    this.inactiveColor = const Color(0xFFE8E0D6), // DS v2 OFF
    this.width = 44.0, // DS v2 spec 44x26
    this.height = 26.0,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final Color inactiveColor;
  final double width;
  final double height;

  @override
  State<NeoSwitch> createState() => _NeoSwitchState();
}

class _NeoSwitchState extends State<NeoSwitch> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final knobSize = widget.height - 6;
    final disableAnim = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    // 44px hitbox — visual 44x26, padding expanded
    return Semantics(
      toggled: widget.value,
      child: GestureDetector(
        onTap: () => widget.onChanged(!widget.value),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Focus(
            canRequestFocus: true,
            onFocusChange: (focused) => setState(() => _isFocused = focused),
            child: Container(
              decoration: _isFocused
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [BoxShadow(color: Color(0xFFFFC526), blurRadius: 0, spreadRadius: 2)],
                    )
                  : null,
              child: AnimatedContainer(
                duration: Duration(milliseconds: disableAnim ? 0 : 160),
                curve: Curves.easeOut,
                width: widget.width,
                height: widget.height,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: widget.value ? widget.activeColor : widget.inactiveColor,
                  borderRadius: BorderRadius.circular(widget.height / 2),
                  border: Border.all(
                    color: AppColors.borderStrong,
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.borderStrong,
                      offset: Offset(1.5, 1.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: AnimatedAlign(
                  duration: Duration(milliseconds: disableAnim ? 0 : 160),
                  curve: Curves.easeOut,
                  alignment: widget.value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: knobSize,
                    height: knobSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AppColors.borderStrong, width: 1.5),
                      boxShadow: const [BoxShadow(color: Color(0x26000000), offset: Offset(0, 1), blurRadius: 2)],
                    ),
                    child: widget.value
                        ? const Center(child: Text('✓', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF111111))))
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
