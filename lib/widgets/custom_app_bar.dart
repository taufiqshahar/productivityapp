import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tab_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showHomeButton;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showHomeButton = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return AppBar(
      leading: showHomeButton
          ? IconButton(
        icon: const Icon(Icons.home),
        onPressed: () {
          Provider.of<TabProvider>(context, listen: false).setTabIndex(0);
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      )
          : null,
      title: Text(title),
      actions: actions?.map((action) {
        if (action is TextButton) {
          // Ensure action.child is not null; provide a fallback if it is
          final buttonChild = action.child ?? const SizedBox.shrink();
          return TextButton(
            onPressed: action.onPressed,
            child: DefaultTextStyle(
              style: TextStyle(color: textColor),
              child: buttonChild,
            ),
          );
        }
        return action;
      }).whereType<Widget>().toList() ?? [],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}