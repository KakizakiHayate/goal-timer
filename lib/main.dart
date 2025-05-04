import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/features/goal_timer/presentation/screens/goal_list_screen.dart';
import 'package:goal_timer/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:goal_timer/features/settings/presentation/screens/settings_screen.dart';
import 'package:goal_timer/features/home/presentation/screens/home_screen.dart';
import 'package:goal_timer/routes.dart';
import 'package:goal_timer/core/utils/route_names.dart';

void main() {
  runApp(
    // Riverpodのプロバイダースコープでアプリをラップ
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ゴールタイマー',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    GoalListScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  final List<String> _titles = const [
    'ゴール一覧',
    '統計',
    '設定',
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: RouteNames.home,
      onGenerateRoute: generateRoute,
      home: const HomeScreen(),
    );
    // Scaffold(
    //   body: _screens[_selectedIndex],
    //   drawer: Drawer(
    //     child: ListView(
    //       padding: EdgeInsets.zero,
    //       children: [
    //         DrawerHeader(
    //           decoration: BoxDecoration(
    //             color: Theme.of(context).colorScheme.primary,
    //           ),
    //           child: const Column(
    //             crossAxisAlignment: CrossAxisAlignment.start,
    //             children: [
    //               Text(
    //                 'ゴールタイマー',
    //                 style: TextStyle(
    //                   color: Colors.white,
    //                   fontSize: 24,
    //                 ),
    //               ),
    //               SizedBox(height: 8),
    //               Text(
    //                 '目標達成を時間で管理',
    //                 style: TextStyle(
    //                   color: Colors.white,
    //                   fontSize: 16,
    //                 ),
    //               ),
    //             ],
    //           ),
    //         ),
    //         ListTile(
    //           leading: const Icon(Icons.list),
    //           title: const Text('ゴール一覧'),
    //           selected: _selectedIndex == 0,
    //           onTap: () {
    //             _selectDrawerItem(0);
    //           },
    //         ),
    //         ListTile(
    //           leading: const Icon(Icons.bar_chart),
    //           title: const Text('統計'),
    //           selected: _selectedIndex == 1,
    //           onTap: () {
    //             _selectDrawerItem(1);
    //           },
    //         ),
    //         const Divider(),
    //         ListTile(
    //           leading: const Icon(Icons.settings),
    //           title: const Text('設定'),
    //           selected: _selectedIndex == 2,
    //           onTap: () {
    //             _selectDrawerItem(2);
    //           },
    //         ),
    //       ],
    //     ),
    //   ),
    //   appBar: AppBar(
    //     title: Text(_titles[_selectedIndex]),
    //     backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    //   ),
    // );
  }

  void _selectDrawerItem(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.of(context).pop(); // ドロワーを閉じる
  }
}
