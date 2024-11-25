import 'dart:convert';
import 'dart:developer';

import 'package:com.cherish.mingji/api/index.dart';
import 'package:com.cherish.mingji/api/nest_request.dart';
import 'package:com.cherish.mingji/components/common/cherish_appbar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? userName;
  String? userEmail;
  String? userIdentifier;
  Future<void> _signInWithApple() async {
    try {
      final isAvailable = await SignInWithApple.isAvailable();
      debugPrint('isAvailable: $isAvailable');
      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Apple 登录不可用')),
        );
        return;
      }
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      debugPrint('appleCredential: $appleCredential');
      log("userIdentifier: ${appleCredential.userIdentifier}");
      // 获取用户的名称和电子邮件

      // 用户信息提交到后端
      // 整理用户信息
      final userInfo = {
        'userIdentifier': appleCredential.userIdentifier, // Apple唯一标识符
        'email': appleCredential.email ?? '', // 可能为空
        'givenName': appleCredential.givenName ?? '', // 可能为空
        'familyName': appleCredential.familyName ?? '', // 可能为空
      };
      await _registerUser(userInfo);
    } catch (e) {
      debugPrint('Apple sign-in failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登录失败，请重试！')),
      );
    }
  }

// 用户注册
  Future<void> _registerUser(Map<String, String?> userInfo) async {
    if (userInfo['userIdentifier']!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('用户信息不完整，请重新登录')),
      );
      return;
    }
    DioClient dioClient = DioClient();

    Map<String, dynamic> postData = userInfo;
    // 将用户信息发送到服务器

    ApiResponse<Map<String, dynamic>> response =
        await dioClient.post(API.register, postData, (data) => data);
    if (response.errno == 0) {
      // 成功处理
      debugPrint(
          'User information saved to server successfully: ${response.data}');
      // 保存登录信息到本地
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', userInfo['givenName']!);
      await prefs.setString('userEmail', userInfo['email']!);
      await prefs.setString('userIdentifier', userInfo['userIdentifier']!);

      // 更新 UI
      setState(() {
        userName = userInfo['givenName'];
        userEmail = userInfo['email'];
        userIdentifier = userInfo['userIdentifier'];
      });
      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登录成功！')),
      );
    } else {
      // 处理错误
      debugPrint(
          'Failed to save user information to server: ${response.message}');
    }
  }

  Future<void> _registerUserold(Map<String, String?> userInfo) async {
    if (userInfo['userIdentifier'] == null && userInfo['email'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('用户信息不完整，请重新登录')),
      );
      return;
    }

    // 将用户信息发送到服务器
    try {
      final response = await Dio().post(
        // 替换为你的服务器API
        'http://revenue-api.test.fancyzh.top/apple-register.php',
        options: Options(headers: {
          'Content-Type': 'application/json',
        }),
        data: jsonEncode(userInfo),
      );
      if (response.statusCode == 200) {
        // 成功处理
        debugPrint('User information saved to server successfully');
        // 保存登录信息到本地
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', userInfo['givenName']!);
        await prefs.setString('userEmail', userInfo['email']!);
        await prefs.setString('userIdentifier', userInfo['userIdentifier']!);

        // 更新 UI
        setState(() {
          userName = userInfo['givenName'];
          userEmail = userInfo['email'];
          userIdentifier = userInfo['userIdentifier'];
        });
        // 显示成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('登录成功！')),
        );
      } else {
        // 处理错误
        debugPrint(
            'Failed to save user information to server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Apple sign-in failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CherishAppbar(
        title: '登录',
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Apple ID 登录按钮
                ElevatedButton.icon(
                  onPressed: _signInWithApple,
                  icon: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.asset(
                      'assets/images/apple.png',
                      width: 30,
                      height: 30,
                      alignment: Alignment.center, // 保证图标居中对齐
                    ),
                  ),
                  label: Text('Apple登录'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50), // 按钮宽度
                    textStyle: TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22), // 添加圆角
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12), // 上下间距
                  ),
                ),
                SizedBox(height: 20), // 按钮之间的间距
                // 微信登录按钮
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: 处理微信登录逻辑
                  },
                  icon: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Container(
                      child: Image.asset(
                        'assets/images/wechat.png',
                        width: 30,
                        height: 30,
                        alignment: Alignment.center, // 保证图标居中对齐
                      ),
                    ),
                  ),
                  label: Text('微信登录   '),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    textStyle: TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22), // 添加圆角
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12), // 上下间距
                  ),
                ),
                SizedBox(height: 20), // 额外间距
              ],
            ),
          )),
    );
  }
}
