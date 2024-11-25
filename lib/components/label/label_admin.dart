import 'dart:developer';

import 'package:com.cherish.mingji/components/common/cherish_appbar.dart';
import 'package:com.cherish.mingji/model/label_info.dart';
import 'package:com.cherish.mingji/provider/pro_status_provider.dart';
import 'package:com.cherish.mingji/utils/constants.dart';
import 'package:com.cherish.mingji/utils/revenuecat/pay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:go_router/go_router.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:provider/provider.dart';

class LabelAdmin extends StatefulWidget {
  const LabelAdmin({super.key});

  @override
  State<LabelAdmin> createState() => _LabelAdminState();
}

class _LabelAdminState extends State<LabelAdmin> {
  List<LabelItem> _labelListItems = [];

  final TextEditingController titleController = TextEditingController();
  final TextEditingController subtitleController = TextEditingController();
  String bgColor = '#BFAAAa'; // 默认颜色

  @override
  void initState() {
    super.initState();
    _fetchLabelListItems();
  }

  @override
  void dispose() {
    titleController.dispose();
    subtitleController.dispose();
    super.dispose();
  }

  Future<void> _fetchLabelListItems() async {
    try {
      final sql = SQLHelper();
      List<LabelItem> labelListItems = await sql.getLabelListItems();
      setState(() {
        _labelListItems = labelListItems;
        log("_labelListItems" + _labelListItems.toString());
      });
    } catch (e) {
      log("error" + e.toString());
      // TODO: Handle error
    }
  }

  String colorToHex(Color color) {
    // 提取颜色的 ARGB 值，并将它们拼接为 #RRGGBB 的形式
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  void _showCreateLabelModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20), // 上方圆角
        ),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            height: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    '创建新标签',
                    style: TextStyle(
                      fontSize:
                          Theme.of(context).textTheme.titleLarge?.fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 使用 _textField 组件
                _textField('标签名称', titleController),
                const SizedBox(height: 12),

                _textField('标签描述', subtitleController),
                const SizedBox(height: 12),

                // 颜色选择器
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Row(
                    children: [
                      const Text('选择颜色  '),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog.adaptive(
                                title: const Text('选择颜色'),
                                content: SingleChildScrollView(
                                  child: MaterialPicker(
                                    pickerColor: HexColor(bgColor),
                                    onColorChanged: (value) =>
                                        _changeColor(value), // 颜色变化时的回调
                                    enableLabel: true, // 显示颜色值
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: HexColor(bgColor),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 创建按钮
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () {
                        debugPrint(
                            "titleController.text${titleController.text}");
                        if (titleController.text.isNotEmpty &&
                            subtitleController.text.isNotEmpty) {
                          _createLabel(
                            title: titleController.text,
                            subtitle: subtitleController.text,
                            bgColor: bgColor,
                          );
                          Navigator.pop(context); // 关闭 modal
                        } else {
                          zToast("请输入有效的标签",
                              position: 'center', context: context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        fixedSize: const Size(double.maxFinite, 40),
                      ),
                      child: Text(
                        '创建',
                        style: TextStyle(
                            fontSize: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.fontSize),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createLabel(
      {required String title,
      String subtitle = '',
      required String bgColor}) async {
    try {
      // 判断输入信息
      if (title.isEmpty || subtitle.isEmpty) {
        zToast("请输入有效的标签", position: 'center', context: context);
        return;
      }

      // return;
      final sql = SQLHelper();
      int id = await sql.createLabelItem(title, subtitle, bgColor, true);
      log("id$id");
      if (id > 0) {
        log("创建成功");
        zToast("创建成功", position: 'center', context: context);
        Future.delayed(const Duration(milliseconds: 500), () {
          _fetchLabelListItems();
        });
        // 清空上次的内容
        titleController.clear();
        subtitleController.clear();
        bgColor = 'ffffff';
      }
    } catch (e) {
      log("Error creating label: $e");
    }
  }

  // 删除操作
  Future<void> _deleteItem(int index) async {
    // 在这里处理你的删除逻辑，比如从列表中移除项目
    try {
      final sql = SQLHelper();
      int id = await sql.deleteLabelItem(index);
      if (id > 0) {
        debugPrint("Item at index $index has been deleted.");
        EasyLoading.showToast("删除成功");
        _fetchLabelListItems();
      } else {
        EasyLoading.showToast("删除失败(默认补签不可删除)");
      }
    } catch (e) {
      // TODO: Handle error
    }
  }

  // 修改
  Future<void> _updateItem(int index) async {
    // 在这里处理你的删除逻辑，比如从列表中移除项目
    try {
      final sql = SQLHelper();
      final item = _labelListItems[index];
      final upItem = LabelItem(
          id: item.id,
          title: '测试修改',
          subtitle: '测试修改',
          bgColor: item.bgColor,
          isUserAdd: item.isUserAdd);
      int id = await sql.updateLabelItem(upItem);
      if (id > 0) {
        debugPrint("Item at index $index has been deleted.");
        zToast("删除成功", position: 'center', context: context);
        _fetchLabelListItems();
      }
    } catch (e) {
      // TODO: Handle error
    }
  }

  void _onFloatingButtonPressed(BuildContext context) async {
    // _createLabel(title: "测试创建");
    final payState = await checkAppPurchase();
    if (!payState) {
      EasyLoading.showError('请检查网络');
      return;
    }
    final isPro = await Provider.of<ProStatusProvider>(context, listen: false)
        .checkProStatus();
    if (!isPro) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog.adaptive(
          title: const Text('提示'),
          content: const Text('需要购买专业版解除创建标签限制'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('取消'),
              style: TextButton.styleFrom(),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确定'),
              style: TextButton.styleFrom(),
            ),
          ],
        ),
      ).then((onValue) async {
        debugPrint("asdasd" + onValue.toString());
        if (onValue) {
          payConfigure().then((_) async {
            await handlePayGlobal();
          });
        }
      });
      return;
    }
    _showCreateLabelModal(context);
  }

  // 删除
  Widget adaptiveAction(
      {required BuildContext context,
      required VoidCallback onPressed,
      required Widget child}) {
    final ThemeData theme = Theme.of(context);
    switch (theme.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return TextButton(onPressed: onPressed, child: child);
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return CupertinoDialogAction(onPressed: onPressed, child: child);
    }
  }

  /// 输入组件
  Widget _textField(final String hint, final TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(width: 1.0)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(width: 1.0)),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CherishAppbar(
        title: '标签管理',
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            _onFloatingButtonPressed(context);
          },
          child: const Icon(Icons.add)),
      body: RefreshIndicator(
        onRefresh: _fetchLabelListItems, // 使用Material风格的下拉刷新
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 每行显示2个元素
                  mainAxisSpacing: 8.0, // 行间距
                  crossAxisSpacing: 6.0, // 列间距
                  childAspectRatio: 1.0, // 宽高比
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () => _updateItem(index),
                        onLongPress: () {
                          debugPrint("Long pressed on item with index: $index");
                          _showDeleteDialog(_labelListItems[index].id);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _labelListItems[index].bgColor, // 背景颜色
                            borderRadius: BorderRadius.circular(10), // 圆角
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _labelListItems[index].title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  _labelListItems[index].subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _labelListItems.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(int index) {
    showAdaptiveDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog.adaptive(
        title: const Text('提示'),
        content: const Text('是否删除该标签?'),
        actions: <Widget>[
          adaptiveAction(
            context: context,
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('取消'),
          ),
          adaptiveAction(
            context: context,
            onPressed: () async {
              await _deleteItem(index);
              Navigator.pop(context);
            },
            child: Text('确认',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  _changeColor(Color color) {
    log("color$color");
    setState(() {
      bgColor = '#${color.toHexString(includeHashSign: true)}';
    });
    log("bgColor$bgColor");
  }
}
