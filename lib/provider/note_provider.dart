import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:com.cherish.mingji/model/data.dart';
import 'package:com.cherish.mingji/utils/db_note.dart';

class NoteProvider with ChangeNotifier {
  final List<Doodle> _notes = [];
  final List<Doodle> _searchTemp = [];
  final List<Doodle> _eventTemp = [];

  List<Doodle> get notes => _notes;
  List<Doodle> get eventNotes => _eventTemp;

  void setNotes(List<Doodle> value) {
    _notes.clear();
    _notes.addAll(value);
    // log("获取数据完成${_notes.length}");
    notifyListeners();
  }

  void setEventTemp(List<Doodle> value) {
    _eventTemp.clear();
    _eventTemp.addAll(value);
    notifyListeners();
  }

  void setNotesTemp(List<Doodle> value) {
    _searchTemp.clear();
    _searchTemp.addAll(value);
    notifyListeners();
  }

  void addNote(Doodle note) {
    _notes.add(note);
    notifyListeners();
  }

  void removeNote(String note) {
    _notes.remove(note);
    notifyListeners();
  }

  ///目前直接通过数据库获取 没在用这个（搜索有用到）
  Future<void> getNotes() async {
    final sql = SQLHelper();
    sql.getDoodles().then((value) {
      log("获取数据${value.length}");
      setNotes(value);
      setNotesTemp(value);
      // notifyListeners();
      // log("获取数据完成${_notes[0].doodle}");
    });
  }

  /// 根据id置顶
  Future<void> setTopNoteState(int id) async {
    final sql = SQLHelper();
    final index = _notes.indexWhere((note) => note.id == id);
    if (index != -1) {
      // 将拿到的index的item，移动到最前面
      final note = _notes.removeAt(index);
      _notes.insert(0, note);
      await sql.setTopDoodleItem(id);
    }
    getNotes();
    notifyListeners();
  }

  // 搜索方法
  void searchNotes(String query) {
    // 先获取全部
    // Timer(const Duration(milliseconds: 300), () => getNotes());
    // 如果query为空，则返回全部
    if (query.isEmpty || query == '') {
      getNotes();
      return;
    }
    final res = _searchTemp
        .where(
            (note) => note.name.contains(query) || note.content.contains(query))
        .toList();
    log("搜索结果$res.toString()");
    setNotes(res);
  }

  void searchNotesByDate(DateTime queryDate) {
    // 获取查询日期当天的 0 点 (00:00:00) 和 23:59:59
    DateTime startOfDay =
        DateTime(queryDate.year, queryDate.month, queryDate.day);
    DateTime endOfDay =
        startOfDay.add(Duration(days: 1)).subtract(Duration(milliseconds: 1));

    // 将 startOfDay 和 endOfDay 转换为时间戳
    int startTimestamp = startOfDay.millisecondsSinceEpoch;
    int endTimestamp = endOfDay.millisecondsSinceEpoch;

    // 筛选 _notes 中 createdAt 在指定时间范围内的记录
    final res = _notes.where((note) {
      int createdAtTimestamp = note.createdAt.millisecondsSinceEpoch;

      // 判断 note.createdAt 是否在指定时间戳范围内
      return createdAtTimestamp >= startTimestamp &&
          createdAtTimestamp <= endTimestamp;
    }).toList();

    // 更新状态
    setEventTemp(res);
    notifyListeners();

    // 打印筛选结果
    log("搜索结果: ${res.toString()}");
  }

  void searchNotesByTxt(String queryDate) {
    if (queryDate.isEmpty || queryDate == '') {
      setEventTemp([]);
      notifyListeners();
      return;
    }
    // 筛选 _notes 中 createdAt 在指定时间范围内的记录
    final res = _notes.where((note) {
      String originTxt = note.content;

      // 判断 note.createdAt 是否在指定时间戳范围内
      return originTxt.contains(queryDate.trim());
    }).toList();

    // 更新状态
    setEventTemp(res);
    notifyListeners();

    // 打印筛选结果
    log("搜索结果: ${res.toString()}");
  }

  Doodle getNoteById(String id) {
    // 筛选
    final res = _notes.where((note) => note.id.toString() == id).first;
    return res;
  }

  List<bool> _isExpandedList = [];

  List<bool> get isExpandedList => _isExpandedList;

  void toggleExpand(int index) {
    _isExpandedList[index] = !_isExpandedList[index];
    notifyListeners();
  }
}
