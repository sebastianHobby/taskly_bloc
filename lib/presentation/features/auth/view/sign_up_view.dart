import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/shared/widgets/taskly_brand_logo.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

/// Sign up view with custom form using AuthBloc.
class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthSignUpRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/sign-in'),
        ),
      ),
      body: BlocListener<AuthBloc, AppAuthState>(
        listenWhen: (prev, curr) =>
            (prev.error != curr.error && curr.error != null) ||
            (prev.pendingEmailConfirmation != curr.pendingEmailConfirmation &&
                curr.pendingEmailConfirmation != null),
        listener: (context, state) {
          // Show errors inline. On email-confirmation sign-up, route to
          // dedicated confirmation guidance.
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          } else if (state.pendingEmailConfirmation != null) {
            context.go('/check-email');
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TasklyBrandLogo.hero(),
                    SizedBox(height: TasklyTokens.of(context).spaceSm),
                    Text(
                      context.l10n.authSignUpTitle,
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: TasklyTokens.of(context).spaceSm),
                    Text(
                      context.l10n.authSignUpSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height:
                          TasklyTokens.of(context).spaceXxl +
                          TasklyTokens.of(context).spaceLg,
                    ),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: context.l10n.authEmailLabel,
                        hintText: context.l10n.authEmailHint,
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.l10n.authEmailRequired;
                        }
                        if (!value.contains('@')) {
                          return context.l10n.authEmailInvalid;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: TasklyTokens.of(context).spaceSm),
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
                      onFieldSubmitted: (_) => _handleSignUp(),
                    ),
                    SizedBox(height: TasklyTokens.of(context).spaceSm),
                    BlocBuilder<AuthBloc, AppAuthState>(
                      builder: (context, state) {
                        return FilledButton(
                          onPressed: state.isLoading ? null : _handleSignUp,
                          child: Padding(
                            padding: EdgeInsets.all(
                              TasklyTokens.of(context).spaceLg,
                            ),
                            child: state.isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(context.l10n.authSignUpButton),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: TasklyTokens.of(context).spaceSm),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${context.l10n.authAlreadyHaveAccount} ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () => context.go('/sign-in'),
                          child: Text(context.l10n.authSignInButton),
                        ),
                      ],
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
