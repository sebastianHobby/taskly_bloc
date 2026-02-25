import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/routing/session_entry_policy.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

/// Forgot password view that sends reset email via AuthBloc.
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _requestPasswordReset() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthPasswordResetRequested(email: _emailController.text.trim()),
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
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          } else if (state.message != null) {
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.lock_reset,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(height: TasklyTokens.of(context).spaceSm),
                    Text(
                      context.l10n.authResetPasswordTitle,
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: TasklyTokens.of(context).spaceSm),
                    Text(
                      context.l10n.authResetPasswordSubtitle,
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
                      textInputAction: TextInputAction.done,
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
                      onFieldSubmitted: (_) => _requestPasswordReset(),
                    ),
                    SizedBox(height: TasklyTokens.of(context).spaceSm),
                    BlocBuilder<AuthBloc, AppAuthState>(
                      builder: (context, state) {
                        return FilledButton(
                          onPressed: state.isLoading
                              ? null
                              : _requestPasswordReset,
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
                                : Text(context.l10n.resetButton),
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
                          '${context.l10n.authRememberPasswordPrompt} ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () => context.go(signInPath),
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
