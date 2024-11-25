import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CherishAppbar extends StatelessWidget implements PreferredSizeWidget {
  // 配置项
  final String title;
  final double iconSize;
  final double fontSize;
  final Widget? leadingIcon;
  // 是否展示leading
  final bool? showLeading;
  final List<Widget>? actions;
  final bool centerTitle;
  final double elevation;

  const CherishAppbar({
    super.key,
    this.title = '',
    this.iconSize = 20.0, // 默认减少的图标大小
    this.fontSize = 20.0, // 默认减少的文字大小
    this.leadingIcon,
    this.showLeading = true,
    this.actions,
    this.centerTitle = true,
    this.elevation = 0.0, // AppBar 阴影高度
  });

  @override
  Widget build(BuildContext context) {
    // 获取主题颜色配置
    final theme = Theme.of(context);
    final appBarColor = theme.appBarTheme.backgroundColor?.withOpacity(0.9) ??
        theme.colorScheme.primary.withOpacity(0.9);
    final titleTextStyle =
        theme.appBarTheme.titleTextStyle ?? theme.textTheme.headlineSmall;
    final iconColor = theme.iconTheme.color ?? theme.colorScheme.onPrimary;

    return AppBar(
      title: Text(
        title,
        style: titleTextStyle?.copyWith(
          fontSize: fontSize,
          color: titleTextStyle.color ?? theme.colorScheme.onPrimary,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: appBarColor,
      elevation: elevation,
      leading: showLeading == false
          ? null
          : leadingIcon ??
              IconButton(
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  size: iconSize,
                  color: iconColor,
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
              ),
      actions: actions?.map((action) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SizedBox(
            width: iconSize + 8,
            height: iconSize + 8,
            child: action,
          ),
        );
      }).toList(),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
