import 'package:flutter/material.dart';

import 'app_text_field.dart';

/// Older text-field API, kept so existing forms keep compiling. Renders an
/// [AppTextField] (label above the box, eye toggle for passwords).
class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      hint: hint,
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      icon: prefixIcon,
      validator: validator,
      textInputAction: textInputAction,
      onSubmitted: onFieldSubmitted,
    );
  }
}
