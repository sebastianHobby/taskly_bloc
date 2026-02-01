import 'package:flutter/material.dart';

class TasklyOverflowMenuButton<T> extends StatelessWidget {
  const TasklyOverflowMenuButton({
    required this.itemsBuilder,
    required this.onSelected,
    this.icon = Icons.more_vert,
    this.tooltip,
    this.style,
    super.key,
  });

  final List<PopupMenuEntry<T>> Function(BuildContext context) itemsBuilder;
  final ValueChanged<T> onSelected;
  final IconData icon;
  final String? tooltip;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return IconButton(
          tooltip: tooltip,
          icon: Icon(icon),
          style: style,
          onPressed: () async {
            final box = context.findRenderObject() as RenderBox?;
            final overlay =
                Overlay.of(context).context.findRenderObject() as RenderBox?;
            if (box == null || overlay == null) return;

            final position = RelativeRect.fromRect(
              Rect.fromPoints(
                box.localToGlobal(Offset.zero, ancestor: overlay),
                box.localToGlobal(
                  box.size.bottomRight(Offset.zero),
                  ancestor: overlay,
                ),
              ),
              Offset.zero & overlay.size,
            );

            final selected = await showMenu<T>(
              context: context,
              position: position,
              items: itemsBuilder(context),
            );
            if (selected == null) return;
            onSelected(selected);
          },
        );
      },
    );
  }
}

class TasklyMenuItemLabel extends StatelessWidget {
  const TasklyMenuItemLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text),
      ),
    );
  }
}
