import 'dart:io';
import 'package:com.cherish.mingji/api/index.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../nest_request.dart';

// upload demo
Future<String> uploadImageGlobal(File image) async {
  DioClient dioClient = DioClient();
  String imagePath = image.path; // 选择的图片路径

  try {
    // 调用上传图片接口
    ApiResponse<Map<String, dynamic>> response =
        await dioClient.uploadImage(imagePath);
    // 检查请求是否成功 (errno == 0 表示成功)
    if (response.errno == 0) {
      debugPrint('上传成功: ${response.data['url']}');
      return response.data['url'];
    } else {
      debugPrint('上传失败: ${response.message}');
      return '';
    }
  } catch (e) {
    debugPrint('Error occurred: $e');
    return '';
  }
}

// post demo
void postData() async {
  DioClient dioClient = DioClient();

  Map<String, dynamic> postData = {
    "key": "value",
  };

  // 调用 POST 请求
  ApiResponse<Map<String, dynamic>> response =
      await dioClient.post('/data/post', postData, (data) => data);

  if (response.errno == 0) {
    // debugPrint('请求成功: ${response.data}');
  } else {
    debugPrint('请求失败: ${response.message}');
  }
}

// 调用生成传记方法
void generateStory(String imageUrl) async {
  DioClient dioClient = DioClient();
  Map<String, dynamic> postData = {
    "imageUrl": imageUrl,
  };
  debugPrint('请求参数: ${postData}');
  ApiResponse<Map<String, dynamic>> response =
      await dioClient.post(API.generateStory, postData, (data) => data);
  if (response.errno == 0) {
    debugPrint('请求成功: ${response.data}');
  } else {
    debugPrint('请求失败: ${response.message}');
  }
}

// 天气地址
Future<Map<String, dynamic>> fetchLocationAndWeather(
    double latitude, double longitude) async {
  DioClient dioClient = DioClient();

  // 返回的结果 Map
  Map<String, dynamic> result = {
    'address': '',
    'formattedAddress': '',
    'weather': '',
    'weatherIconCode': '',
    "windDir": ""
  };

  // 获取地理位置信息
  Map<String, dynamic> geoPostData = {
    "lat": latitude,
    "lon": longitude,
  };

  // 获取地理位置信息的请求
  ApiResponse<Map<String, dynamic>> geoResponse =
      await dioClient.post(API.getGeoInfo, geoPostData, (data) => data);

  if (geoResponse.errno == 0) {
    debugPrint('地理位置信息请求成功: ${geoResponse.data}');

    result['formattedAddress'] = geoResponse.data['formatted_address'] ?? '';
    result['address'] = geoResponse.data['address'] ?? '';
  } else {
    debugPrint('地理位置信息请求失败: ${geoResponse.message}');
  }

  // 获取天气信息
  Map<String, dynamic> weatherPostData = {
    "lat": latitude,
    "lon": longitude,
  };

  // 获取天气信息的请求
  try {
    ApiResponse<Map<String, dynamic>> weatherResponse =
        await dioClient.post(API.getWeather, weatherPostData, (data) => data);

    if (weatherResponse.errno == 0) {
      debugPrint('天气信息请求成功: ${weatherResponse.data}');

      result['weather'] = weatherResponse.data['text'] ?? '';
      result['weatherIconCode'] = weatherResponse.data['icon'] ?? '';
      result['windDir'] = weatherResponse.data['windDir'] ?? '';
    } else {
      debugPrint('天气信息请求失败: ${weatherResponse.message}');
    }
  } on Exception catch (e) {
    // TODO
    EasyLoading.showError('位置服务调整中');
  }

  return result;
}
