import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Enhanced accessibility widget with comprehensive screen reader support
class EnhancedAccessibilityWidget extends StatelessWidget {
  final Widget child;
  final String? label;
  final String? hint;
  final String? value;
  final bool isButton;
  final bool isHeader;
  final bool isImage;
  final bool isTextField;
  final bool isSlider;
  final bool isCheckbox;
  final bool isRadioButton;
  final bool isSwitch;
  final bool isTab;
  final bool isSelected;
  final bool isEnabled;
  final bool isRequired;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final ValueChanged<String>? onValueChanged;
  final ValueChanged<bool>? onCheckedChanged;
  final ValueChanged<double>? onSliderChanged;
  final int? maxValueLength;
  final double? minValue;
  final double? maxValue;
  final double? currentValue;
  final List<String>? actions;
  final Map<String, String>? customProperties;

  const EnhancedAccessibilityWidget({
    super.key,
    required this.child,
    this.label,
    this.hint,
    this.value,
    this.isButton = false,
    this.isHeader = false,
    this.isImage = false,
    this.isTextField = false,
    this.isSlider = false,
    this.isCheckbox = false,
    this.isRadioButton = false,
    this.isSwitch = false,
    this.isTab = false,
    this.isSelected = false,
    this.isEnabled = true,
    this.isRequired = false,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.onValueChanged,
    this.onCheckedChanged,
    this.onSliderChanged,
    this.maxValueLength,
    this.minValue,
    this.maxValue,
    this.currentValue,
    this.actions,
    this.customProperties,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      value: value,
      button: isButton,
      header: isHeader,
      image: isImage,
      textField: isTextField,
      slider: isSlider,
      selected: isSelected,
      enabled: isEnabled,
      child: _buildInteractiveChild(),
    );
  }

  Widget _buildInteractiveChild() {
    if (onTap != null || onLongPress != null || onDoubleTap != null) {
      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        onDoubleTap: onDoubleTap,
        child: child,
      );
    }
    return child;
  }
}

/// Accessible button with enhanced semantics
class AccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final String? label;
  final String? hint;
  final bool isEnabled;
  final bool isSelected;
  final bool isRequired;
  final ButtonStyle? style;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const AccessibleButton({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.label,
    this.hint,
    this.isEnabled = true,
    this.isSelected = false,
    this.isRequired = false,
    this.style,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedAccessibilityWidget(
      label: label,
      hint: hint,
      isButton: true,
      isSelected: isSelected,
      isEnabled: isEnabled,
      isRequired: isRequired,
      onTap: onPressed,
      onLongPress: onLongPress,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        onLongPress: isEnabled ? onLongPress : null,
        style: style,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }
}

/// Accessible text field with enhanced semantics
class AccessibleTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? value;
  final bool isRequired;
  final bool isEnabled;
  final bool isPassword;
  final bool isMultiline;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final InputDecoration? decoration;

  const AccessibleTextField({
    super.key,
    this.label,
    this.hint,
    this.value,
    this.isRequired = false,
    this.isEnabled = true,
    this.isPassword = false,
    this.isMultiline = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.decoration,
  });

  @override
  State<AccessibleTextField> createState() => _AccessibleTextFieldState();
}

class _AccessibleTextFieldState extends State<AccessibleTextField> {
  late TextEditingController _controller;
  String _currentValue = '';

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _currentValue = widget.value ?? '';
    _controller.text = _currentValue;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _currentValue = _controller.text;
    });
    widget.onChanged?.call(_currentValue);
  }

  @override
  Widget build(BuildContext context) {
    return EnhancedAccessibilityWidget(
      label: widget.label,
      hint: widget.hint,
      value: _currentValue,
      isTextField: true,
      isRequired: widget.isRequired,
      isEnabled: widget.isEnabled,
      maxValueLength: widget.maxLength,
      onTap: widget.onTap,
      child: TextFormField(
        controller: _controller,
        enabled: widget.isEnabled,
        obscureText: widget.isPassword,
        maxLines: widget.isMultiline ? widget.maxLines : 1,
        maxLength: widget.maxLength,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        onTap: widget.onTap,
        validator: widget.validator,
        decoration: widget.decoration ??
            InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              suffixIcon: widget.isRequired
                  ? Icon(
                      Icons.star,
                      color: Colors.red,
                      size: 16,
                    )
                  : null,
            ),
      ),
    );
  }
}

/// Accessible checkbox with enhanced semantics
class AccessibleCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final String? hint;
  final bool isEnabled;
  final bool isRequired;
  final Color? activeColor;
  final Color? checkColor;
  final BorderRadius? borderRadius;

  const AccessibleCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.hint,
    this.isEnabled = true,
    this.isRequired = false,
    this.activeColor,
    this.checkColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedAccessibilityWidget(
      label: label,
      hint: hint,
      value: value ? 'Checked' : 'Unchecked',
      isCheckbox: true,
      isSelected: value,
      isEnabled: isEnabled,
      isRequired: isRequired,
      onTap: isEnabled ? () => onChanged?.call(!value) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: value,
            onChanged: isEnabled
                ? (bool? newValue) => onChanged?.call(newValue ?? false)
                : null,
            activeColor: activeColor,
            checkColor: checkColor,
          ),
          if (label != null) ...[
            SizedBox(width: 8),
            Flexible(
              child: Text(
                label!,
                style: TextStyle(
                  fontSize: 16,
                  color: isEnabled ? null : Colors.grey,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Accessible switch with enhanced semantics
class AccessibleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final String? hint;
  final bool isEnabled;
  final bool isRequired;
  final Color? activeColor;
  final Color? activeTrackColor;
  final Color? inactiveThumbColor;
  final Color? inactiveTrackColor;

  const AccessibleSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.hint,
    this.isEnabled = true,
    this.isRequired = false,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedAccessibilityWidget(
      label: label,
      hint: hint,
      value: value ? 'On' : 'Off',
      isSwitch: true,
      isSelected: value,
      isEnabled: isEnabled,
      isRequired: isRequired,
      onTap: isEnabled ? () => onChanged?.call(!value) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: value,
            onChanged: isEnabled ? onChanged : null,
            activeColor: activeColor,
            activeTrackColor: activeTrackColor,
            inactiveThumbColor: inactiveThumbColor,
            inactiveTrackColor: inactiveTrackColor,
          ),
          if (label != null) ...[
            SizedBox(width: 8),
            Flexible(
              child: Text(
                label!,
                style: TextStyle(
                  fontSize: 16,
                  color: isEnabled ? null : Colors.grey,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Accessible slider with enhanced semantics
class AccessibleSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final String? hint;
  final bool isEnabled;
  final bool isRequired;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;

  const AccessibleSlider({
    super.key,
    required this.value,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.hint,
    this.isEnabled = true,
    this.isRequired = false,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
  });

  @override
  State<AccessibleSlider> createState() => _AccessibleSliderState();
}

class _AccessibleSliderState extends State<AccessibleSlider> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(AccessibleSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _currentValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return EnhancedAccessibilityWidget(
      label: widget.label,
      hint: widget.hint,
      value: _currentValue.toStringAsFixed(2),
      isSlider: true,
      isEnabled: widget.isEnabled,
      isRequired: widget.isRequired,
      minValue: widget.min,
      maxValue: widget.max,
      currentValue: _currentValue,
      onTap: widget.isEnabled
          ? () {
              // Focus the slider for keyboard navigation
              FocusScope.of(context).requestFocus(FocusNode());
            }
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: widget.isEnabled ? null : Colors.grey,
              ),
            ),
            SizedBox(height: 8),
          ],
          Slider(
            value: _currentValue,
            onChanged: widget.isEnabled
                ? (value) {
                    setState(() {
                      _currentValue = value;
                    });
                    widget.onChanged?.call(value);
                  }
                : null,
            onChangeStart: widget.onChangeStart,
            onChangeEnd: widget.onChangeEnd,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            activeColor: widget.activeColor,
            inactiveColor: widget.inactiveColor,
            thumbColor: widget.thumbColor,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.min.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                widget.max.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Accessible image with enhanced semantics
class AccessibleImage extends StatelessWidget {
  final ImageProvider image;
  final String? label;
  final String? hint;
  final bool isEnabled;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadius? borderRadius;

  const AccessibleImage({
    super.key,
    required this.image,
    this.label,
    this.hint,
    this.isEnabled = true,
    this.onTap,
    this.width,
    this.height,
    this.fit,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedAccessibilityWidget(
      label: label,
      hint: hint,
      isImage: true,
      isEnabled: isEnabled,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
          ),
          clipBehavior: borderRadius != null ? Clip.antiAlias : Clip.none,
          child: Image(
            image: image,
            fit: fit,
            width: width,
            height: height,
          ),
        ),
      ),
    );
  }
}

/// Accessible list item with enhanced semantics
class AccessibleListItem extends StatelessWidget {
  final Widget child;
  final String? label;
  final String? hint;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const AccessibleListItem({
    super.key,
    required this.child,
    this.label,
    this.hint,
    this.isSelected = false,
    this.isEnabled = true,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedAccessibilityWidget(
      label: label,
      hint: hint,
      isSelected: isSelected,
      isEnabled: isEnabled,
      onTap: onTap,
      onLongPress: onLongPress,
      onDoubleTap: onDoubleTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: backgroundColor ??
              (isSelected ? Colors.blue.withValues(alpha: 0.1) : null),
          borderRadius: borderRadius,
        ),
        child: child,
      ),
    );
  }
}
