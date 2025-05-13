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
      actions: actions ?? [],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}