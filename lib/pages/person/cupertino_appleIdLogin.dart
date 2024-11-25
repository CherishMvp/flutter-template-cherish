// ignore: file_names
import 'dart:convert';

import 'package:com.cherish.mingji/api/index.dart';
import 'package:com.cherish.mingji/api/nest_request.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CupertinoAppleidlogin extends StatefulWidget {
  const CupertinoAppleidlogin({super.key});

  @override
  State<StatefulWidget> createState() => _CupertinoAppleidloginState();
}

class _CupertinoAppleidloginState extends State<CupertinoAppleidlogin> {
  String? userName;
  String? userEmail;
  String? userIdentifier;

  @override
  void initState() {
    super.initState();
    // 尝试加载缓存的用户数据
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName');
      userEmail = prefs.getString('userEmail');
      userIdentifier = prefs.getString('userIdentifier');
    });
  }

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
      // 获取用户的名称和电子邮件

      // 用户信息提交到后端
      // 整理用户信息
      final userInfo = {
        'userIdentifier': appleCredential.userIdentifier, // Apple唯一标识符
        'email': appleCredential.email ?? '', // 可能为空
        'givenName': appleCredential.givenName ?? '', // 可能为空
        'familyName': appleCredential.familyName ?? '', // 可能为空
      };
      // 已经登录则不需要重复登录
      if (userIdentifier != null &&
          await SignInWithApple.getCredentialState(userIdentifier!) ==
              CredentialState.authorized) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('用户已登录')),
        );
        return;
      }
      await _registerUser(userInfo);
    } catch (e) {
      debugPrint('Apple sign-in failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登录失败，请重试！')),
      );
    }
  }
// 用户注册

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

  Future<void> _registerUser(Map<String, String?> userInfo) async {
    if (userInfo['userIdentifier'] == null && userInfo['email'] == null) {
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
          'Failed to save user information to server: ${response.message}');
    }
  }

  // 退出登录
  @override
  Widget build(BuildContext context) {
    return Material(
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Sign in With Apple'),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              userName != null
                  ? Text(
                      'Welcome, $userName\nEmail: $userEmail\nIdentifier: $userIdentifier')
                  : Text('You are not signed in'),
              SizedBox(height: 20),
              CupertinoButton.filled(
                child: Text('Sign in with Apple'),
                onPressed: _signInWithApple,
              ),
              SizedBox(
                height: 20,
              ),
              CupertinoButton.filled(
                child: Text('Mock Sign in with Apple'),
                onPressed: _mockSignInWithApple,
              ),
              SizedBox(
                height: 20,
              ),
              if (1 > 2 && userName != null)
                CupertinoButton.filled(
                  onPressed: _getUserInfo,
                  child: const Text('get userinfo'),
                ),
              // 退出登录
              if (userName != null)
                CupertinoButton(
                  child: Text('Sign out'),
                  onPressed: () async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.remove('userName');
                    await prefs.remove('userEmail');
                    await prefs.remove('userIdentifier');
                    setState(() {
                      userName = null;
                      userEmail = null;
                      userIdentifier = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _mockSignInWithApple() {
    final userInfo = {
      'userIdentifier': 'test-appleid-login', // Apple唯一标识符
      'email': "test-appleid-login@163.com", // 可能为空
      'givenName': "name-mock", // 可能为空
      'familyName': "cherish-mock" // 可能为空
    };
    _registerUser(userInfo);
  }

  void _getUserInfo() {}
}
