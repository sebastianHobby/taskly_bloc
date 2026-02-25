import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/routing/session_entry_policy.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class CheckEmailView extends StatelessWidget {
  const CheckEmailView({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final email = context.select<AuthBloc, String?>(
      (bloc) => bloc.state.pendingEmailConfirmation,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(signInPath),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(tokens.spaceLg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.mark_email_read_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(height: tokens.spaceSm),
                Text(
                  context.l10n.authCheckEmailTitle,
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: tokens.spaceSm),
                Text(
                  context.l10n.authCheckEmailBody(
                    email ?? context.l10n.authEmailLabel,
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: tokens.spaceLg),
                FilledButton(
                  onPressed: () => context.go(signInPath),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: tokens.spaceMd),
                    child: Text(context.l10n.authSignInButton),
                  ),
                ),
                SizedBox(height: tokens.spaceSm),
                TextButton(
                  onPressed: () => context.go(signUpPath),
                  child: Text(context.l10n.authUseDifferentEmailAction),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
