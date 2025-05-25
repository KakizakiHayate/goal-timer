part of '../screens/home_screen.dart';

Widget _buildFilterBar(
  BuildContext context,
  HomeState state,
  HomeViewModel viewModel,
) {
  return Material(
    color: Colors.white,
    elevation: 1,
    child: Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            '表示:',
            style: TextStyle(fontSize: 14, color: ColorConsts.textLight),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: state.filterType,
            underline: Container(),
            icon: const Icon(Icons.arrow_drop_down, color: ColorConsts.primary),
            items: const [
              DropdownMenuItem(value: '全て', child: Text('全て')),
              DropdownMenuItem(value: '進行中', child: Text('進行中')),
              DropdownMenuItem(value: '完了', child: Text('完了')),
            ],
            onChanged: (String? value) {
              if (value != null) {
                viewModel.changeFilter(value);
              }
            },
          ),
        ],
      ),
    ),
  );
}
