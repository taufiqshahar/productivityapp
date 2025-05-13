import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/focus_provider.dart';
import 'timer_view.dart';
import 'stats_view.dart';
import '../../widgets/custom_app_bar.dart';

class FocusBoosterScreen extends StatelessWidget {
  const FocusBoosterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Focus Booster",
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatsView()),
              );
            },
            tooltip: 'View Stats',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<FocusProvider>(
            builder: (context, focusProvider, child) {
              return Column(
                children: [
                  Text(
                    "Today's Focus: ${focusProvider.todayMinutes} min",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Streak: ${focusProvider.streakDays} days",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  const Expanded(child: TimerView()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}