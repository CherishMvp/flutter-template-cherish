import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';

class QuoteContent {
  dynamic id;
  String content;
  String? type;
  String? fromSource;
  String? creator;
  String? from_who;
  int? is_collect; //2为收藏状态

  QuoteContent(
      {required this.id,
      required this.content,
      this.type,
      this.fromSource,
      this.creator,
      this.from_who,
      this.is_collect = 1});
}

// 名言数据结构
class Quote {
  final dynamic id;
  final dynamic categoryId;
  final List<QuoteContent> content;

  Quote({required this.id, required this.categoryId, required this.content});
}

/// quote数据库连接助手
class DatabaseQuoteHelper {
  static Database? _database;
  String tableName = "quote_collect"; //收藏表名称
  String defaultTableName = 'a'; //默认quote读取的分类表
  String localQuoteName = "one_quote_new"; //本地数据库文件名
  String customFileName = 'one_quote_new.db'; // Custom database file name

  Future<Database> get database async {
    if (_database != null) {
      // return _database!;
      return await openQuoteDatabase();
    } // 延迟 2 秒，等待数据库文件复制完成
    _database = await _initDatabase();
    return _database!;
  }

// 初始化数据库实例
  Future<bool> setUpDatabase() async {
    final customFilePath = await getCustomFilePath();
    bool exists = await databaseExists(customFilePath);
    if (exists) {
      _database = await openQuoteDatabase();
      return true;
    }
    try {
      print('Copying database file from assets...');
      ByteData data = await rootBundle.load("assets/sqlite/one_quote_new.db");
      List<int> bytes = data.buffer.asUint8List();
      await File(customFilePath).writeAsBytes(bytes);
      print('Database file copied successfully');
      _database = await openDatabase(customFilePath, version: 1);
      return true;
    } on Exception catch (e) {
      // TODO
      return false;
    }
  }

  // Write a method to return the custom file path with the given custom file name
  Future<String> getCustomFilePath() async {
    String customFilePath = join((await getDatabasesPath()),
        customFileName); // Build custom database file path
    if (kDebugMode) {
      print("final path$customFilePath");
    }
    // Open the database from the documents directory
    return customFilePath;
  }

  Future<Database> _initDatabase() async {
    // Check if the database file already exists in the documents directory
    final customFilePath = await getCustomFilePath();
    bool exists = await databaseExists(customFilePath);
    if (exists) {
      return await openQuoteDatabase();
      // await File(customFilePath).delete(); // 如果需要删除旧的内容，可以取消注释此行
    }
    // If the database file doesn't exist, copy it from assets to the documents directory
    else {
      print('Copying database file from assets...');
      ByteData data = await rootBundle.load("assets/sqlite/one_quote_new.db");
      List<int> bytes = data.buffer.asUint8List();
      await File(customFilePath).writeAsBytes(bytes);
      print('Database file copied successfully');
      return await openDatabase(customFilePath, version: 1);
    }
  }

  /// 在线更新数据库文件
  Future<void> updateDatabaseFile() async {
    Dio dio = Dio();
    String url = 'https://example.com/updated_database.db'; // 替换为实际的数据库文件下载链接
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, localQuoteName);

    // 如果文件存在，则删除旧文件
    if (await File(path).exists()) {
      await File(path).delete();
    }

    try {
      await dio.download(url, path);
      print('Database file updated successfully');
    } catch (e) {
      print('Failed to download database file: $e');
    }
  }

  /// 获取quote的配置信息(同时更新当前主题信息和背景图片)
  Future<Map<dynamic, dynamic>> getCurrentQuoteConfig() async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query('quote_config');
    final data = {};
    if (result.isNotEmpty) {
      print("当前配置的quote信息: ${result[0]}");
      data['current_category'] = result[0]['curent_type'];
      data['pageSize'] = result[0]['pageSize'];
      data['page'] = result[0]['page'];
      data['name'] = result[0]['remark'];
      data['bgPath'] = result[0]['bgPath'];
    }
    db.close();
    print("数据库配置信息:$data");
    return data;
  }

  /// 插入quote配置内容
// 更新当前分类的分页配置
// 更新任意配置的分页设置
  Future<void> updateQuoteConfig(Map<String, dynamic> updateData) async {
    final db = await database;
    // 确保更新数据中包含必需的基本字段或做相应处理
    // 例如，确保有更新时间字段，如果没有则添加
    if (!updateData.containsKey('updated_at')) {
      updateData['updated_at'] =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    }

    // 动态构建更新语句的条件部分 - 假设基于某个特定ID更新，需要从updateData中获取或默认设定
    String whereClause = 'id = ?';
    List<dynamic> whereArgs = [
      updateData.remove('id') ?? 1
    ]; // 如果id不在updateData中，则默认为1

    // 执行更新操作
    await db.update('quote_config', updateData,
        where: whereClause, whereArgs: whereArgs);
    db.close();
  }

// 分页查询名言内容
  Future<List<Map<String, dynamic>>> getQuotes(
      String category, int page, int pageSize) async {
    final db = await database;
    // 计算偏移量
    int offset = (page - 1) * pageSize;
    // 使用 LIMIT 和 OFFSET 进行分页查询

    final rs = await db.query(category,
        where: 'page = ?', whereArgs: [page], limit: pageSize, offset: offset);
    db.close();
    return rs;
  }

  /// 插入内容
  Future<void> insertData(String table, Map<String, dynamic> data) async {
    final db = await database;
    data['created_at'] =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()); // 添加创建时间字段
    await db.insert(table, data);
    db.close();
  }

  ///获取对应表数据(默认是a表)
  Future<List<Map<String, dynamic>>> getData(
      {String table = 'a', int number = 66}) async {
    final db = await database;
    print("模板表$table");

    // 构建查询语句，使用ORDER BY RANDOM()来随机排序
    String query = table == 'quote_collect'
        ? 'SELECT quote_id as id, quote_content AS content, quote_type AS type, creator, from_source, created_at, from_who, is_collect FROM $table ORDER BY RANDOM() LIMIT $number'
        : 'SELECT *, hitokoto as content FROM $table ORDER BY RANDOM() LIMIT $number';

    // 执行查询并返回结果
    final rs = db.rawQuery(query);
    await db.close();
    return rs;
  }

  // 删除内容
  Future<void> deleteData(String quoteType, int id) async {
    const table = "quote_collect";
    final db = await database;
    // 删除指定内容
    await db.delete(
      table,
      where: "quote_type = ? AND quote_id = ?",
      whereArgs: [quoteType, id],
    );
    db.close();
  }

  /// Insert specific c table data into the quote_like table
  Future<bool> insertCToQuoteLike(int id, String table) async {
    final db = await database;
    List<Map<String, dynamic>> cData =
        await db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (cData.isNotEmpty) {
      Map<String, dynamic> cRow = cData.first;
      print(("cRow ${cRow}"));
      Map<String, dynamic> likeData = {
        'quote_id': cRow['id'],
        'quote_content': cRow['hitokoto'],
        'quote_type': cRow['type'],
        'creator': cRow['creator'],
        'from_source': cRow['from_source'],
        'from_who': cRow['from_who'],
        'is_collect': 2,
        'created_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        'updated_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      };
      bool transactionSuccessful = false;
      try {
        await db.transaction((txn) async {
          await txn.insert('quote_collect', likeData);
          if (cRow['type'] != null) {
            // 更新原表中的收藏状态(type is tableName)
            await txn.update(
              cRow['type'],
              {'is_collect': 2},
              where: 'id = ?',
              whereArgs: [cRow['id']],
            );
          }
          transactionSuccessful = true;
        });
      } catch (e) {
        print('Transaction failed: $e');
      }
      db.close();
      return transactionSuccessful;
    } else {
      db.close();
      return false;
    }
  }

  // 更新收藏状态
  Future<bool> updateCollectState(QuoteContent quote) async {
    final db = await database;
    bool transactionSuccessful = false;
    print("点击quote收藏${quote.from_who},id:${quote.id},type:${quote.type}");
    if (quote.is_collect == 2) {
      // 此时传进来的是修改之前的状态，isCollect为1为未收藏，现在改成收藏状态
      try {
        await db.transaction((txn) async {
          if (quote.type != null) {
            deleteData(quote.type!, quote.id!); //删除收藏内容
            await txn.update(
              quote.type!,
              {
                'is_collect': 1,
                'updated_at':
                    DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())
              },
              where: 'id = ?',
              whereArgs: [quote.id],
            ); // 更新原表中的收藏状态
          }
        });
        transactionSuccessful = true;
      } catch (e) {
        print('Transaction failed: $e');
      }
    } else {
      // 此时传进来的是修改之前的状态，isCollect为1为未收藏，现在改成收藏状态
      Map<String, dynamic> likeData = {
        'quote_id': quote.id,
        'quote_content': quote.content,
        'quote_type': quote.type,
        'creator': quote.creator,
        'from_source': quote.fromSource,
        'from_who': quote.from_who,
        'is_collect': 2,
        'created_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        'updated_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      };
      try {
        await db.transaction((txn) async {
          await txn.insert(tableName, likeData);
          if (quote.type != null) {
            // 更新原表中的收藏状态
            await txn.update(
              quote.type!,
              {'is_collect': 2},
              // 手动构造 WHERE 子句，而不是使用 where 参数
              where: 'id = ? AND type = ?',
              // 更新参数列表，确保它们按正确的顺序
              whereArgs: [quote.id, quote.type],
            );
          }
          transactionSuccessful = true;
        });
      } catch (e) {
        print('Transaction failed: $e');
      }
    }
    db.close();
    return transactionSuccessful;
  }

  /// 传来的是整个quote内容(减少数据库查询)
  Future<bool> insertCToQuoteLikeByContent(QuoteContent quote) async {
    if (quote.id != null) {
      bool updateState = await updateCollectState(quote);
      return updateState;
    }
    return false;
  }

  /// Retrieve the collection list based on quote_id and quote_type, including data from the c table
  Future<List<Map<String, dynamic>>> getCollectionList(
      String quoteType, int quoteId) async {
    final db = await database;
    db.close();
    return db.rawQuery('SELECT * FROM quote_like');

    ///全部返回
    // return db.rawQuery(
    //   'SELECT * FROM quote_like'
    //   'JOIN c ON l.quote_id = c.id '
    //   'WHERE l.quote_type = ? AND l.quote_id = ?',
    //   [quoteType, quoteId],
    // );///分类查询
  }

  Future<Database> openQuoteDatabase() async {
    final dbPath = await getCustomFilePath();
    return await openDatabase(dbPath, version: 1);
  }
}
