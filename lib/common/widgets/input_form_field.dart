import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_svg/svg.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:chime/common/common.dart';

class InputFormField extends StatelessWidget {
  final String name;
  final bool? enable;
  final int? maxLines;
  final int? maxLength;
  final String labelText;
  final String? helperText;
  final String? initialValue;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final TextEditingController? controller;
  final bool? isObscure;
  final Function()? onObscure;
  final String? prefixIcon;
  final List<String? Function(String?)> validation;

  const InputFormField({
    super.key,
    this.enable,
    this.maxLines,
    this.maxLength,
    this.initialValue,
    this.isObscure,
    this.onObscure,
    this.prefixIcon,
    this.helperText,
    this.textInputAction,
    this.controller,
    required this.name,
    required this.labelText,
    required this.validation,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    CommonHelper commonHelper = CommonHelper();
    return FormBuilderTextField(
      name: name,
      enabled: enable ?? true,
      keyboardType: keyboardType,
      initialValue: initialValue,
      maxLines: maxLines ?? 1,
      maxLength: maxLength,
      controller: controller,
      obscureText: isObscure ?? false,
      textInputAction: textInputAction ?? TextInputAction.done,
      decoration: InputDecoration(
        labelText: labelText,
        helperText: helperText ?? "",
        prefixIconConstraints: const BoxConstraints(minWidth: 26, minHeight: 26),
        prefixIcon: prefixIcon?.isNotEmpty == true
            ? Padding(
                padding: const EdgeInsets.all(10.0),
                child: SvgPicture.asset(
                  commonHelper.getIconPath(prefixIcon!),
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
                ),
              )
            : null,
        suffixIcon: onObscure != null
            ? IconButton(
                icon: Icon(isObscure != null && isObscure == true ? Icons.visibility : Icons.visibility_off),
                onPressed: () => onObscure != null ? onObscure!() : null,
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      validator: FormBuilderValidators.compose(validation),
    );
  }
}
