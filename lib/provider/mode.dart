import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Mode { left, center, right }

class ModeProvider extends ChangeNotifier {
  Mode _mode = Mode.left; // 默认模式
  int _currentModeIndex = 0; // 当前模式的索引，用于循环模式

  // 获取当前模式
  Mode get mode => _mode;

  // 设置模式并通知监听者
  void setMode(Mode newMode) {
    if (newMode != _mode) {
      _mode = newMode;
      notifyListeners();
    }
  }

  // 循环切换模式
  Future<void> cycleMode() async {
    List<Mode> modes = Mode.values;

    // 依次循环递增模式索引
    _currentModeIndex = (_currentModeIndex + 1) % modes.length;

    // 获取下一个模式
    Mode nextMode = modes[_currentModeIndex];
    setMode(nextMode);

    // 将当前模式保存到 SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_mode', nextMode.toString());
    print('已保存模式：${nextMode.toString()}');
  }

  // 随机选择模式
  Future<void> randomizeMode() async {
    List<Mode> modes = Mode.values;
    final random = Random();
    Mode randomMode = modes[random.nextInt(modes.length)];
    setMode(randomMode);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_mode', randomMode.toString());
  }

  // 从 SharedPreferences 加载模式
  Future<void> loadModeFromPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? modeString = prefs.getString('selected_mode');

    if (modeString != null) {
      Mode? savedMode = _stringToMode(modeString);
      if (savedMode != null) {
        _mode = savedMode;
        // 更新 _currentModeIndex 以确保循环正确
        _currentModeIndex = Mode.values.indexOf(savedMode);
        notifyListeners(); // 确保监听者更新
      }
    }
  }

  // 将字符串转换为 Mode 枚举
  Mode? _stringToMode(String modeString) {
    switch (modeString) {
      case 'Mode.left':
        return Mode.left;
      case 'Mode.center':
        return Mode.center;
      case 'Mode.right':
        return Mode.right;
      default:
        return null;
    }
  }
}
