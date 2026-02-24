import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/shared/widgets/taskly_brand_logo.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

/// Sign in view with custom form using AuthBloc.
class SignInView extends StatefulWidget {
  const SignInView({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthSignInRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AppAuthState>(
        listenWhen: (prev, curr) =>
            prev.error != curr.error && curr.error != null,
        listener: (context, state) {
          // Only show errors - navigation is handled by auth gating in app.dart
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
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
                      context.l10n.authWelcomeTitle,
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: TasklyTokens.of(context).spaceSm),
                    Text(
                      context.l10n.authSignInSubtitle,
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
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
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
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleSignIn(),
                    ),
                    SizedBox(height: TasklyTokens.of(context).spaceSm),
                    BlocBuilder<AuthBloc, AppAuthState>(
                      builder: (context, state) {
                        return FilledButton(
                          onPressed: state.isLoading ? null : _handleSignIn,
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
                                : Text(context.l10n.authSignInButton),
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
                          '${context.l10n.authNoAccountPrompt} ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () => context.go('/sign-up'),
                          child: Text(context.l10n.authSignUpButton),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.go('/forgot-password'),
                      child: Text(context.l10n.authForgotPasswordLink),
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
