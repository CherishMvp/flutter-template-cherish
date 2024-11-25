<!-- @format -->

# 2024 年 6 月 27 日

- 分页面开发，前期不要考虑过于精简的组件拆分。基本功能先完善

# 2024 年 6 月 29 日

- 打包压缩同步功能
  import 'dart:io';
  import 'package:archive/archive.dart';
  import 'package:path_provider/path_provider.dart';

// ...

Future<File?> pickImage(ImageSource imageType) async {
File? tempImage;
try {
// Get the library directory
final directory = await getApplicationDocumentsDirectory();

    // Use the image picker to get the image
    final photo = await ImagePicker().pickImage(source: imageType, imageQuality: 100);
    if (photo == null) return null;

    // Create a new file with a unique name in the library directory
    final newFile = File('${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');

    // Copy the image to the new file
    await newFile.writeAsBytes(await photo.readAsBytes());

    // Crop the image
    tempImage = await _cropImage(imageFile: newFile);

    // Create a ZIP file
    final zipFile = File('${directory.path}/images.zip');
    final zip = ZipFileEncoder();
    zip.create(zipFile.path);

    // Add the selected image and the cropped image to the ZIP file
    zip.addFile(File(newFile.path), archiveName: 'selected_image.jpg');
    zip.addFile(File(tempImage!.path), archiveName: 'cropped_image.jpg');

    // Close the ZIP file
    await zip.close();

    setState(() {
      pickedImage = tempImage;
    });

} catch (error) {
log_dev.log("图片选择失败: ${error.toString()}");
}
return tempImage;
}

# ios13 风格的 modal bottom sheet 的用法，需要注意，跟传入的 key 有关系

- 相关内容：https://github.com/jamesblasco/modal_bottom_sheet/issues/363
- 标准的 modal sheet 标题大小： style: Theme.of(context).textTheme.titleMedium!.copyWith(
  fontWeight: FontWeight.bold,
  )

# 2024 年 07 月 01 日 00:40:13

- 点击内容 先查看详情 再去修改界面

# 2024 年 7 月 6 日 18:49:22

- 考虑记录当天的天气情况？使用动态天气背景

# 2024 年 07 月 15 日 19:33:02

`CupertinoScaffold.showCupertinoModalBottomSheet( context: cupertinoScaffoldContext, builder: (_) => NoteDetailEdit(noteId: doodle.id.toString()), )`;触发 ios 风格的 modal 同时需要注意当前页面的 cupertinoScaffoldContext
在外层包裹一层 `return CupertinoScaffold(body: Builder(builder: (cupertinoScaffoldContext) { return`即可

# 升级最新版 flutter

[./docotor.png]

# web 项目出问题

重新创建：flutter create --org com.cherish.mingji --platforms ios .

# ios 项目出问题

- 保留 info 配置信息和 podfile 内容
- 删除整合 ios 目录，执行
  重新创建：flutter create --org com.cherish.mingji --platforms ios .
  重新创建项目

# 一个组件中调用子组件 传入变量出现：

The instance member 'imageUrls1' can't be accessed in an initializer.
Try replacing the reference to the instance member with a different expressiond

- 可以使用 使用 static 关键字可以解决这个问题的原因是：在 Dart 中，static 成员是属于类本身的，而不是属于类的实例的。

  当你声明一个 static 成员时，它是在类加载时就被初始化的，而不是在实例创建时。这意味着 static 成员可以在任何地方被访问，而不需要创建类的实例。

  在你的例子中，imageUrls1 是一个实例成员，它是在类的实例创建时被初始化的。但是，你试图在另一个实例成员的初始化器中访问它，这是不允许的，因为实例成员的初始化顺序是未定义的。

  但是，如果你将 imageUrls1 声明为 static 成员，那么它就会在类加载时被初始化，而不是在实例创建时。这意味着你可以在任何地方访问它，包括在另一个实例成员的初始化器中。

  因此，使用 static 关键字可以解决这个问题，因为它允许你在类的实例创建之前就初始化成员，并且可以在任何地方访问这些成员。

  # 页面栈

  - 首页：
    - index_content
    - note_add 页面
    - note_detail 页面（不进行操作）
    - note_edit 页面（crud 操作）

  # 使用 image_picker

  - 在这个插件的基础上 再新增一个拍照选中图片
  - 使用链接：`https://blog.csdn.net/qq_42362997/article/details/112283982`
  - 官网：`https://pub.dev/packages/image_picker`

  # 平台特定组件

  - 即不用每次都判断是 ios 还是 android
  - 如 switch，可以使用
    - Switch.adaptive()书写

  # 使用 provider 的页面同时使用'package:path/path.dart' 会在 initState 中出现 context 找不到的情况。

  - 可以使用`import 'package:path/path.dart' as file_path;  `解决 file_path.join()xxx
  - 或者使用 this.context
  - 参考`https://stackoverflow.com/questions/53406548/error-dart-the-argument-type-context-cant-be-assigned-to-the-parameter-typ`

  # 考虑使用 easy_date_timeline: ^1.1.3 执行做日历内容的展示

  # 考虑使用 markdown 代替现有的分步表单书写

  # 2024 年 09 月 02 日 23:52:53

  - 妈了逼的折腾一晚上傻逼 ios 应用配置

  # 2024 年 9 月 5 日 10:22:08

  - android/app/build.gradle ：这个文件是应用模块的配置文件，主要设置应用的构建参数、依赖和编译选项。
  - android/build.gradle：这个文件是项目的根级别 Gradle 配置文件，用于设置全局的构建脚本配置，包括插件和存储库。
  - sound audio 插件推荐：assets_audio_player: ^3.1.1 、audioplayers
  - 记录日期展示(和热热力图类似)考虑使用 scrollable_clean_calendar: ^1.5.0 这个插件
  - 1日期展示选择：easy_date_timeline: ^1.1.3
  - 事件展示 event：table_calendar: ^3.1.2
  - 日期轮播使用 calendar_timeline: ^1.1.3(pass)、可下拉的：flutter_advanced_calendar: ^1.4.1(pass)，花里胡哨版：clean_calendar: ^1.1.0
    - 终极合适：flutter_neat_and_clean_calendar: ^0.4.14（日期下方有配套列表展示，**但是更适合于待办事项的时间提醒**）
  - 日期热力图使用 flutter_heatmap_calendar: ^1.0.5（展示记录的频次等，或者当天是否有记录）
  - 时间回溯：mobkit_calendar: ^1.0.1
  - 1事件日历：flutter_event_calendar: ^1.0.0
  - 预定时间日期：booking_calendar: ^1.1.10
  - appbar 日期 calendar_appbar: ^0.0.6
  - 时间日期选择插入：board_datetime_picker: ^2.1.1
  -

  # 2024 年 9 月 5 日 11:34:35

  - 日期插件 参考：`https://flutter.ducafecat.com/pubs/calendar-packages`

  # 2024 年 9 月 5 日 16:49:39

  - 登录 apple id（需要 Sign in With Apple 能力）：sign_in_with_apple: ^6.1.2

  # 2024 年 09 月 07 日 21:58:16

  - 组件可以使用.adaptive 来自适应平台自己的特殊内容。如 icon: Icon(Icons.adaptive.arrow_back),会根据不同平台使用各自的组件
    - 参考链接：`https://api.flutter.dev/flutter/material/Icons/adaptive.html`

  # 2024 年 09 月 07 日 23:34:02

  - 移动动画：AnimatedPositioned
  - 保存的时候，文字和图片主键关联就行。根据 noteid 关联笔记文字内容和图片。这样方便备份
  - 所有媒体文件都通过 noteid 和静态资源关联（voice、image...）

  # 2024 年 09 月 09 日 23:21:49

  - MainAxisSize.min：Column 只会占用包裹内容的高度，所以整个布局会比较紧凑。
  - MainAxisSize.max：Column 会拉伸到最大高度，即使内容较少，可能会看到较多的空白区域。
  - StatefulWidget 的变量: 用于传递不可变的配置或参数。
  - \_State 的变量: 用于管理 widget 的可变状态，反映 UI 的动态变化。

  # 2024 年 09 月 10 日 00:36:06

  - 开始考虑在 ios 中使用 flex_color_scheme 的主题组合，但是还是希望 ios 和主题切换页面的样式一样

  # 2024 年 9 月 10 日 15:53:56

  - 提示词：`你是一个flutter高手 熟练掌握各种最新技巧和功能实现。`
  - 组件拆分思想

    - 核心思想：
      功能和展示分离：

      将逻辑和界面展示分开，避免在同一个组件中既处理业务逻辑又渲染 UI。
      高复用性：

      如果某个组件的功能可能在多个地方使用，或者具有相似的逻辑，那么将其提取为单独的子组件。
      单一职责：

      每个组件应该只负责一件事情，比如：处理一个按钮、显示一行信息等。
      数据传递和状态管理：

      确保通过父组件向子组件传递数据和回调，使数据流清晰可见。

  # 2024 年 9 月 11 日 17:48:36

  - https://www.youtube.com/watch?v=k2v3gxtMlDE&t=430s（slivers_demo_flutter）
  - https://github.com/bizz84/slivers_demo_flutter
  - material3 的 sourceColor 介绍：`https://codelabs.developers.google.com/codelabs/flutter-boring-to-beautiful?hl=zh-cn#4`
  - material 设计指南详细介绍：`https://docs.flutter.dev/ui/widgets/material
  - cupertino 风格介绍：`https://docs.flutter.dev/ui/widgets/cupertino`

  # 2024 年 9 月 13 日 11:20:28

  - Cupertino 风格
    CupertinoFormSection 和 CupertinoListSection （简单来说一个是表单、应该是列表）
    两者都有 insetGrouped 方法（header 会变大，个人理解就是成为一组）：当它的值为 true 时，列表项会在左侧和右侧添加一定的内边距，以便与其他列表项区分开来。这种样式通常用于展示嵌套的列表数据。
    - CupertinoFormSection 是一个用于展示表单数据的 widget，它通常用于表单页面中。它可以包含一个标题和一组表单项（CupertinoFormRow），每个表单项都包含一个标签和一个输入字段。CupertinoFormSection 可以用于收集用户输入的数据。
    - CupertinoListSection 是一个用于展示列表数据的 widget，它通常用于展示非表单数据的列表。它可以包含一个标题和一组列表项（CupertinoListTile），每个列表项都包含一个标题和一个子标题。CupertinoListSection 可以用于展示数据列表。

  # 2024 年 9 月 14 日 09:39:29

  - adaptive 支持的组件：switch、slider、CircularProgressIndicator、radio、checkbox 和 AlertDialog
  - 日历+event 的选择：
    - color 中的组件：calendar_table_two 或者 calendar_todo
`GoRouter` 的 `go()` 和 `push()` 是两种不同的导航方式，主要区别在于它们如何处理路由堆栈（页面栈）。

# GoRouter 的 go() 和 push() 是两种不同的导航方式
### 区别：
1. **`go()`**
   - **作用**：`go()` 会直接导航到指定路由，**替换**当前页面栈中的内容。
   - **行为**：不保留当前页面，直接跳转到新页面，相当于“重新设置”页面栈。不会推入新的页面到导航栈中。
   - **适用场景**：当你想直接导航到某个页面，不关心用户是否可以返回到之前的页面时，使用 `go()`。比如从首页跳转到登录页。
   - **例子**：
     ```dart
     context.go('/settings');  // 直接导航到 /settings，替换当前页面
     ```

2. **`push()`**
   - **作用**：`push()` 会将新的页面**推入**到路由栈的顶部，保留之前的页面。
   - **行为**：将新页面推入导航栈，用户可以通过返回按钮（`pop`）回到上一个页面。
   - **适用场景**：当你希望用户能够返回上一个页面时使用 `push()`，如从列表页面推入到详情页面。
   - **例子**：
     ```dart
     context.push('/details');  // 推入 details 页面到栈顶，保留当前页面
     ```

### 具体对比：

| 特性                | `go()`                        | `push()`                           |
|---------------------|-------------------------------|------------------------------------|
| **页面栈行为**       | 替换页面栈                     | 将新页面推入页面栈                  |
| **用户返回操作**     | 不能返回到之前的页面           | 可以返回到之前的页面                |
| **适用场景**         | 无需用户返回（如登录页）       | 需要用户返回（如详情页）            |
| **导航语法**         | `context.go('/path')`         | `context.push('/path')`            |

### 实际场景：
- **使用 `go()` 的场景**：
  - 导航到某个新页面，并不希望用户回到之前的页面。例如从欢迎页面直接导航到首页。
  - 在登录或注销的情况下，使用 `go()` 导航到主页或登录页面，避免用户回退到登录或注销之前的页面。

  ```dart
  onPressed: () {
    context.go('/home');  // 导航到 /home，替换当前页面栈
  }
  ```

- **使用 `push()` 的场景**：
  - 从列表页跳转到详情页，用户需要返回列表页。
  - 从主页跳转到某个设置页面，用户可以通过返回按钮返回。

  ```dart
  onPressed: () {
    context.push('/details');  // 推入详情页面，可以返回列表页
  }
  ```

### 总结
- **`go()`**：重置导航栈，直接跳转到新页面，不能返回到之前的页面，适用于用户不需要回退的场景。
- **`push()`**：将新页面推入导航栈，允许用户返回到之前的页面，适用于用户需要返回上一个页面的场景。

# 去除按钮的水波纹效果
```
       splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
```

# 2024年10月14日22:38:23
- live图做法
  - 使用wechat_assets_picker进行操作
  - 添加按钮到功能面板。存储图片。拿到heic内容和mov两个内容。将heic的链接嵌入到编辑器中（和普通的图片嵌入一样）
  - 将heic的图片链接同样插入到原有的图片保存方法中。
  - 预览：暂时使用heic预览。

# 2024年10月17日17:45:40
- 应该多花时间看看别人的优秀的代码
- 多理解业务钻研业务、而不是一味地追求技术
- // 比如autosize text 以及lottie以及shadermask和flutter_staggered_grid_view google_fonts这些之间的插件内容
# 时间
暂时不考虑md格式显示在外层
你是一个flutter高手 熟练使用各种最新的api用法和各种pub.dev中的库进行各种需求开发

# 2024年10月23日17:36:53


那么你可以直接使用 `watch` 来获取 `eventNotes`：

```dart
final notes = context.watch<NoteProvider>().eventNotes;
```

或者使用 `select` 来获取 `eventNotes`：

```dart
final notes = context.select((NoteProvider provider) => provider.eventNotes);
```

这样你就不需要使用 `Consumer` 的 `builder` 函数了。
使用 select 来获取数据，并且数据发生变化后调用了 notifyListeners()，但是 UI 并没有重绘。

这是因为 select 只会在 widget 树构建时获取数据，并不会监听数据的变化。如果数据发生变化后，需要手动通知 widget 树重绘。

在这种情况下，你可以使用 Consumer 或 Selector 来代替 select。这两个 widget 会监听数据的变化，并在数据变化后自动重绘 UI。

# 2024年10月24日00:03:59
毛玻璃效果
  BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 1.0, sigmaY: 1.0), // 设置模糊效果
                                  child: Container(
                                    color: Colors.black
                                        .withOpacity(0.3), // 半透明黑色背景
                                    alignment: Alignment.center,
                                    child: SizedBox.shrink(),
                                  ),
                                ),

# 2024年10月29日23:04:24
- 考虑插入的时候判断embed的大小，现在不是block插入怕会有问题。
- width不足的时候，embed会插入失败
# 会员描述
Here’s the English translation for each feature:

1. **AI生成传记功能** - AI-Generated Biography Feature
2. **不限制视频数量** - Unlimited Video Count
3. **录音功能** - Audio Recording Feature
4. **live图不限量** - Unlimited Live Photos
5. **标签数量不限制** - Unlimited Tags