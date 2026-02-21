import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;
  final bool readOnly;
  final int? maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.hint,
    this.isPassword = false,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.validator,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(  // ← Changed to TextFormField (better for forms + validation)
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        textInputAction: textInputAction ?? TextInputAction.next,
        focusNode: focusNode,
        readOnly: readOnly,
        maxLines: maxLines,
        onTap: onTap,
        validator: validator,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 15,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(
              color: Color(0xFF4A90E2), // or AppColors.primaryBlue if you have it
              width: 1.8,
            ),
          ),
          errorBorder: border.copyWith(
            borderSide: const BorderSide(
              color: Colors.redAccent,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: border.copyWith(
            borderSide: const BorderSide(
              color: Colors.redAccent,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          // Optional: add floating label behavior if you want
          // floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }
}