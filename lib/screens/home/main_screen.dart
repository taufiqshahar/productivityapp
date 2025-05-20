import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tab_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/task_manager/task_manager_screen.dart';
import '../../screens/note_hub/note_hub_screen.dart';
import '../../screens/focus_booster/focus_booster_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_app_bar.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        return Consumer<TabProvider>(
          builder: (context, tabProvider, child) {
            // Determine colors based on the current theme (light or dark)
            final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
            final Color selectedColor = isDarkMode
                ? Colors.deepPurple[200]! // Lighter purple for dark mode
                : Theme.of(context).colorScheme.primary; // Default deep purple for light mode
            final Color unselectedColor = isDarkMode
                ? Colors.grey[400]! // Lighter gray for dark mode
                : Colors.grey[600]!; // Darker gray for light mode
            final Color navBarBackgroundColor = isDarkMode
                ? Colors.grey[900]! // Match scaffold background in dark mode
                : Colors.grey.shade100; // Match scaffold background in light mode

            return Scaffold(
              appBar: CustomAppBar(
                title: 'Productivity App',
                showHomeButton: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Sign Out',
                    onPressed: () async {
                      await authService.signOut();
                    },
                  ),
                ],
              ),
              body: IndexedStack(
                index: tabProvider.currentIndex,
                children: const [
                  HomeScreen(),
                  TaskManagerScreen(),
                  NoteHubScreen(),
                  FocusBoosterScreen(),
                ],
              ),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: tabProvider.currentIndex,
                selectedItemColor: selectedColor,
                unselectedItemColor: unselectedColor,
                backgroundColor: navBarBackgroundColor,
                onTap: (index) {
                  tabProvider.setTabIndex(index);
                },
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                  BottomNavigationBarItem(icon: Icon(Icons.task), label: "Tasks"),
                  BottomNavigationBarItem(icon: Icon(Icons.note), label: "Notes"),
                  BottomNavigationBarItem(icon: Icon(Icons.timer), label: "Focus"),
                ],
                type: BottomNavigationBarType.fixed,
              ),
            );
          },
        );
      },
    );
  }
}