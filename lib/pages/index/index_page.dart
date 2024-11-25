import 'dart:developer';
import 'package:com.cherish.mingji/pages/person/index.dart';
import 'package:com.cherish.mingji/provider/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        // 主頁
        Center(
          child: Text("ssm"),
        ),
        // 导航栏
        Consumer<AppState>(builder: (context, app, child) {
          final mainTabbar = Container(
            alignment: Alignment.center, // 子组件在 Container 中居中对齐
            key: ValueKey(1), // 确保每次切换时有不同的 key
            height: 70, // 导航栏的高度
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0), // 调整底部距离
              child: Container(
                width: MediaQuery.of(context).size.width * 0.5, // 宽度为屏幕的50%

                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? HexColor("#f6f6f6").withOpacity(0.9)
                      : HexColor("#404040").withOpacity(0.85), // 半透明效果

                  borderRadius: BorderRadius.circular(30), // 圆角效果
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _handlePageChange(0);
                      },
                      child: SvgPicture.asset(
                        'assets/svg/search.svg',
                        color: Theme.of(context).primaryColor,
                        width: 28,
                        height: 28,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _handlePageChange(1);
                      },
                      child: SvgPicture.asset(
                        'assets/svg/circle-plus.svg',
                        color: Theme.of(context).primaryColor,
                        width: 28,
                        height: 28,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _handlePageChange(2);
                      },
                      child: SvgPicture.asset(
                        'assets/svg/bolt.svg',
                        color: Theme.of(context).primaryColor,
                        width: 28,
                        height: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          return Align(
              alignment: Alignment.bottomCenter, // 底部居中对齐
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  // 定义切换时的动画
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: app.showScrollbar
                    ? mainTabbar
                    : SizedBox.shrink(key: ValueKey(0)), // 隐藏状态时
              ));
        }),
      ],
    ));
  }

  void _handlePageChange(int i) {
    switch (i) {
      case 0:
        setState(() {
          // _currentIndex = 0;
          ///NOTE - 搜索
          log("搜索功能search");
          context.push("/network_test_page");
          // context.push('/my_assets_select');
          log("upload");
          // searchFocusNode.requestFocus();
          // context.push('/audio_recorder');
        });
        break;
      case 1:
        _changePageByModal();
        break;
      case 2:
        context.push('/setting');
        break;
    }
  }

  void _changePageByModal() {
    showCupertinoModalBottomSheet(
        context: context, isDismissible: false, builder: (d) => SettingsPage());
  }
}
