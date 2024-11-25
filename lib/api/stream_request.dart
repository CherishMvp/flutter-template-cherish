import 'dart:convert'; // 用于解析 JSON
import 'package:com.cherish.mingji/utils/env.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'index.dart';

class ApiService {
  Dio _dio = Dio();

  Future<void> streamResponse(String imgUrl, Function(String) onData) async {
    const String url = "$baseUrl${API.generateStory}";

    final headers = {
      "Authorization": "Bearer YOUR_DASHSCOPE_API_KEY",
      "Content-Type": "application/json",
    };

    try {
      final response = await _dio.post<ResponseBody>(
        url,
        data: {
          "imageUrl": imgUrl,
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: headers,
        ),
      );

      debugPrint('Response: ${response.data.toString()}');
      // 监听流数据
      response.data!.stream.listen((chunk) {
        final chunkString = String.fromCharCodes(chunk);
        _processStreamedData(chunkString, onData);
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  // 处理服务器返回的流式数据
  void _processStreamedData(String dataChunk, Function(String) onData) {
    // 解析 chunk，提取 data 部分
    final lines = dataChunk.split('\n');
    for (var line in lines) {
      if (line.startsWith('data:')) {
        final jsonData = line.substring(5).trim(); // 去掉 "data:" 前缀
        try {
          final jsonMap = jsonDecode(jsonData); // 解析 JSON
          final content =
              jsonMap['output']['choices'][0]['message']['content'][0]['text'];
          onData(content); // 将解析后的文本传递给前端处理
        } catch (e) {
          print('Error parsing JSON: $e');
        }
      }
    }
  }
}
