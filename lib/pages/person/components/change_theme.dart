import 'package:com.cherish.mingji/components/common/cherish_appbar.dart';
import 'package:com.cherish.mingji/provider/theme_provider.dart';
import 'package:com.cherish.mingji/utils/common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme_select_dialog.dart';

class ChangeTheme extends StatefulWidget {
  const ChangeTheme({super.key});

  @override
  State<ChangeTheme> createState() => _ChangeThemeState();
}

class _ChangeThemeState extends State<ChangeTheme> {
  @override
  Widget build(BuildContext context) {
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final appbarColor = Theme.of(context).appBarTheme.backgroundColor;
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    return Scaffold(
      appBar: CherishAppbar(
        title: '更换主题',
        centerTitle: true,
        elevation: 0,
        actions: [
          CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.ellipsis_vertical,
                size: 20,
              ),
              onPressed: () {
                // debugprint('切换主题');
                debugPrint('切换主题');
                // 显示主题选择弹窗
                showCupertinoModalPopup(
                  context: context,
                  builder: (BuildContext context) => CupertinoActionSheet(
                    title: const Text('选择主题'),
                    actions: List<CupertinoActionSheetAction>.generate(
                      Provider.of<ThemeProvider>(context).schemes.length,
                      (index) => CupertinoActionSheetAction(
                        onPressed: () {
                          // 更新主题模式
                          Provider.of<ThemeProvider>(context, listen: false)
                              .setThemeByIndex(index);
                          zToast(
                              '切换主题为${Provider.of<ThemeProvider>(context, listen: false).getSchemesNameByIndex(index)}',
                              position: 'center',
                              context: context);
                          Navigator.pop(context); // 关闭弹窗
                        },
                        child: Text(
                            Provider.of<ThemeProvider>(context, listen: false)
                                .getSchemesNameByIndex(index)),
                      ),
                    ),
                    cancelButton: CupertinoActionSheetAction(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('取消'),
                    ),
                  ),
                );
              })
        ],
      ),
      body: SizedBox(
        child: Center(
          child: Column(
            // mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                  child: Material(
                child: SingleChildScrollView(
                  child: Column(children: <Widget>[
                    RadioListTile<ThemeMode>(
                      title: Text('跟随系统'),
                      value: ThemeMode.system,
                      groupValue: themeMode,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          Provider.of<ThemeProvider>(context, listen: false)
                              .updateThemeMode(value);
                        }
                      },
                    ),
                    // 随机主题
                    // RadioListTile<ThemeMode>(
                    //   title: Text('随机主题'),
                    //   value: ThemeMode.system,
                    //   groupValue: themeMode,
                    //   onChanged: (ThemeMode? value) {
                    //     Provider.of<ThemeProvider>(context, listen: false)
                    //         .switchTheme();
                    //   },
                    // ),
                    RadioListTile<ThemeMode>(
                      title: Text('浅色模式'),
                      value: ThemeMode.light,
                      groupValue: themeMode,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          Provider.of<ThemeProvider>(context, listen: false)
                              .updateThemeMode(value);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('深色模式'),
                      value: ThemeMode.dark,
                      groupValue: themeMode,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          Provider.of<ThemeProvider>(context, listen: false)
                              .updateThemeMode(value);
                        }
                      },
                    ),
                  ]),
                ),
              )),
              if (1 > 2)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: Colors.white,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                              'Current Theme: ${Provider.of<ThemeProvider>(context).currentThemeName}'),
                          ElevatedButton(
                            onPressed: () {
                              Provider.of<ThemeProvider>(context, listen: false)
                                  .switchTheme();
                            },
                            child: const Text('随机主题'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Provider.of<ThemeProvider>(context, listen: false)
                                  .toggleDarkMode();
                            },
                            child: Text('Toggle Dark Mode'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => ThemeSelectorDialog(),
                              );
                            },
                            child: Text('Select Theme'),
                          ),
                        ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
