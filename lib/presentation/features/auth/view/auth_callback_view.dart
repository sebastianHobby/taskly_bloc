import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/features/auth/services/auth_callback_uri_parser.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class AuthCallbackView extends StatefulWidget {
  const AuthCallbackView({super.key});

  @override
  State<AuthCallbackView> createState() => _AuthCallbackViewState();
}

class _AuthCallbackViewState extends State<AuthCallbackView> {
  final AuthCallbackUriParser _parser = const AuthCallbackUriParser();
  AuthCallbackUriPayload? _payload;
  bool _handled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handled) return;
    _handled = true;

    final payload = _parser.parse(GoRouterState.of(context).uri);
    _payload = payload;
    if (payload.isRecoveryFlow) {
      context.read<AuthBloc>().add(const AuthPasswordRecoveryDetected());
    }
  }

  @override
  Widget build(BuildContext context) {
    final payload = _payload;
    final tokens = TasklyTokens.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(tokens.spaceLg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: BlocBuilder<AuthBloc, AppAuthState>(
              builder: (context, state) {
                if (payload?.hasError ?? false) {
                  return _AuthCallbackErrorCard(
                    message:
                        payload?.errorDescription ??
                        context.l10n.authCallbackDefaultError,
                  );
                }

                if (state.requiresPasswordUpdate) {
                  return _AuthCallbackLoadingCard(
                    title: context.l10n.authCallbackRecoveryDetectedTitle,
                    body: context.l10n.authCallbackRecoveryDetectedBody,
                  );
                }

                if (state.status == AuthStatus.loading ||
                    state.status == AuthStatus.initial) {
                  return _AuthCallbackLoadingCard(
                    title: context.l10n.authCallbackProcessingTitle,
                    body: context.l10n.authCallbackProcessingBody,
                  );
                }

                if (state.status == AuthStatus.unauthenticated) {
                  return _AuthCallbackErrorCard(
                    message: context.l10n.authCallbackUnauthenticatedBody,
                  );
                }

                return _AuthCallbackLoadingCard(
                  title: context.l10n.authCallbackSuccessTitle,
                  body: context.l10n.authCallbackSuccessBody,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthCallbackLoadingCard extends StatelessWidget {
  const _AuthCallbackLoadingCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          width: 52,
          child: const Center(child: CircularProgressIndicator()),
        ),
        SizedBox(height: tokens.spaceSm),
        Text(
          title,
          style: Theme.of(context).textTheme.displaySmall,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: tokens.spaceSm),
        Text(
          body,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _AuthCallbackErrorCard extends StatelessWidget {
  const _AuthCallbackErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.error_outline,
          size: 72,
          color: Theme.of(context).colorScheme.error,
        ),
        SizedBox(height: tokens.spaceSm),
        Text(
          context.l10n.authCallbackErrorTitle,
          style: Theme.of(context).textTheme.displaySmall,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: tokens.spaceSm),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: tokens.spaceLg),
        FilledButton(
          onPressed: () => context.go('/sign-in'),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.spaceMd),
            child: Text(context.l10n.authSignInButton),
          ),
        ),
      ],
    );
  }
}
