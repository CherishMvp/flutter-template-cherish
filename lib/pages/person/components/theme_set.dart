import 'package:com.cherish.mingji/themes/theme_contaoller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

// 老版本的themetroller切换主题页面
class ThemeSet extends StatelessWidget {
  const ThemeSet({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('多主题切换示例'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // 打开 Modal Sheet 选择主题
            showModalBottomSheet(
              context: context,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => ThemeSelectorModal(),
            );
          },
          child: Text('选择主题'),
        ),
      ),
    );
  }
}

// ThemeSelectorModal 主题选择 Modal
class ThemeSelectorModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 获取当前主题控制器
    final themeProvider = Provider.of<ThemeController>(context, listen: false);

    // 获取所有可用的主题方案
    final List<FlexSchemeData> schemes = FlexColor.schemesList;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              '选择一个主题',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: schemes.length,
              itemBuilder: (context, index) {
                final scheme = schemes[index];
                return ListTile(
                  title: Text(scheme.name),
                  trailing: Icon(Icons.circle, color: scheme.light.primary),
                  onTap: () {
                    // 使用 scheme.key 切换主题
                    themeProvider.changeTheme(scheme);
                    Navigator.of(context).pop(); // 关闭 Modal Sheet
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
