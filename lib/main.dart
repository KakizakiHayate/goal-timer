import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'features/home/view/home_screen.dart';
import 'core/utils/color_consts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Goal Timer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ColorConsts.primary),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
