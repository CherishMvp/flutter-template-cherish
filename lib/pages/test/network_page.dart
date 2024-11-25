import 'package:com.cherish.mingji/api/index.dart';
import 'package:com.cherish.mingji/api/nest_request.dart';
import 'package:flutter/material.dart';

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  String _locationMessage = '';
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
    } else {
      debugPrint('请求失败: ${response.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Network Page")),
      body: Center(
          child: Column(
        children: [
          Text('我的位置$_locationMessage'),
          ElevatedButton(
              onPressed: () {
                getGeoInfo(39.9, 116.4);
              },
              child: Text("获取当前位置"))
        ],
      )),
    );
  }
}
