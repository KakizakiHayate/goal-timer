import 'package:flutter/material.dart';

import 'package:goal_timer/features/home/presentation/widgets/goal_list_cell_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const Header(),
            const DeadlineFilter(), 
            const SizedBox(height: 16),
            const MainContents(),
          ],
        ),
      ),
    );
  }
}

// MARK: - Header

class Header extends StatelessWidget {
  const Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      child: Container(
        height: 56,
        color: Colors.blue,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.pink),
              onPressed: () {
                // TODO: 処理を書く
              },
            )
          ],
        ),
      ),
    );
  }
}

// MARK: - 絞り込み検索

class DeadlineFilter extends StatelessWidget {
  const DeadlineFilter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Text('絞り込み:', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: '全て',
              items: const [
                DropdownMenuItem(
                  value: '全て',
                  child: Text('全て'),
                ),
                DropdownMenuItem(
                  value: '進行中',
                  child: Text('進行中'),
                ),
                DropdownMenuItem(
                  value: '完了',
                  child: Text('完了'),
                ),
              ],
              onChanged: (String? value) {
                // TODO: 絞り込み処理を実装
              },
            ),
          ],
        ),
      ),
    );
  }
}

// MARK: - MainContents

class MainContents extends StatelessWidget {
  const MainContents({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder( 
        shrinkWrap: true,
        itemCount: 20,
        itemBuilder: (context, index) {
          return const GoalListCellWidget();
        },
      ),
    );
  }
}
