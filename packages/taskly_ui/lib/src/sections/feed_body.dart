import 'package:flutter/material.dart';

import 'package:taskly_ui/src/sections/error_state_widget.dart';

enum _FeedBodyKind {
  loading,
  error,
  empty,
  list,
}

/// Shared feed body UI that standardizes loading/error/empty/list rendering.
///
/// This widget is pure UI: it does not know about BLoCs, routing, repositories,
/// or domain streams.
class FeedBody extends StatelessWidget {
  const FeedBody._({
    required _FeedBodyKind kind,
    String? errorMessage,
    VoidCallback? onRetry,
    String? retryLabel,
    Widget? empty,
    int? itemCount,
    IndexedWidgetBuilder? itemBuilder,
    EdgeInsetsGeometry? padding,
    ScrollController? controller,
    super.key,
  }) : _kind = kind,
       _errorMessage = errorMessage,
       _onRetry = onRetry,
       _retryLabel = retryLabel,
       _empty = empty,
       _itemCount = itemCount,
       _itemBuilder = itemBuilder,
       _padding = padding,
       _controller = controller;

  /// Loading state (spinner).
  const FeedBody.loading({Key? key})
    : this._(kind: _FeedBodyKind.loading, key: key);

  /// Error state.
  const FeedBody.error({
    required String message,
    VoidCallback? onRetry,
    String? retryLabel,
    Key? key,
  }) : this._(
         kind: _FeedBodyKind.error,
         errorMessage: message,
         onRetry: onRetry,
         retryLabel: retryLabel,
         key: key,
       );

  /// Empty state.
  const FeedBody.empty({
    required Widget child,
    Key? key,
  }) : this._(kind: _FeedBodyKind.empty, empty: child, key: key);

  /// List state.
  const FeedBody.list({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    EdgeInsetsGeometry? padding,
    ScrollController? controller,
    Key? key,
  }) : this._(
         kind: _FeedBodyKind.list,
         itemCount: itemCount,
         itemBuilder: itemBuilder,
         padding: padding,
         controller: controller,
         key: key,
       );

  final _FeedBodyKind _kind;

  final String? _errorMessage;
  final VoidCallback? _onRetry;
  final String? _retryLabel;

  final Widget? _empty;

  final int? _itemCount;
  final IndexedWidgetBuilder? _itemBuilder;
  final EdgeInsetsGeometry? _padding;
  final ScrollController? _controller;

  @override
  Widget build(BuildContext context) {
    assert(
      _onRetry == null || _retryLabel != null,
      'When onRetry is provided, retryLabel must be provided (taskly_ui does not '
      'hardcode user-facing strings).',
    );

    return switch (_kind) {
      _FeedBodyKind.loading => const Center(child: CircularProgressIndicator()),
      _FeedBodyKind.error => ErrorStateWidget(
        message: _errorMessage!,
        onRetry: _onRetry,
        retryLabel: _retryLabel,
      ),
      _FeedBodyKind.empty => _empty ?? const SizedBox.shrink(),
      _FeedBodyKind.list => ListView.builder(
        controller: _controller,
        padding: _padding,
        itemCount: _itemCount ?? 0,
        itemBuilder: _itemBuilder!,
      ),
    };
  }
}
