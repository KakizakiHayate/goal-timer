import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {

  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16), // 角丸の半径
              child: Image.asset(
                'assets/icons/goal_timer_app_icon.png',
                  width: MediaQuery.of(context).size.width * 0.5, // 画面幅の30%
                  height: MediaQuery.of(context).size.width * 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}