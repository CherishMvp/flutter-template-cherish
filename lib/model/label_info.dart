import 'dart:ui';

import 'package:hexcolor/hexcolor.dart';

class LabelItem {
  final int id;
  final String title;
  final String subtitle;
  // void Function()? onTap;
  final Color bgColor;
  final int isUserAdd;
  LabelItem(
      {required this.id,
      required this.title,
      required this.subtitle,
      // this.onTap,
      required this.bgColor,
      this.isUserAdd = 0}); // this.onTap

  // 用于将对象转换成Map（通常在数据库操作中使用）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'bgColor': bgColor,
      'isUserAdd': isUserAdd, // bool转换成数据库中的整数
    };
  }

  // 从Map创建LabelItem对象
  factory LabelItem.fromMap(Map<String, dynamic> map) {
    return LabelItem(
      id: map['id'],
      title: map['title'],
      subtitle: map['subtitle'],
      bgColor: map['bgColor'],
      isUserAdd: map['isUserAdd'],
    );
  }
}

final colorMap = {
  '默认分类': HexColor('#CC5500'),
  'Todo': HexColor('#B22222'),
  'Goals': HexColor('#FFBF00'),
};

final LabelListItems = [
  LabelItem(
      id: 1,
      title: '默认分类',
      subtitle: '',
      bgColor: HexColor('#CC5500'),
      isUserAdd: 0),
  LabelItem(
      id: 2,
      title: 'Todo',
      subtitle: ' ',
      bgColor: HexColor('#B22222'),
      isUserAdd: 0),
  LabelItem(
      id: 3,
      title: 'Goals',
      subtitle: ' ',
      bgColor: HexColor('#FFBF00'),
      isUserAdd: 0),
];
