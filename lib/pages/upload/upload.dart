import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:com.cherish.mingji/api/index.dart';
import 'package:com.cherish.mingji/utils/common.dart';
import 'package:com.cherish.mingji/utils/env.dart';
import 'package:flutter/material.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/nest-api/index.dart';
import '../../api/stream_request.dart';

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  _ImageUploadScreenState createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  File? _image;

  final ImagePicker _picker = ImagePicker();
  String displayedText = "11"; // 用于显示的逐字输出
  String fullText = "This is a sample response from the API."; // 模拟的全文本
  String reply = '';
  String? callBackUrl;
  final _controller = TextEditingController();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

// 清除缓存方法
  void _clearCache(File file) async {
    try {
      if (await file.exists()) {
        await file.delete(); // 删除文件
        debugPrint('缓存文件已删除: ${file.path}');
      }
    } catch (e) {
      debugPrint('删除缓存文件时出错: $e');
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;
    final res = await uploadImageGlobal(_image!);
    if (res != '') {
      if (mounted) zToast("上传成功", position: 'center', context: context);
      setState(() {
        callBackUrl = res;
      });
      // _clearCache(_image!);
    } else {
      zToast("上传失败，图片格式错误或图片太大", position: 'center', context: context);
    }
    debugPrint("res$res");
  }

  @override
  void initState() {
    super.initState();
    simulateTyping(fullText);
  }

  // 模拟打字机效果：逐字符显示
  void simulateTyping(String text) async {
    for (int i = 0; i < text.length; i++) {
      await Future.delayed(Duration(milliseconds: 100)); // 控制速度
      setState(() {
        displayedText += text[i]; // 每次加一个字符
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('图片上传'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image != null ? Image.file(_image!) : Text('请选择图片'),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('选择图片'),
            ),
            ElevatedButton(
              onPressed: _uploadImage,
              child: Text('上传图片'),
            ),
            // 生成传记
            ElevatedButton(
              onPressed: () {
                if (callBackUrl != '') {
                  // generateStory(callBackUrl!);
                  ApiService().streamResponse(
                      'http://cherish-bucket.oss-cn-shenzhen.aliyuncs.com/uploads/images/1726616938252-image_picker_B4EC080D-DE8F-4434-B2CC-389C62454BEE-17199-00000476DDCB25EA.jpg',
                      (newData) {
                    simulateTyping(newData);
                  });
                }
              },
              child: Text('生成传记'),
            ),
            ElevatedButton(
              onPressed: startSSE,
              child: Text('sse效果测试'),
            ),
            // 打字机效果
            Text(
              displayedText, // 动态显示的文本
              style: TextStyle(fontSize: 24),
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: 200,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        reply, // 动态显示的文本
                        style: TextStyle(fontSize: 24),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      TextField(
                        maxLines: 12,
                        controller: _controller,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void startSSE() {
    reply = '';
    SSEClient.subscribeToSSE(
      url: '$baseUrl${API.generateStory}', //mock url
      header: {
        "Accept": "text/event-stream",
        "Cache-Control": "no-cache",
      },
      method: SSERequestType.GET,
    ).listen(
      (event) async {
        try {
          log("event.event: ${event.event}");
          log("event.data length: ${event.data?.trim().length}");
          if (event.data != null && event.data?.trim() == '[DONE]') {
            log('Response completed: $reply');
            SSEClient.unsubscribeFromSSE(); // Close the SSE connection
          }
          if (event.event == 'result') {
            final res = event.data ?? '';
            debugPrint('Event data: $res');

            // Assuming the data structure is similar to your provided example
            await handleTextInput(res);
          }
        } catch (e) {
          debugPrint('Error processing SSE data: $e');
        }
      },
      onError: (error) {
        debugPrint('SSE Error: $error');
        SSEClient.unsubscribeFromSSE(); // Close on error
      },
      onDone: () => {
        debugPrint('SSE connection closed'),
        SSEClient.unsubscribeFromSSE() // Close the SSE connection
      },
    );
  }

  ///处理文本输入
  Future<void> handleTextInput(String res) async {
    // Assuming the data structure is similar to your provided example
    final decodedData = jsonDecode(res);
    await Future.delayed(const Duration(milliseconds: 100)); // 控制速度

    setState(() {
      reply += decodedData['output']['choices'][0]['message']['content'][0]
              ['text'] ??
          '';
      _controller.text += decodedData['output']['choices'][0]['message']
              ['content'][0]['text'] ??
          '';
    });

    debugPrint('Current reply: $reply');
  }
}
