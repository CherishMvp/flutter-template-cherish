import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WeatherIcon extends StatelessWidget {
  final String weatherIconCode;

  const WeatherIcon(this.weatherIconCode, {super.key});

  @override
  Widget build(BuildContext context) {
    // 动态生成图标的本地路径
    final String iconPath = 'assets/weather/icons/$weatherIconCode.svg';

    return SvgPicture.asset(
      iconPath,
      placeholderBuilder: (BuildContext context) =>
          CircularProgressIndicator(), // 加载中的占位符
      width: 50, // 设置图标宽度
      height: 50, // 设置图标高度
      semanticsLabel: 'Weather Icon',
    );
  }
}
