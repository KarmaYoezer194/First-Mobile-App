import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Text field with its label above the box (12 w600), a leading icon, and
/// an optional trailing widget. Password fields ([obscureText]) get an
/// eye toggle automatically.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.focusNode,
    this.icon,
    this.trailing,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.autofillHints,
    this.inputFormatters,
    this.maxLines = 1,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final IconData? icon;

  /// Widget shown at the end of the field (e.g. a camera button).
  /// Ignored for password fields, which show the eye toggle.
  final Widget? trailing;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    Widget? suffix;
    if (widget.obscureText) {
      suffix = IconButton(
        tooltip: _obscure ? 'Show password' : 'Hide password',
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 19,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      );
    } else if (widget.trailing != null) {
      suffix = Padding(
        padding: const EdgeInsets.only(right: 7),
        child: widget.trailing,
      );
    }

    final field = TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      autofillHints: widget.autofillHints,
      inputFormatters: widget.inputFormatters,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      style: AppFonts.sans(fontSize: 14, color: palette.ink),
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: widget.icon != null ? Icon(widget.icon, size: 19) : null,
        prefixIconConstraints: const BoxConstraints(
            minWidth: 44, minHeight: AppConstants.fieldHeight),
        suffixIcon: suffix,
        suffixIconConstraints: const BoxConstraints(
            minWidth: 44, minHeight: AppConstants.fieldHeight),
      ),
    );

    if (widget.label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label!,
          style: AppFonts.sans(
              fontSize: 12, fontWeight: FontWeight.w600, color: palette.ink),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}

/// 36px rounded-square button used inside search fields (the camera
/// shortcut).
class FieldIconButton extends StatelessWidget {
  const FieldIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: SizedBox(
          width: AppConstants.minTapTarget,
          height: AppConstants.minTapTarget,
          child: Center(
            child: Material(
              color: palette.surfaceSoft,
              borderRadius: BorderRadius.circular(AppConstants.radiusIconWell),
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusIconWell),
                onTap: onPressed,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(icon, size: 18, color: palette.ink),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
