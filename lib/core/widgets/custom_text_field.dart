import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkTextSecondaryColor : AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          focusNode: focusNode,
          textInputAction: textInputAction,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor,
          ),
          decoration: InputDecoration(
            hintText: hint ?? 'Enter $label',
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.darkTextSecondaryColor : AppTheme.textMutedColor,
            ),
            fillColor: isDark ? AppTheme.darkSurfaceColor : Colors.white,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: isDark ? AppTheme.darkTextSecondaryColor : AppTheme.textSecondaryColor,
                    size: 20,
                  )
                : null,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: Icon(
                      suffixIcon,
                      color: isDark ? AppTheme.darkTextSecondaryColor : AppTheme.textSecondaryColor,
                      size: 20,
                    ),
                    onPressed: onSuffixTap,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
