import 'dart:io';
import 'package:com.cherish.mingji/api/index.dart';
import 'package:com.cherish.mingji/api/nest_request.dart';
import 'package:com.cherish.mingji/provider/app_state.dart';
import 'package:com.cherish.mingji/utils/revenuecat/pay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:com.cherish.mingji/utils/common.dart';

class SettingsPage extends StatefulWidget {
  /// 设置
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String appVersion = '0.0.1';
  final ScrollController _scrollController = ScrollController();
  bool _showBackButton = false;
  final TextEditingController _codeController = TextEditingController();
  @override
  void initState() {
    super.initState();
    // 监听滚动事件
    _scrollController.addListener(() {
      setState(() {
        _showBackButton = _scrollController.offset > 100;
      });
    });
    init();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> init() async {
    //
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      appVersion = prefs.getString("app_version") ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final primaryColor = theme.primaryColor;
    final scafColor = theme.scaffoldBackgroundColor;
    final Color hintTextColor = theme.hintColor;
    final isIos = Platform.isIOS;
    String icpNumber = "闽ICP备2023001613号-5A";

    bool isCodeBenifit = true;
//  自定义widget

    // ignore: non_constant_identifier_names
    Widget FormWidgetTwo = CupertinoListSection.insetGrouped(
        header: Text(
          "关于",
          style: TextStyle(fontSize: 16, color: primaryColor),
        ),
        children: [
          CupertinoListTile.notched(
            title: Text('检查更新', style: textTheme.titleSmall),
            leading:
                Icon(CupertinoIcons.arrow_down_circle, color: primaryColor),
            trailing: CupertinoListTileChevron(),
            onTap: () async {
              String appId = '6636551585';
              final String appStoreUrl =
                  'https://apps.apple.com/app/id${appId}'; //查看app
              final Uri url = Uri.parse(appStoreUrl);
              if (!await launchUrl(url)) {
                throw Exception('Could not launch $url');
              }
              return;
            },
          ),
          CupertinoListTile.notched(
            title: Text('关于我们', style: textTheme.titleSmall),
            leading: Icon(CupertinoIcons.info, color: primaryColor),
            trailing: CupertinoListTileChevron(),
            onTap: () {
              _handleLaunchUrl(context, Uri.parse("https://www.baidu.com"));
            },
          ),
          CupertinoListTile.notched(
            title: Text('隐私条款', style: textTheme.titleSmall),
            leading: Icon(CupertinoIcons.lock, color: primaryColor),
            trailing: CupertinoListTileChevron(),
            onTap: () {
              _handleLaunchUrl(context, Uri.parse(pravicyLink));
            },
          ),
          CupertinoListTile.notched(
            title: Text('数据备份', style: textTheme.titleSmall),
            leading: Icon(CupertinoIcons.info, color: primaryColor),
            trailing: CupertinoListTileChevron(),
            onTap: () {
              context.push('/data_backup');
            },
          ),
        ]);

    // ignore: non_constant_identifier_names
    Widget FormWidgetOne = CupertinoListSection.insetGrouped(
      header: Text(
        '基础',
        style: TextStyle(
          color: primaryColor,
          fontSize: 16,
        ),
      ),
      children: [
        CupertinoListTile.notched(
          title: Text('主题切换', style: textTheme.titleSmall),
          leading: Icon(CupertinoIcons.color_filter, color: primaryColor),
          trailing: CupertinoListTileChevron(),
          onTap: () {
            context.push('/change_theme');
          },
        ),
        CupertinoListTile.notched(
          title: Text('内容反馈', style: textTheme.titleSmall),
          leading: Icon(CupertinoIcons.pencil, color: primaryColor),
          trailing: CupertinoListTileChevron(),
          onTap: () {
            _handleLaunchUrl(
                context,
                Uri.parse(
                    "https://blog.csdn.net/CherishTaoTao/article/details/139294328"));
          },
        ),
        CupertinoListTile.notched(
          title: Text('给个好评', style: textTheme.titleSmall),
          leading: Icon(CupertinoIcons.star, color: primaryColor),
          trailing: CupertinoListTileChevron(),
          onTap: () => handleRating(context),
        ),
        CupertinoListTile.notched(
          title: Text('推荐码', style: textTheme.titleSmall),
          leading: Icon(CupertinoIcons.gift, color: primaryColor),
          trailing: CupertinoListTileChevron(),
          onTap: () {
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('提示'),
                content: const Text('敬请期待'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('确定'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );

    return isIos || Platform.isAndroid
        ? Scaffold(
            backgroundColor: scafColor,
            body: CustomScrollView(
              controller: _scrollController, // 绑定 ScrollController
              slivers: [
                SliverAppBar(
                  floating: true,
                  title: _showBackButton ? const Text('设置') : null,
                  centerTitle: true,
                  pinned:
                      _showBackButton, // Keeps the app bar visible when scrolling
                  stretch: true, // Enables the stretch effect
                  leading: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: _showBackButton || (2 > 1)
                        ? IconButton(
                            highlightColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            icon: Icon(
                              Icons.arrow_back_ios_new,
                              size: 24,
                            ),
                            onPressed: () {
                              if (GoRouter.of(context).canPop()) {
                                // GoRouter 的 canPop 判断
                                GoRouter.of(context).pop();
                              } else if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              } else {
                                // 根据需求决定，比如返回主页或其他行为
                                print("Nothing to pop");
                              }
                            },
                          )
                        : Container(
                            key: ValueKey('emptyContainer'),
                          ),
                  ),
                  expandedHeight: 200,
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [
                      StretchMode
                          .zoomBackground, // Enables the background image zoom effect
                      StretchMode
                          .blurBackground, // Optionally, blur the background when stretched
                      StretchMode
                          .fadeTitle, // Fades the title as the user scrolls down
                    ],
                    background: Consumer<AppState>(
                      builder: (context, appState, child) {
                        return Image.file(
                          appState.selectedImage!,
                          fit: BoxFit.cover,
                          colorBlendMode: BlendMode.darken,
                          color: Colors.black.withOpacity(0.5),
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        ListTile(
                          visualDensity:
                              VisualDensity(horizontal: -4.0), // 减少水平间距
                          title: Text(
                            '基础',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: textTheme.titleMedium!.fontSize,
                            ),
                          ),
                        ),
                        ListTile(
                          visualDensity:
                              VisualDensity(horizontal: -4.0), // 减少水平间距
                          leading: Icon(Icons.color_lens_outlined,
                              color: primaryColor),
                          title: Text('主题切换', style: textTheme.titleSmall),
                          horizontalTitleGap: 8,
                          trailing: CupertinoListTileChevron(),
                          onTap: () {
                            context.push('/change_theme');
                          },
                        ),
                        ListTile(
                          visualDensity:
                              VisualDensity(horizontal: -4.0), // 减少水平间距
                          leading:
                              Icon(Icons.memory_rounded, color: primaryColor),
                          title: Text('配置', style: textTheme.titleSmall),
                          horizontalTitleGap: 8,

                          trailing: CupertinoListTileChevron(),
                          onTap: () {
                            context.push('/config');
                          },
                        ),

                        ListTile(
                          visualDensity:
                              VisualDensity(horizontal: -4.0), // 减少水平间距
                          leading:
                              Icon(Icons.backup_outlined, color: primaryColor),
                          title: Text('数据备份', style: textTheme.titleSmall),
                          horizontalTitleGap: 8,

                          trailing: CupertinoListTileChevron(),
                          onTap: () {
                            context.push('/data_backup');
                          },
                        ),
                        if (1 > 2)
                          ListTile(
                            visualDensity:
                                VisualDensity(horizontal: -4.0), // 减少水平间距
                            leading:
                                Icon(Icons.code_outlined, color: primaryColor),
                            title: Text('推荐码', style: textTheme.titleSmall),
                            trailing: CupertinoListTileChevron(),
                            onTap: () {
                              showDialog(
                                  context: context,
                                  builder: (context) => isCodeBenifit == true
                                      ? AlertDialog.adaptive(
                                          title: const Text('提示'),
                                          content: const Text('是否前往兑换'),
                                          actions: [
                                            TextButton(
                                              onPressed: _handleCodeBenifit,
                                              child: const Text('确定'),
                                            ),
                                          ],
                                        )
                                      : AlertDialog.adaptive(
                                          title: const Text('提示'),
                                          content: const Text('敬请期待'),
                                          actions: [
                                            TextButton(
                                              child: const Text('确定'),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                            ),
                                          ],
                                        ));
                            },
                          ),
                        ListTile(
                          visualDensity:
                              VisualDensity(horizontal: -4.0), // 减少水平间距
                          leading: SvgPicture.asset(
                              'assets/svg/RiVipCrown2Line.svg',
                              color: primaryColor),
                          title: Text('会员', style: textTheme.titleSmall),
                          horizontalTitleGap: 8,

                          trailing: CupertinoListTileChevron(),
                          onTap: () {
                            // context.push('/restore');
                            _handleIAP(context);
                          },
                        ),
                        // 恢复内购
                        ListTile(
                          visualDensity:
                              VisualDensity(horizontal: -4.0), // 减少水平间距
                          leading:
                              Icon(Icons.restore_outlined, color: primaryColor),
                          title: Text('恢复内购', style: textTheme.titleSmall),
                          horizontalTitleGap: 8,

                          trailing: CupertinoListTileChevron(),
                          onTap: () {
                            // context.push('/restore');
                            _handleRestorePurchase(context);
                          },
                        ),
                        ListTile(
                          visualDensity:
                              VisualDensity(horizontal: -4.0), // 减少水平间距
                          leading: Icon(Icons.feedback_outlined,
                              color: primaryColor),
                          title: Text('内容反馈', style: textTheme.titleSmall),
                          horizontalTitleGap: 8,

                          trailing: CupertinoListTileChevron(),
                          onTap: () {
                            _handleLaunchUrl(
                                context,
                                Uri.parse(
                                    "https://blog.csdn.net/CherishTaoTao/article/details/139294328"));
                          },
                        ),
                        ListTile(
                          visualDensity:
                              VisualDensity(horizontal: -4.0), // 减少水平间距
                          leading:
                              Icon(Icons.star_outline, color: primaryColor),
                          title: Text('给个好评', style: textTheme.titleSmall),
                          horizontalTitleGap: 8,

                          trailing: CupertinoListTileChevron(),
                          onTap: () => handleRating(context),
                        ),
                        // 可以继续添加更多的 ListTile
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: // 关于部分
                      Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        ListTile(
                          visualDensity:
                              VisualDensity(horizontal: -4.0), // 减少水平间距
                          title: Text('关于',
                              style: TextStyle(
                                  color: primaryColor,
                                  fontSize: textTheme.titleMedium!.fontSize)),
                        ),
                        ListTile(
                          visualDensity:
                              VisualDensity(horizontal: -4.0), // 减少水平间距
                          leading: Icon(Icons.upgrade, color: primaryColor),
                          title: Text('检查更新', style: textTheme.titleSmall),
                          horizontalTitleGap: 8,

                          trailing: CupertinoListTileChevron(),
                          onTap: () async {
                            String appId = '6636551585';
                            final String appStoreUrl =
                                'https://apps.apple.com/app/id$appId';
                            final Uri url = Uri.parse(appStoreUrl);
                            if (!await launchUrl(url)) {
                              throw Exception('Could not launch $url');
                            }
                            return;
                          },
                        ),

                        ListTile(
                          visualDensity:
                              VisualDensity(horizontal: -4.0), // 减少水平间距
                          leading:
                              Icon(Icons.lock_outline, color: primaryColor),
                          title: Text('隐私条款', style: textTheme.titleSmall),
                          horizontalTitleGap: 8,

                          trailing: CupertinoListTileChevron(),
                          onTap: () {
                            _handleLaunchUrl(context, Uri.parse(pravicyLink));
                          },
                        ),
                        ListTile(
                          visualDensity:
                              VisualDensity(horizontal: -4.0), // 减少水平间距
                          leading:
                              Icon(Icons.info_outline, color: primaryColor),
                          title: Text('关于我们', style: textTheme.titleSmall),
                          horizontalTitleGap: 8,

                          trailing: CupertinoListTileChevron(),
                          onTap: () {
                            _handleLaunchUrl(
                                context, Uri.parse("https://www.fancyzh.top/"));
                          },
                        ),
                        // 备案号
                        ListTile(
                          visualDensity:
                              VisualDensity(horizontal: -4.0), // 减少水平间距

                          leading: Icon(Icons.my_library_books_outlined,
                              color: primaryColor),
                          title: Text('备案号', style: textTheme.titleSmall),
                          horizontalTitleGap: 8,

                          trailing:
                              Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(icpNumber,
                                style: textTheme.titleSmall!.copyWith(
                                    fontSize: 13, color: Colors.grey)),
                          ]),
                          onTap: () {
                            // context.push('/data_backup');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    height: 210,
                  ),
                )
              ],
            ),
          )
        : CupertinoPageScaffold(
            backgroundColor: CupertinoColors.systemGroupedBackground,
            child: CustomScrollView(slivers: [
              CupertinoSliverNavigationBar(
                border: null,
                alwaysShowMiddle: false, //滚动空间不够设置为true才能同时显示
                middle: Text(
                  "设置",
                  style: TextStyle(color: primaryColor),
                ),
                largeTitle: Text(
                  '设置',
                  style: TextStyle(
                    color: primaryColor,
                  ),
                ), // 修改为适合的标题
                stretch: true,
                // 添加背景图
                backgroundColor: CupertinoColors.systemGroupedBackground,
                // trailing: Container(), // 如果不需要右侧按钮，保留空间
              ),
              SliverFillRemaining(
                child: SingleChildScrollView(
                  child: Column(children: [FormWidgetOne, FormWidgetTwo]),
                ),
              )
            ]));
  }

  _handleLaunchUrl(BuildContext context, Uri url) async {
    await _launchUrl(url);
  }

  _handleRestorePurchase(BuildContext context) async {
    print("恢复内购");
    await restorePurchases(context);
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  handleRating(BuildContext context) async {
    print("准备评价");
    // String appId = '6630387527';//todo
    String appId = '6636551585';
    // final String appStoreUrl = 'https://apps.apple.com/app/id${appId}';//查看app
    String appStoreUrl =
        'itms-apps://itunes.apple.com/app/id$appId?action=write-review'; //评价app
    final Uri url = Uri.parse(appStoreUrl);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  ///从后端校验兑换码是否正确
  void _verifyRedeemCode(String code) async {
    if (code.isEmpty) {
      EasyLoading.showError('请输入兑换码');
      return;
    }

    // 根据这个mock的code换来真的code，然后跳转App Store
    Map<String, dynamic> data = {
      'originCode': code,
    };
    try {
      final response =
          await DioClient().post(API.getExchangeCode, data, (data) => data);
      if (response.errno == 0) {
        debugPrint('response data is ${response.data}');
        String realCode = response.data;
        if (realCode.isNotEmpty) {
          _goToAppStoreRedeemPage(realCode);
        } else {
          EasyLoading.showError('兑换码错误或已失效');
        }
      } else {
        debugPrint('adasds ${response.message}');
        EasyLoading.showError(response.message);
      }
    } finally {
      // TODO
      _codeController.clear();
    }
  }

  void _goToAppStoreRedeemPage(String promotionCode) async {
    dynamic url =
        'https://apps.apple.com/redeem?code=$promotionCode'; // Promo Code 页面
    url = Uri.parse(url);
    try {
      if (await canLaunchUrl(url)) {
        _handleCodeSuccess(promotionCode);
        print("兑换码成功");
        await launchUrl(url);
        // 记录当前使用的code
        // final prefs = await SharedPreferences.getInstance();
        // prefs.setString('currentCode', promotionCode);
        // debugPrint('prefs.getString  is ${prefs.getString('currentCode')}');
      } else {
        throw 'Could not launch $url';
      }
    } on Exception catch (e) {
      // TODO
    }
  }

  ///处理兑换码
  void _handleCodeBenifit() async {
    Navigator.of(context).pop();
    return showDialog<void>(
        context: context,
        barrierDismissible: false, // 点击对话框外部不会关闭它
        builder: (BuildContext context) {
          return AlertDialog.adaptive(
            title: Text('输入兑换码'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('请输入您的兑换码以激活会员资格。'),
                  SizedBox(height: 10),
                  CupertinoTextField(
                    controller: _codeController,
                    placeholder: '兑换码',
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.inactiveGray),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('取消'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('兑换'),
                onPressed: () {
                  Navigator.of(context).pop();
                  final code = _codeController.text;
                  _verifyRedeemCode(code);
                },
              ),
            ],
          );
        });
  }

  // 核销兑换码
  void _handleCodeSuccess(String promotionCode) async {
    // 根据这个mock的code换来真的code，然后跳转App Store
    final prefs = await SharedPreferences.getInstance();
    final userIdentifier = prefs.getString('userIdentifier') ?? '';
    if (userIdentifier.isEmpty) {
      EasyLoading.showError('请先登录');
      return;
    }
    Map<String, dynamic> data = {
      'originCode': promotionCode,
      "userId": userIdentifier
    };
    try {
      final response =
          await DioClient().post(API.redeemCode, data, (data) => data);
      if (response.errno == 0) {
        debugPrint('response data is ${response.data}');
        EasyLoading.showError(response.message);
      } else {
        throw Exception('Failed to verify code');
      }
    } finally {
      // TODO
      _codeController.clear();
    }
  }

  // void _handleIAP(BuildContext context) {}
  // 处理购买
  Future<void> _handleIAP(BuildContext context) async {
    payConfigure().then((value) => {
          handlePayGlobal(),
        });
  }
}

class _SecondPage extends StatelessWidget {
  const _SecondPage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
        child: Text(text),
      ),
    );
  }
}
