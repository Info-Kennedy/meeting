import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:chime/app/route_names.dart';
import 'package:chime/common/common.dart';
import 'package:chime/login/bloc/login_bloc.dart';
import 'package:logger/logger.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final log = Logger();
  final PreferencesRepository pref = getIt<PreferencesRepository>();
  final CommonHelper commonHelper = CommonHelper();
  final UiHelper uiHelper = UiHelper();
  final formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return NetworkAwareScaffoldWithBanner(
      body: SafeArea(
        child: BlocConsumer<LoginBloc, LoginState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == LoginStatus.success) {
              ToastUtil.showSuccessToast(context, state.message);
              context.goNamed(RouteNames.home);
              RouteHistory.clear();
            }
            if (state.status == LoginStatus.loggedIn) {
              context.goNamed(RouteNames.home);
              RouteHistory.clear();
            }
            if (state.status == LoginStatus.error) {
              ToastUtil.showErrorToast(context, state.message);
            }
          },
          builder: (context, state) {
            final isEnabled = state.status != LoginStatus.loading;
            return SingleChildScrollView(
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: FormBuilder(
                  key: formKey,
                  onChanged: () {
                    formKey.currentState!.save();
                    context.read<LoginBloc>().add(ChangeFormValue(formValue: formKey.currentState!.value));
                  },
                  child: state.status == LoginStatus.initial || state.status == LoginStatus.loggedIn
                      ? const Center(child: CircularProgressIndicator())
                      : Stack(
                          children: [
                            Column(
                              children: [
                                AppbarWidget(context: context, title: "", themeIcon: false),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                                  child: Column(
                                    spacing: 10.0,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        commonHelper.getStringLabel("login"),
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        "${commonHelper.getStringLabel("welcome")} ${commonHelper.getStringLabel("app_name")}",
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 16),
                                      InputFormField(
                                        name: "email",
                                        enable: isEnabled,
                                        labelText: commonHelper.getStringLabel("email_id"),
                                        keyboardType: TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        validation: [
                                          FormBuilderValidators.required(errorText: commonHelper.getStringLabel("email_id_e")),
                                          FormBuilderValidators.email(errorText: commonHelper.getStringLabel("email_id_v")),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      InputFormField(
                                        name: "password",
                                        enable: isEnabled,
                                        labelText: commonHelper.getStringLabel("password"),
                                        keyboardType: TextInputType.visiblePassword,
                                        textInputAction: TextInputAction.done,
                                        isObscure: state.isObscure,
                                        onObscure: () {
                                          context.read<LoginBloc>().add(const TogglePasswordVisibility());
                                        },
                                        validation: [
                                          FormBuilderValidators.required(errorText: commonHelper.getStringLabel("password_e")),
                                          FormBuilderValidators.minLength(6, errorText: commonHelper.getStringLabel("password_v")),
                                          (val) {
                                            if (val == null || val.isEmpty) return null;
                                            final hasUpper = val.contains(RegExp(r'[A-Z]'));
                                            final hasLower = val.contains(RegExp(r'[a-z]'));
                                            final hasDigit = val.contains(RegExp(r'[0-9]'));
                                            final hasSpecial = val.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]'));
                                            if (!hasUpper) {
                                              return "Password must have at least one uppercase letter.";
                                            }
                                            if (!hasLower) {
                                              return "Password must have at least one lowercase letter.";
                                            }
                                            if (!hasDigit) {
                                              return "Password must have at least one number.";
                                            }
                                            if (!hasSpecial) {
                                              return "Password must have at least one special character.";
                                            }
                                            return null;
                                          },
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      ButtonField(
                                        name: commonHelper.getStringLabel("login"),
                                        isLoading: state.status == LoginStatus.loading,
                                        onPressed: () {
                                          if (formKey.currentState?.validate() == true) {
                                            context.read<LoginBloc>().add(LoginSubmit());
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12.0),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(8.0),
                                          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), width: 1.0),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.primary),
                                                const SizedBox(width: 6),
                                                Text(
                                                  commonHelper.getStringLabel("demo_credentials"),
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: Theme.of(context).colorScheme.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              commonHelper.getStringLabel("demo_email"),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              commonHelper.getStringLabel("demo_password"),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                                            ),
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton.icon(
                                                onPressed: isEnabled
                                                    ? () {
                                                        formKey.currentState?.fields['email']?.didChange('task@example.com');
                                                        formKey.currentState?.fields['password']?.didChange('Qwerty@123!');
                                                        formKey.currentState?.save();
                                                        context.read<LoginBloc>().add(ChangeFormValue(formValue: formKey.currentState!.value));
                                                      }
                                                    : null,
                                                icon: const Icon(Icons.autorenew, size: 16),
                                                label: Text(commonHelper.getStringLabel("fill")),
                                                style: OutlinedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
