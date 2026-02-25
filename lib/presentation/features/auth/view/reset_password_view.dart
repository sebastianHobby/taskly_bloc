import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/routing/session_entry_policy.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthPasswordUpdateRequested(newPassword: _passwordController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(signInPath),
        ),
      ),
      body: BlocListener<AuthBloc, AppAuthState>(
        listenWhen: (previous, current) =>
            previous.error != current.error ||
            previous.message != current.message,
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          if (state.message != null && !state.requiresPasswordUpdate) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.lock_reset,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(height: TasklyTokens.of(context).spaceSm),
                    Text(
                      context.l10n.authSetNewPasswordTitle,
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: TasklyTokens.of(context).spaceSm),
                    Text(
                      context.l10n.authSetNewPasswordSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height:
                          TasklyTokens.of(context).spaceXxl +
                          TasklyTokens.of(context).spaceLg,
                    ),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: context.l10n.authPasswordLabel,
                        hintText: context.l10n.authPasswordHint,
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.l10n.authPasswordRequired;
                        }
                        if (value.length < 6) {
                          return context.l10n.authPasswordMinLength(6);
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: TasklyTokens.of(context).spaceSm),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: context.l10n.authConfirmPasswordLabel,
                        hintText: context.l10n.authConfirmPasswordHint,
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.l10n.authConfirmPasswordRequired;
                        }
                        if (value != _passwordController.text) {
                          return context.l10n.authPasswordMismatch;
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    SizedBox(height: TasklyTokens.of(context).spaceSm),
                    BlocBuilder<AuthBloc, AppAuthState>(
                      builder: (context, state) {
                        return FilledButton(
                          onPressed: state.isLoading ? null : _submit,
                          child: Padding(
                            padding: EdgeInsets.all(
                              TasklyTokens.of(context).spaceLg,
                            ),
                            child: state.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(context.l10n.authUpdatePasswordButton),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
