import 'dart:io';

import 'package:com.cherish.mingji/components/common/cherish_appbar.dart';
import 'package:com.cherish.mingji/provider/app_state.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final primaryColor = theme.primaryColor;

    return Scaffold(
      appBar: CherishAppbar(
        title: "配置",
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              ListTile(
                visualDensity: VisualDensity(horizontal: -4.0), // 减少水平间距
                leading: Icon(Icons.edit_road_outlined, color: primaryColor),
                title: Text('图文混排'),
                subtitle: Text('是否开启图文混排功能'),
                isThreeLine: true,
                horizontalTitleGap: 8,
                trailing: Switch.adaptive(
                  activeColor: primaryColor,
                  value: Provider.of<AppState>(context).isTxtPhotoMerge,
                  onChanged: (value) {
                    Provider.of<AppState>(context, listen: false)
                        .setEditState(value);
                  },
                ),
                onTap: null,
              ),
              ListTile(
                visualDensity: VisualDensity(horizontal: -4.0), // 减少水平间距
                leading: Icon(Icons.cyclone, color: primaryColor),
                title: Text('首页轮播图'),
                subtitle: Text('轮播图自动播放开关'),
                isThreeLine: true,
                horizontalTitleGap: 8,
                trailing: Switch.adaptive(
                  activeColor: primaryColor,
                  value: Provider.of<AppState>(context).isHomeSwiperAutoPlay,
                  onChanged: (value) {
                    Provider.of<AppState>(context, listen: false)
                        .setHomeSwiperAutoPlay(value);
                  },
                ),
                onTap: null,
              ),
              ListTile(
                visualDensity: VisualDensity(horizontal: -4.0),
                horizontalTitleGap: 8,
                leading: Icon(Icons.image_outlined, color: primaryColor),
                title: Text('背景图更换'),
                subtitle: Text('点击图片切换背景图'),
                isThreeLine: true,
                onTap: () async {
                  final picker = ImagePicker();
                  final pickedFile =
                      await picker.pickImage(source: ImageSource.gallery);
                  debugPrint('response data is ${pickedFile?.path}');

                  if (pickedFile != null) {
                    if (mounted) {
                      Provider.of<AppState>(context, listen: false)
                          .setSelectedImage(File(pickedFile.path));
                    }
                  }
                },
                trailing: Consumer<AppState>(
                  builder: (context, appState, child) {
                    if (appState.selectedImage != null) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ClipOval(
                          child: Image.file(
                            appState.selectedImage!,
                            width: 35,
                            height: 35,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }
                    return Icon(Icons.image, color: Colors.grey);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
