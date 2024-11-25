import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tools/common.dart';

class EncryptSecure extends StatefulWidget {
  const EncryptSecure({super.key});

  @override
  State<EncryptSecure> createState() => _EncryptSecureState();
}

class _EncryptSecureState extends State<EncryptSecure> {
  Map<String, dynamic> userInfo = {};

  // 假设登录成功后，将加密密钥上传到服务器（秘钥在一开始就会生成）
  Future<void> _onReadyUploadEncryptionKey(String userId) async {
    debugPrint("userId: $userId");
    // Step 1: 获取加密密钥(初始化就需要生成)
    String encryptionKey = await getOrCreateEncryptionKey();
    debugPrint('response data is $encryptionKey');

    // 获取userid
    // Step 2: 将加密密钥上传到服务器
    await _uploadEncryptionKey(userId, encryptionKey);
    print('Encryption key uploaded successfully');
  }

// 将加密密钥上传到服务器
  Future<void> _uploadEncryptionKey(String userId, String encryptionKey) async {
    // 使用share_prefrense记录是否上传过的状态
    final prefs = await SharedPreferences.getInstance();
    bool hasUploaded = prefs.getBool('hasUploadedEncryptionKey') ?? false;
    if (hasUploaded) {
      debugPrint('Encryption key has already been uploaded');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Encryption key has already been uploaded')),
      );
      return;
    }
    const url = 'http://192.168.2.9:6066/api/users-mingji/userinfo/store-key';

    // 构建请求体
    final response = await Dio().post(url,
        options: Options(
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer ${userInfo['token']}',
          },
        ),
        data: Map<String, dynamic>.from({
          'userId': userId,
          'encryptionKey': encryptionKey,
        }));

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Encryption key uploaded successfully');
      prefs.setBool('hasUploadedEncryptionKey', true);
    } else {
      print('Failed to upload encryption key: ${response.statusCode}');
    }
  }

// 调用请求上传秘钥
  Future<void> _requestUploadEncryptionKey() async {
    final userId = userInfo['user']['id'];
    if (userId == null) {
      print('User ID not found');
      return;
    }

    await _uploadEncryptionKey(
        userId.toString(), await getOrCreateEncryptionKey());
  }

// 假设登录成功后获取到的用户ID
  Future<void> _fetchAndStoreEncryptionKey() async {
    final userId = userInfo['user']['id'];
    if (userId == null) {
      print('User ID not found');
      return;
    }

    final url = 'http://192.168.2.9:6066/api/users-mingji/get-key/$userId';

    // 通过API获取用户加密密钥
    final response = await Dio().get(url,
        options: Options(headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer ${userInfo['token']}',
        }));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final sb = GeneralResult.fromMap(response.data).data;
      debugPrint('Response: ${sb.toString()}');
      final encryptionKey = sb['encryptionKey'];
      debugPrint('Encryption key: $encryptionKey');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Encryption key: $encryptionKey'),
        ),
      );
      return;
      // 将加密密钥存储在secure storage
    } else {
      print('Failed to fetch encryption key');
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    userInfo = {};
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        child: Scaffold(
            body: CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('加密安全'),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 打开modal
              ElevatedButton(
                  child: Text('打开modal'),
                  onPressed: () => showCupertinoModalBottomSheet(
                        expand: true,
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => Container(),
                      )),
              ElevatedButton(
                onPressed: _login,
                child: Text('登录'),
              ),
              if (userInfo.isNotEmpty && userInfo['user']['id'] != null)
                ElevatedButton(
                  onPressed: _fetchAndStoreEncryptionKey,
                  child: Text('获取秘钥'),
                ),
              if (userInfo.isNotEmpty && userInfo['user']['id'] != null)
                ElevatedButton(
                  onPressed: _requestUploadEncryptionKey,
                  child: Text('上传秘钥'),
                ),
            ],
          ),
        ),
      ),
    )));
  }

  Future<void> _login() async {
    var dio = Dio();
    dio.options.headers = {
      'Content-Type': 'application/json',
    };
    var response = await dio.post<Map<String, dynamic>>(
        'http://192.168.2.9:6066/api/users-mingji/register',
        data: {
          "userIdentifier": "71",
          "email": "g.cdkaaw@qq.com",
          "familyName": "43",
          "givenName": "765"
        });
    debugPrint('response data is ${response.data}');
    debugPrint('response data is ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      debugPrint("response data is ${data.toString()}");
      if (data != null) {
        setState(() {
          userInfo = GeneralResult.fromMap(data).data;
        });
        print("response data is not null ${GeneralResult.fromMap(data).data}");
        if (userInfo['user']['id'] != null) {
          _onReadyUploadEncryptionKey(userInfo['user']['id'].toString());
        }
      } else {
        print('response data is null');
      }
    } else {
      print(response.statusMessage);
    }
  }

  Future<void> _showModal(BuildContext context) async {
    showCupertinoModalBottomSheet(
        expand: false,
        isDismissible: true,
        context: context,
        builder: (_) => Container(
              height: 500,
              color: Colors.red,
            ));
  }
}
