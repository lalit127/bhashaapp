import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../lesson_screen.dart' as main_screen;

class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirecting to the main LessonScreen implementation to avoid duplication and errors.
    // The main implementation is in lib/features/lesson_engine/presentation/lesson_screen.dart
    return const main_screen.LessonScreen();
  }
}
