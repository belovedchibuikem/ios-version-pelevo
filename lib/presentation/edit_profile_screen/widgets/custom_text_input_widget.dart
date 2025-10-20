import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

// lib/presentation/edit_profile_screen/widgets/custom_text_input_widget.dart

class CustomTextInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String labelText;
  final String hintText;
  final String? errorText;
  final String? iconName;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final String? suffixText;

  const CustomTextInputWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.labelText,
    required this.hintText,
    this.errorText,
    this.iconName,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.inputFormatters,
    this.suffixText,
  });

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          readOnly: readOnly,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onTap: onTap,
          inputFormatters: inputFormatters,
          style: currentTheme.textTheme.bodyLarge?.copyWith(
              color: enabled
                  ? currentTheme.colorScheme.onSurface
                  : currentTheme.colorScheme.onSurfaceVariant),
          decoration: InputDecoration(
              labelText: labelText,
              hintText: hintText,
              suffixText: suffixText,
              prefixIcon: iconName != null
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CustomIconWidget(
                          iconName: iconName!,
                          color: errorText != null
                              ? currentTheme.colorScheme.error
                              : focusNode.hasFocus
                                  ? currentTheme.colorScheme.primary
                                  : currentTheme.colorScheme.onSurfaceVariant,
                          size: 24))
                  : null,
              errorText: null,
              counterText: maxLength != null ? null : '',
              filled: true,
              fillColor: enabled
                  ? currentTheme.colorScheme.surface
                  : currentTheme.colorScheme.surface.withAlpha(128),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: currentTheme.colorScheme.outline, width: 1)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: currentTheme.colorScheme.outline, width: 1)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: currentTheme.colorScheme.primary, width: 2)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: currentTheme.colorScheme.error, width: 1)),
              focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: currentTheme.colorScheme.error, width: 2)),
              disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: currentTheme.colorScheme.outline.withAlpha(128),
                      width: 1)),
              labelStyle: currentTheme.textTheme.bodyMedium?.copyWith(
                  color: errorText != null
                      ? currentTheme.colorScheme.error
                      : focusNode.hasFocus
                          ? currentTheme.colorScheme.primary
                          : currentTheme.colorScheme.onSurfaceVariant),
              hintStyle: currentTheme.textTheme.bodyMedium?.copyWith(
                  color: currentTheme.colorScheme.onSurfaceVariant
                      .withAlpha(153)))),
      if (errorText != null) ...[
        const SizedBox(height: 8),
        Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(errorText!,
                style: currentTheme.textTheme.bodySmall
                    ?.copyWith(color: currentTheme.colorScheme.error))),
      ],
    ]);
  }
}
