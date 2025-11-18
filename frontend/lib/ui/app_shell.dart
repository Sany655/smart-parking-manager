import 'package:flutter/material.dart';
import '../screens/home/view_slots_screen.dart';

class AppShell extends StatelessWidget {
  final Widget? initial;
  const AppShell({super.key, this.initial});

  @override
  Widget build(BuildContext context) {
    // For regular users, just show the ViewSlotsScreen without any bottom navigation
    // This provides a clean, simple interface for regular users
    return const ViewSlotsScreen();
  }
}
