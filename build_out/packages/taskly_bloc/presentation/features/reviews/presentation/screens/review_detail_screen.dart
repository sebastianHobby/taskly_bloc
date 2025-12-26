import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review_action.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review_action_type.dart';
import 'package:taskly_bloc/presentation/features/reviews/presentation/blocs/review_detail/review_detail_bloc.dart';

class ReviewDetailScreen extends StatelessWidget {
  const ReviewDetailScreen({
    required this.reviewId,
    super.key,
  });
  final String reviewId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        actions: [
          BlocBuilder<ReviewDetailBloc, ReviewDetailState>(
            builder: (context, state) {
              return IconButton(
                icon: state.isExecutingActions
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                onPressed: state.isExecutingActions
                    ? null
                    : () {
                        context.read<ReviewDetailBloc>().add(
                          const ReviewDetailEvent.completeReview(),
                        );
                      },
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<ReviewDetailBloc, ReviewDetailState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
          if (!state.isExecutingActions &&
              state.actions.isEmpty &&
              !state.isLoading) {
            // Review completed successfully
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final review = state.review;
          if (review == null) {
            return const Center(child: Text('Review not found'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (review.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        review.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      '${state.tasks.length} items to review',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: state.tasks.length,
                  itemBuilder: (context, index) {
                    final task = state.tasks[index];
                    final action = state.actions[task.id];

                    return ListTile(
                      title: Text(task.name),
                      subtitle: action != null
                          ? Text(_getActionLabel(action.type))
                          : null,
                      trailing: PopupMenuButton<ReviewActionType>(
                        icon: Icon(
                          action != null ? Icons.check : Icons.more_vert,
                          color: action != null ? Colors.green : null,
                        ),
                        onSelected: (actionType) {
                          context.read<ReviewDetailBloc>().add(
                            ReviewDetailEvent.executeAction(
                              entityId: task.id,
                              action: ReviewAction(type: actionType),
                            ),
                          );
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: ReviewActionType.skip,
                            child: Text('Skip'),
                          ),
                          const PopupMenuItem(
                            value: ReviewActionType.complete,
                            child: Text('Complete'),
                          ),
                          const PopupMenuItem(
                            value: ReviewActionType.update,
                            child: Text('Update'),
                          ),
                          const PopupMenuItem(
                            value: ReviewActionType.delete,
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getActionLabel(ReviewActionType type) {
    switch (type) {
      case ReviewActionType.update:
        return 'Will update';
      case ReviewActionType.complete:
        return 'Will complete';
      case ReviewActionType.archive:
        return 'Will archive';
      case ReviewActionType.delete:
        return 'Will delete';
      case ReviewActionType.skip:
        return 'Skipped';
    }
  }
}
