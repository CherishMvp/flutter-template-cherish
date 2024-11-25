import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io'; // 用于读取本地文件

class WeatherIconSelector extends StatelessWidget {
  final List<String> iconList;
  final Function(String) onIconSelected;

  const WeatherIconSelector(
      {super.key, required this.iconList, required this.onIconSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 550,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '天气选择',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 30.0, vertical: 8.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 40.0,
                mainAxisSpacing: 20.0,
              ),
              itemCount: iconList.length,
              itemBuilder: (context, index) {
                String iconName = iconList[index];

                return GestureDetector(
                  onTap: () {
                    onIconSelected(iconName);
                    Navigator.pop(context);
                  },
                  child: SvgPicture.asset(
                    'assets/weather/icons/$iconName.svg',
                    width: 50,
                    height: 50,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).primaryColor,
                      BlendMode.srcIn,
                    ),
                    placeholderBuilder: (BuildContext context) =>
                        CircularProgressIndicator(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

///NOTE - 调起图标选择器
void showWeatherIconSelector(BuildContext context, List<String> iconList,
    Function(String) onIconSelected) {
  debugPrint("调起图标选择器${iconList.length}");
  // 先关闭键盘
  FocusScope.of(context).unfocus();
  // 延迟 0.3 秒，等待键盘收起
  Future.delayed(Duration(milliseconds: 500));
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    // useRootNavigator: true, // 使用根 Navigator，速度提升
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return WeatherIconSelector(
        iconList: iconList,
        onIconSelected: onIconSelected,
      );
    },
  ).then((onValue) => {
        Future.delayed(Duration(milliseconds: 500)),
        FocusScope.of(context).requestFocus()
      });
}

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});

  @override
  _WeatherAppState createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  String selectedIcon = '100'; // 默认选择的图标
  List<String> iconList = []; // 图标文件名列表

  @override
  void initState() {
    super.initState();
    loadIcons(); // 加载图标
  }

  Future<void> loadIcons() async {
    // 从 AssetManifest.json 中获取所有资源文件
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    // 筛选出 assets/weather/icons 文件夹中的 SVG 文件
    final svgs = manifestMap.keys
        .where((String key) =>
            key.startsWith('assets/weather/icons/') && key.endsWith('.svg'))
        .map((String key) => key.split('/').last.split('.').first)
        .toList();

    setState(() {
      iconList = svgs; // 将 SVG 文件名保存到 iconList 中
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather Icon Selector'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/weather/icons/$selectedIcon.svg',
              width: 100,
              height: 100,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.primary,
                BlendMode.srcIn,
              ),
              placeholderBuilder: (BuildContext context) =>
                  CircularProgressIndicator(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showWeatherIconSelector(context, iconList, (selectedIcon) {
                  setState(() {
                    this.selectedIcon = selectedIcon; // 更新选中的图标
                  });
                });
              },
              child: Text('Select Weather Icon'),
            ),
          ],
        ),
      ),
    );
  }
}
