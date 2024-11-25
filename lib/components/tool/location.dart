import 'package:com.cherish.mingji/api/index.dart';
import 'package:com.cherish.mingji/api/nest_request.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../common/weather_icon.dart';

class LocationExample extends StatefulWidget {
  const LocationExample({super.key});

  @override
  State<StatefulWidget> createState() => _LocationExampleState();
}

class _LocationExampleState extends State<LocationExample> {
  String _locationMessage = "";
  String weatherIconCode = "100";
  // 天气信息
  String addressInfo = "";

  Map<String, dynamic>? weatherInfo = {
    'text': '',
    'windDir': '',
  };

  String get computedWeather =>
      '${weatherInfo!['text']}-${weatherInfo!['windDir']}' ?? '';
  // 获取权限并返回当前位置信息
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 检查是否启用了位置服务
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationMessage = "位置服务未启用";
      });
      return;
    }

    // 检查并请求位置权限
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationMessage = "位置权限被拒绝";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationMessage = "位置权限被永久拒绝";
      });
      return;
    }

    // 获取当前位置
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    debugPrint("当前位置: ${position.toString()}\n");
    // 分别打印经纬度
    debugPrint("当前位置: 经度: ${position.longitude}, 纬度: ${position.latitude}");
    setState(() {
      _locationMessage = "当前位置: 经度: ${position}, 纬度: ${position.latitude}";
    });
    if (position.latitude != 0 && position.longitude != 0) {
      getGeoInfo(position.latitude, position.longitude);
      // 获取天气信息
      getWeatherInfo(position.latitude, position.longitude);
    }
  }

// 传入经纬度获取地理位置信息
  void getGeoInfo(double latitude, double longitude) async {
    DioClient dioClient = DioClient();

    Map<String, dynamic> postData = {
      "lat": latitude,
      "lon": longitude,
    };

    ApiResponse<Map<String, dynamic>> response =
        await dioClient.post(API.getGeoInfo, postData, (data) => data);
    if (response.errno == 0) {
      debugPrint('请求成功: ${response.data}');
      if (response.data['formatted_address'] != null) {
        setState(() {
          _locationMessage = response.data['formatted_address'];
        });
      }
      if (response.data['address'] != null) {
        setState(() {
          addressInfo = response.data['address'];
        });
      }
    } else {
      debugPrint('请求失败: ${response.message}');
    }
  }

  // 获取天气信息
  void getWeatherInfo(double latitude, double longitude) async {
    DioClient dioClient = DioClient();

    Map<String, dynamic> postData = {
      "lat": latitude,
      "lon": longitude,
    };

    ApiResponse<Map<String, dynamic>> response =
        await dioClient.post(API.getWeather, postData, (data) => data);
    if (response.errno == 0) {
      debugPrint('请求成功天气信息: ${response.data}');
      if (response.data.isNotEmpty) {
        setState(() {
          weatherInfo = response.data;
          weatherIconCode = response.data['icon'];
        });
      }
    } else {
      debugPrint('请求失败: ${response.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("位置获取示例"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            WeatherIcon(weatherIconCode), // 根据API数据动态显示天气图标
            Text(computedWeather),
            Text('Weather Icon Code: $weatherIconCode'),
            SizedBox(
              height: 20,
            ),
            Text('地址信息: $addressInfo'),
            Text(
              "详细地址:$_locationMessage",
              maxLines: 1,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              child: Text("获取当前位置"),
            ),
          ],
        ),
      ),
    );
  }
}
