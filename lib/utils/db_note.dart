import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:com.cherish.mingji/model/data.dart';
import 'package:com.cherish.mingji/model/label_info.dart';
import 'package:com.cherish.mingji/pages/export/tools/common.dart';
import 'package:com.cherish.mingji/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sqflite/sqflite.dart';
import 'package:sqflite_sqlcipher/sqflite.dart'; // 使用加密的 sqflite_sqlcipher
import 'package:path/path.dart';

class SQLHelper {
  static final SQLHelper _instance = SQLHelper._internal();
  final _secureStorage = FlutterSecureStorage();
  static const String dbName = 'time_line.db';
  static String tableDoodles = 'doodles';
  static String tableLabel = 'labels';

  Database? _database;

  factory SQLHelper() {
    return _instance;
  }

  SQLHelper._internal();

  Future<Database> get database async {
    debugPrint("_database: $_database");
    if (_database != null) return _database!;
    _database = await _initDB(dbName);
    return _database!;
  }

// 获取dbname
  String get databaseName => dbName;
// 初始化数据库内容
  Future<Database> _initDB(String dbName) async {
    String path = join(await getDatabasesPath(), dbName);
    debugPrint('response data is $path');
    // 从 secure storage 中获取加密密钥
    // 从 secure storage 中获取加密密钥
    String? encryptionKey = await _secureStorage.read(key: 'db_encryption_key');
    encryptionKey ??= await getOrCreateEncryptionKey();
    try {
      return await openDatabase(
        path,
        password: encryptionKey, // 通过加密密钥打开数据库
        version: 12,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } on Exception catch (e) {
      log("打开数据库失败${e.toString()}");
      // 删除数据库
      await deleteDatabase(path);
      throw Exception("${e}Make sure the database is created and stored.");
    }
  }

// 数据库表创建逻辑
  Future<void> _onCreate(Database db, int version) async {
    await _createDoodleTable(db);
    await _createLabelTable(db);
    await _createCommentsTable(db);
  }

// 更新表结构
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (newVersion > oldVersion) {
      try {
        // await updateDoodleTableWeather(db);
        // 新增置顶字段
        await db
            .execute("ALTER TABLE doodles ADD COLUMN isTop INTEGER DEFAULT 0");
        return;
        await _createCommentsTable(db); // 新增评论表
        await db.execute(
            "ALTER TABLE doodles ADD COLUMN video TEXT DEFAULT ''"); // 新增video字段
        await db.execute(
            "ALTER TABLE doodles ADD COLUMN audio TEXT DEFAULT ''"); // 新增audio字段
        debugPrint("执行完成");
      } on Exception catch (e) {
        // TODO
        debugPrint(e.toString());
      }
    }
  }

// 创建doodle表
  Future<void> _createDoodleTable(Database database) async {
    await database.execute("""CREATE TABLE doodles(
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    name TEXT,
    time TEXT,
    content TEXT DEFAULT '',
    doodle TEXT DEFAULT '', 
    video Text DEFAULT '',  
    audio Text DEFAULT '',  
    label TEXT DEFAULT '1',
    weather TEXT DEFAULT '',
    location TEXT DEFAULT '',
    isTop INTEGER DEFAULT 0,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
    """);
  }

// label、weather、location等
// 更新表doodles结构
  Future<void> updateDoodleTableWeather(Database database) async {
    // 添加新的列 label, weather, location
    await database
        .execute('ALTER TABLE doodles ADD COLUMN label TEXT DEFAULT \'1\'');
    await database
        .execute('ALTER TABLE doodles ADD COLUMN weather TEXT DEFAULT \'\'');
    await database
        .execute('ALTER TABLE doodles ADD COLUMN location TEXT DEFAULT \'\'');

    // 你可以根据需求，选择是否更新现有数据。
    // 如果你需要为已有数据设置这些列的默认值，下面这行可以用来更新所有的旧数据。
    await database.execute(
        'UPDATE doodles SET label = \'1\', weather = \'\', location = \'\'');
  }

// 创建标签表
  Future<void> _createLabelTable(Database database) async {
    await database.execute("""CREATE TABLE $tableLabel(
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      title TEXT NOT NULL,
      subtitle TEXT,
      bgColor TEXT NOT NULL,
      isUserAdd INTEGER NOT NULL DEFAULT 0,
      createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
     )
     """);
    //  插入默认标签值
    final count = await database.rawQuery('SELECT COUNT(*) FROM labels');
    final isEmpty = count.first['COUNT(*)'] == 0;
    log("isEmpty$isEmpty");
    if (isEmpty) {
      await database
          .execute("""INSERT INTO labels (title, subtitle, bgColor, isUserAdd)
        VALUES
          ('默认分类', '默认分类', '#CC5500', 0),
          ('Todo', '待办事项', '#B22222', 0),
          ('Goal', '目标类别', '#FFBF00', 0)
        """);
    }
  }

  // 创建评论表
  Future<void> _createCommentsTable(Database database) async {
    await database.execute("""
      CREATE TABLE comments (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        doodle_id INTEGER NOT NULL,
        commenter TEXT,
        comment TEXT,
        time TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (doodle_id) REFERENCES doodles(id) ON DELETE CASCADE
      )
    """);
  }

// 查询某个 doodle 的所有评论
  Future<List<Comment>> getCommentsForDoodle(int doodleId) async {
    final db = await database;
    // 使用 INNER JOIN 进行联表查询
    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT c.id, c.doodle_id, c.commenter, c.comment, c.time, c.createdAt, c.updatedAt 
    FROM comments c
    INNER JOIN doodles d ON c.doodle_id = d.id
    WHERE d.id = ?
  ''', [doodleId]);

    // 将查询结果转换为 Comment 对象列表
    return result.map((map) => Comment.fromMap(map)).toList();
  }

  /// 插入评论到 comments 表
  Future<int> insertComment(Comment comment) async {
    final db = await database;
    // 将 Comment 对象转换为 Map 数据
    final data = comment.toMap();
    // 插入数据到 comments 表
    final id = await db.insert(
      'comments', // 表名
      data,
      conflictAlgorithm: ConflictAlgorithm.replace, // 冲突时替换
    );

    return id;
  }

  // 打开数据库
  Future<void> open() async {
    if (_database == null || !_database!.isOpen) {
      _database = await _initDB('doodles.db');
      debugPrint('Database opened.');
    } else {
      debugPrint('Database is already open.');
    }
  }

  // 关闭数据库
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
      debugPrint('Database closed.');
    } else {
      debugPrint('Database is already closed or not initialized.');
    }
  }

  ///插入日记具体的sql操作
  Future<int> createDoodle(Doodle doodle) async {
    final db = await database;
    final data = doodle.toMap();
    data['createdAt'] = DateTime.now().toString();
    log("插入内容${data.toString()}");
    if (doodle.label!.isEmpty) {
      data['label'] = '1'; //默认给个标签1
    }
    final id = await db.insert('doodles', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

// 重新初始化数据库
  Future<void> dataBackup2Reset() async {
    await database;
  }

  Future<int> updateDoodle(Doodle doodle) async {
    final db = await database;
    final data = doodle.toMap();
    final id = await db.update(
      'doodles',
      data,
      where: 'id = ?',
      whereArgs: [doodle.id],
    );
    return id;
  }

  ///拿到指定id的所有静态资源（图片、视频、音频）
  Future<int> _deleteImageInFile(int id) async {
    final db = await database;
    final data = await db.query('doodles', where: 'id = ?', whereArgs: [id]);
    log("拿到数据${data.toString()}");
    final filePaths = data.first['doodle'] as String;
    final videoPaths = data.first['video'] as String;
    final audioPaths = data.first['audio'] as String;

    final paths = [
      ...filePaths.split(','),
      ...videoPaths.split(','),
      ...audioPaths.split(',')
    ]; //多个静态资源路径拼接
    // [/1730131258136726.jpg, /1730131269056085.jpg, /1730131262343811.jpg, /video_1730131281615.mp4, /recording_1730131246889.m4a]
    log("要删除的静态资源路径===${paths.toString()}");
    var rowsDeleted = 0;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final noteImagesPath = Directory('${directory.path}/noteImages');
      await Future.forEach(paths, (p) async {
        final finalPath = join(noteImagesPath.path, p);
        await deleteAssetsByPath(finalPath);
      });
      // 执行删除数据库内容
      final db = await database;
      rowsDeleted = await db.delete(
        'doodles',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting image: $e');
    } finally {
      return rowsDeleted;
    }
  }

  ///删除指定路径中的资源
  Future<void> deleteAssetsByPath(String filePath) async {
    try {
      final file = File(filePath);
      await file.delete();
    } catch (e) {
      debugPrint('Error deleting assets: $e');
    }
  }

  /// 删除方法
  Future<bool> deleteDoodle(int id) async {
    var rowsDeleted = 0;
    try {
      rowsDeleted = await _deleteImageInFile(id);
      log("删除对象$rowsDeleted");
      return true;
    } on Exception catch (e) {
      // TODO
      return false;
    } finally {
      // await database;
      log("删除成功$id,结果：$rowsDeleted");
    }
  }

// 得到md固定格式content内容
  Future<String> _getEditInfo(Doodle info, String prefixPath) async {
    final info2 = jsonDecode(info.content);
    List<dynamic> newJsonData = reverseProcessJsonData(info2, prefixPath);
    // debugPrint("newJsonData: $newJsonData");
    return jsonEncode(newJsonData);
  }

  /// sql获取内容 拼接路径
  // TODO 考虑全局处理内容
  Future<List<Doodle>> getDoodles() async {
    final db = await database;
    final maps =
        await db.rawQuery('SELECT * FROM doodles ORDER BY  isTop DESC,id DESC');
    final res = maps.map((map) => Doodle.fromMap(map)).toList();
    final prefs = await SharedPreferences.getInstance();
    final String noteImagesPath = (prefs.getString('noteImagesPath')!);
    // log("noteImagesPath$noteImagesPath");
    // 在sql拿到的时候已经处理过路径拼接了
    for (var note in res) {
      if (note.doodle.isNotEmpty) {
        note.doodle =
            note.doodle.split(',').map((n) => noteImagesPath + n).join(',');
        note.audio =
            note.audio?.split(',').map((n) => noteImagesPath + n).join(',');
        note.video =
            note.video?.split(',').map((n) => noteImagesPath + n).join(',');
      }
      // 这个地方时拼接完整的照片和视频内容到doodle和video
      if (note.content.isNotEmpty) {
        note.content = await _getEditInfo(note, noteImagesPath);
      }
    }

    // log("数据库获取数据完成${res[0].doodle}");
    log(res.toString());
    return res;
  }

  /// 备份专用（不需要拼接路径）
  Future<List<Doodle>> getDoodlesByBackup() async {
    final db = await database;
    final maps = await db.rawQuery('SELECT * FROM doodles ORDER BY id DESC');
    final res = maps.map((map) => Doodle.fromMap(map)).toList();
    // log("数据库获取数据完成${res[0].doodle}");
    log(res.toString());
    return res;
  }

// 根据id设置置顶属性为1
  Future<int> setTopDoodleItem(int id) async {
    final db = await database;
    final res = await db.rawUpdate(
        'UPDATE doodles SET isTop = CASE WHEN isTop = 1 THEN 0 ELSE 1 END WHERE id = ?',
        [id]);
    log(res.toString());
    return res;
  }

// 统计频率
  Future<List<Map<String, dynamic>>> countItemsByDay(int? days) async {
    final db = await database;
    String query;

    if (days != null) {
      query = '''
      SELECT 
        DATE(createdAt) AS date,
        COUNT(*) AS count
      FROM 
        doodles
      WHERE 
        createdAt >= DATE(CURRENT_DATE, '-$days day')
      GROUP BY 
        DATE(createdAt)
      ORDER BY 
        DATE(createdAt) ASC
    ''';
    } else {
      query = '''
      SELECT 
        DATE(createdAt) AS date,
        COUNT(*) AS count
      FROM 
        doodles
      GROUP BY 
        DATE(createdAt)
      ORDER BY 
        DATE(createdAt) ASC
    ''';
    }

    final results = await db.rawQuery(query);
    // log("results: $results");

    return results.map((row) {
      return {
        'key': DateFormat('yy/MM/dd').format(DateTime.parse("${row['date']}")),
        'value': row['count'],
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> countItemsByDay2(int? days) async {
    final db = await database;
    String query;

    if (days != null) {
      query = '''
    SELECT 
      createdAt AS date,
      COUNT(*) AS count
    FROM 
      doodles
    WHERE 
      createdAt >= DATE(CURRENT_DATE, '-$days day')
    GROUP BY 
      createdAt
    ORDER BY 
      createdAt ASC
    ''';
    } else {
      query = '''
    SELECT 
      createdAt AS date,
      COUNT(*) AS count
    FROM 
      doodles
    GROUP BY 
      createdAt
    ORDER BY 
      createdAt ASC
    ''';
    }

    final results = await db.rawQuery(query);
    log("results: $results");
    final list = results.map((row) {
      return {
        'date': DateFormat('yy-MM-dd:HH:mm')
            .format(DateTime.parse("${row['date']}")),
        'count': row['count'],
      };
    }).toList();
    log("loist$list");
    return list;
  }

  /// 获取表中所有doodle的内容得到后每个item是字符串，然后拼接他们 使用，分割成数组
  Future<List<String>> getAllImageList() async {
    final db = await database;
    final maps = await db.rawQuery('SELECT * FROM doodles ORDER BY id DESC');
    final res = maps.map((map) => Doodle.fromMap(map)).toList();
    final prefs = await SharedPreferences.getInstance();
    final String noteImagesPath = (prefs.getString('noteImagesPath')!);
    // log("noteImagesPath$noteImagesPath");
    // 在sql拿到的时候已经处理过路径拼接了
    List<String> doodleList = [];
    for (var note in res) {
      if (note.doodle.isNotEmpty) {
        doodleList
            .addAll(note.doodle.split(',').map((n) => noteImagesPath + n));
      }
    }
    return doodleList;
  }

// label分类标签相关
// 假设你有一个 SQLite 数据库，表名为 'label_items'
  Future<List<LabelItem>> getLabelListItems() async {
    final db = await database;
    final List<Map<String, dynamic>> data =
        await db.rawQuery('SELECT * FROM labels');
    // 将读取到的数据转换为 LabelListItems
    final List<LabelItem> labelListItems = data.map((item) {
      return LabelItem(
        id: item['id'],
        title: item['title'],
        subtitle: item['subtitle'],
        bgColor: HexColor(item['bgColor']),
        isUserAdd: item['isUserAdd'],
      );
    }).toList();

    return labelListItems;
  }

// 默认label的id从1-3 不允许修改
  final defaultLabelListID = [1, 2, 3];

  /// 根据id删除label
  Future<int> deleteLabelItem(int id) async {
    if (defaultLabelListID.contains(id)) {
      return 0;
    }
    final db = await database;
    return await db.delete('labels', where: 'id = ?', whereArgs: [id]);
  }

  /// 根据id修改label
  Future<int> updateLabelItem(LabelItem item) async {
    if (defaultLabelListID.contains(item.id)) {
      return 0;
    }
    final db = await database;
    return await db.update(
      'labels',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// 创建label
  Future<int> createLabelItem(
      String title, String subtitle, String bgColor, bool isUserAdd) async {
    final db = await database;
    return await db.insert(
      'labels',
      {
        'title': title,
        'subtitle': subtitle,
        'bgColor': bgColor,
        'isUserAdd': isUserAdd ? 1 : 0,
      },
    );
  }

  // 获取当前note的label信息
  Future<List<LabelItem>> getLabelListItemsByIds(List<int> labelIds) async {
    // 将 id 列表转换为字符串，用于 SQL IN 查询
    final String idList = labelIds.join(',');

    // 获取数据库实例
    final db = await database;

    // 使用 SQL 的 IN 子句查找多个 id 对应的标签
    final List<Map<String, dynamic>> data = await db.rawQuery(
      'SELECT * FROM labels WHERE id IN ($idList)',
    );

    // 将读取到的数据转换为 LabelItem 对象列表
    final List<LabelItem> labelListItems = data.map((item) {
      return LabelItem(
        id: item['id'],
        title: item['title'],
        subtitle: item['subtitle'],
        bgColor: HexColor(item['bgColor']),
        isUserAdd: item['isUserAdd'],
      );
    }).toList();

    return labelListItems;
  }

  ///获取每日记录数 统计每天的数量，用于计数，createdAt作为key
  Future<Map<DateTime, int>> getHeatMapDatasets() async {
    final db = await database;
    final List<Map<String, dynamic>> data = await db.rawQuery(
        'SELECT createdAt, COUNT(*) as count FROM doodles GROUP BY createdAt');

// mock data为空
    if (data.isEmpty) {
      return {};
    }
    final Map<DateTime, int> heatMapDatasets = {};
    for (var item in data) {
      // 解析 'createdAt' 为 DateTime
      final DateTime date = DateTime.parse(item['createdAt']);

      // 创建一个新的 DateTime，只保留年、月、日，忽略时间部分
      final DateTime dayOnly = DateTime(date.year, date.month, date.day);

      // 如果 heatMapDatasets 已经包含该日期，则累加 count，否则创建新的 entry
      if (heatMapDatasets.containsKey(dayOnly)) {
        heatMapDatasets[dayOnly] =
            (heatMapDatasets[dayOnly]! + item['count']).toInt();
      } else {
        heatMapDatasets[dayOnly] = item['count'];
      }
    }

    debugPrint("heatMapDatasets ${heatMapDatasets.toString()}");
    return heatMapDatasets;
  }
}
