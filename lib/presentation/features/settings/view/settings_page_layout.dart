import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_ui/taskly_ui_chrome.dart';
import 'package:taskly_ui/taskly_ui_primitives.dart';
import 'package:taskly_ui/taskly_ui_theme.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class SettingsPageLayout extends StatelessWidget {
  const SettingsPageLayout({
    required this.icon,
    required this.title,
    required this.children,
    this.subtitle,
    this.variant = TasklyHeaderVariant.screen,
    super.key,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final String? subtitle;
  final TasklyHeaderVariant variant;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return TasklyPageGradientSurface(
      child: ResponsiveBody(
        isExpandedLayout: context.isExpandedScreen,
        child: ListView(
          padding: EdgeInsets.only(bottom: tokens.spaceLg),
          children: [
            TasklyPageHeader(
              icon: icon,
              title: title,
              subtitle: subtitle,
              variant: variant,
            ),
            for (var i = 0; i < children.length; i++)
              TasklyReveal(
                delay: Duration(milliseconds: 40 * (i + 1)),
                offset: TasklyMotionTheme.of(context).sectionOffset,
                child: children[i],
              ),
          ],
        ),
      ),
    );
  }
}
