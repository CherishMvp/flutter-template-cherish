import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:com.cherish.mingji/api/index.dart';
import 'package:com.cherish.mingji/utils/env.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
// ignore: slash_for_doc_comments
/**
 * ApiResponse<T>：这是自定义的响应泛型类，处理后端返回的数据。它包含了 errno、message 和 data，对应你后端的接口设计。
 * T 是 data 的类型，由外部定义。fromJsonT 是一个函数，用于解析 data 的结构。
 * DioClient 类：封装了 Dio 的常见操作（get、post、上传图片）。这样不仅代码清晰，而且可以重复使用，减少了耦合。
 * _handleResponse 和 _handleError：这两个方法负责处理成功的响应和错误响应。通过这些方法可以确保所有的请求在出错时都能得到一致的处理。
 * 上传图片接口：上传图片时将文件封装为 FormData，调用 post 方法上传文件，并返回带有 URL 的响应。
 **/

// 定义泛型接口对应的类型
class ApiResponse<T> {
  final T data;
  final int errno;
  final String message;

  ApiResponse({required this.data, required this.errno, required this.message});

  // 从 JSON 解析出 ApiResponse 实例
  factory ApiResponse.fromJson(
      Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    return ApiResponse(
      data: fromJsonT(json['data']), // 将 data 部分反序列化
      errno: json['errno'],
      message: json['message'],
    );
  }
}

class DioClient {
  late Dio _dio;
  DioClient() {
    debugPrint("baseUrl$baseUrl");
    // 初始化 Dio 实例
    _dio = Dio(
      BaseOptions(
        // baseUrl: macDevBaseUrl, // 后端服务地址
        baseUrl: baseUrl, // 后端服务地址
        connectTimeout: Duration(milliseconds: 10000), // 连接超时
        receiveTimeout: Duration(milliseconds: 10000), // 响应超时
      ),
    );

    // 添加拦截器 (日志拦截器，便于调试)

    // _dio.interceptors.add(LogInterceptor(
    //   request: true,
    //   requestBody: true,
    //   responseBody: true,
    //   error: true,
    // ));
    // 添加拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 从本地存储（例如SharedPreferences）中获取保存的token
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('token'); // 获取token
        // 如果存在token，将其添加到请求头
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        // 继续请求
        return handler.next(options);
      },
    ));
  }

  // 通用的 GET 请求方法
  Future<ApiResponse<T>> get<T>(
      String path, T Function(dynamic) fromJsonT) async {
    try {
      final response = await _dio.get(path);
      return _handleResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  // 通用的 POST 请求方法
  Future<ApiResponse<T>> post<T>(
      String path, dynamic data, T Function(dynamic) fromJsonT) async {
    try {
      final response = await _dio.post(path, data: data);
      return _handleResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  // 上传文件方法，返回 ApiResponse 泛型
  Future<ApiResponse<Map<String, dynamic>>> uploadImage(String filePath) async {
    // 压缩上传
    final originalImageBytes = await File(filePath).readAsBytes();
    log("originalImageBytes:$originalImageBytes");
    final decodedImage = img.decodeImage(originalImageBytes);
    log("decodedImage${decodedImage}");
    if (decodedImage == null) {
      throw Exception("图片解码失败");
    }
    // 将图片压缩到 60% 质量
    final compressedImageBytes = img.encodeJpg(decodedImage, quality: 60);
    try {
      final multipartFile = MultipartFile.fromBytes(
        compressedImageBytes,
        filename: path.basename(filePath),
      );
      FormData formData = FormData.fromMap({
        'file': multipartFile,
      });
      final response = await _dio.post(API.uploadImage, data: formData);

      return _handleResponse<Map<String, dynamic>>(response, (data) => data);
    } on DioException catch (e) {
      return _handleError<Map<String, dynamic>>(e);
    }
  }

  // 流式 POST 请求方法
  Future<void> stream<T>(
    String path,
    String imgUrl,
    Function(T) onData,
    T Function(dynamic) fromJsonT,
  ) async {
    try {
      // 发送 POST 请求
      final response = await _dio.post<ResponseBody>(
        path,
        data: {
          'imgUrl': imgUrl, // 请求体中的 imgUrl
        },
        options: Options(responseType: ResponseType.stream),
      );

      // 正确处理 ResponseBody 数据流
      final responseStream = response.data!.stream;
      debugPrint("Response stream: $responseStream");
      // 监听流数据
      responseStream.listen((chunk) {
        final chunkString = String.fromCharCodes(chunk);
        debugPrint("Chunk received: $chunkString");

        // 处理流事件并解析数据
        final events = chunkString.split('\n\n');
        for (var event in events) {
          if (event.trim().isNotEmpty) {
            _processStreamEvent(event, fromJsonT, onData);
          }
        }
      }, onError: (error) {
        debugPrint("Stream error: $error");
      }, onDone: () {
        debugPrint("Stream done");
      });
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // 处理每个流事件，逐字显示内容
  void _processStreamEvent<T>(
    String event,
    T Function(dynamic) fromJsonT, // 用于解析 data 数据的泛型函数
    Function(T) onData, // 处理数据的回调函数
  ) {
    // 每个流事件都是以 '\n' 分隔的多行数据
    final lines = event.split('\n');
    String? data;

    // 查找以 'data:' 开头的行，它包含实际数据
    for (var line in lines) {
      if (line.startsWith('data:')) {
        data = line.substring(5).trim(); // 去掉 'data:' 前缀并清理空格
      }
    }

    if (data != null && data.isNotEmpty) {
      try {
        // 解析 JSON 数据
        final jsonData = jsonDecode(data);
        final outputChoices = jsonData['output']['choices'];

        if (outputChoices != null && outputChoices.isNotEmpty) {
          for (var choice in outputChoices) {
            final content = choice['message']['content'];

            // 处理文本内容，模拟逐字打字机效果
            if (content is List && content.isNotEmpty) {
              StringBuffer buffer = StringBuffer();
              for (var item in content) {
                if (item.containsKey('text')) {
                  buffer.write(item['text']); // 累积每块文本
                }
              }
              // 调用 onData 回调函数，将最终文本传递出去
              onData(fromJsonT({'text': buffer.toString()}));
            }
          }
        }
      } catch (e) {
        log('Error parsing JSON: $e');
      }
    }
  }
}

// 处理 HTTP 响应并解析成 ApiResponse<T>
ApiResponse<T> _handleResponse<T>(
    Response response, T Function(dynamic) fromJsonT) {
  if (response.statusCode == 200 ||
      response.statusCode == 201 ||
      response.statusCode == 204) {
    return ApiResponse<T>.fromJson(response.data, fromJsonT);
  } else {
    throw Exception('Failed with status code: ${response.statusCode}');
  }
}

// 错误处理，封装错误信息
ApiResponse<T> _handleError<T>(DioException error) {
  log("error.response: ${error.response}");
  log("error.response.data: ${error.response?.data}");
  if (error.response != null) {
    return ApiResponse(
      data: null as T,
      errno: error.response!.statusCode ?? -1,
      message: error.response!.data['message'] ?? 'Unknown error',
    );
  } else {
    return ApiResponse(
      data: null as T,
      errno: -1,
      message: 'Request failed: ${error.message}',
    );
  }
}
