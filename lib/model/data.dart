import 'package:intl/intl.dart';

class Doodle {
  final int? id;
  final String name;
  final String time;
  late String content;
  late String doodle;
  late String? video;
  late String? audio;

  final List<String>? label;
  final String? weather;
  final String? location;
  final int? isTop;
  DateTime get createdAt => DateTime.parse(_createdAt);
  String get formattedCreatedAt {
    return DateFormat('MM/dd HH:mm・EE').format(createdAt);
  }

  final String _createdAt;

  DateTime get updatedAt => DateTime.parse(_updatedAt);
  final String _updatedAt;

  Doodle({
    this.id,
    required this.name,
    required this.time,
    this.content = '',
    this.doodle = '',
    this.audio = '',
    this.video = '',
    this.label = const ['1'],
    this.weather = '100',
    this.location = '未知',
    this.isTop = 0,
    String? createdAt,
    String? updatedAt,
  })  : _createdAt = createdAt ?? DateTime.now().toIso8601String(),
        _updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  // 将 Doodle 转换为 Map
  Map<String, dynamic> toMap() {
    // final currentDate = DateTime.now();
    // final formattedDate =
    //     '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
    return {
      'id': id,
      'name': name,
      'time': time,
      'content': content,
      'doodle': doodle,
      'audio': audio,
      'video': video,
      'isTop': isTop,
      'label': label?.join(',') ?? '1', // 确保 label 是非 null 的
      'weather': weather ?? '100', // 防止 weather 为 null
      'location': location ?? '未知',
      // 'createdAt': _createdAt,
    };
  }

  // 从 Map 创建 Doodle 实例
  factory Doodle.fromMap(Map<String, dynamic> map) {
    return Doodle(
      id: map['id'] as int?,
      name: map['name'] ?? '', // 防止 name 为 null
      time: map['time'] ?? '', // 防止 time 为 null
      content: map['content'] ?? '', // 防止 content 为 null
      doodle: map['doodle'] ?? '', // 防止 doodle 为 null
      audio: map['audio'] ?? '', // 防止 doodle 为 null
      video: map['video'] ?? '',
      label: (map['label'] as String?)?.split(',') ?? ['1'], // 防止 label 为 null
      weather: map['weather'] ?? '', // 防止 weather 为 null
      location: map['location'] ?? '', // 防止 location 为 null
      isTop: map['isTop'] as int?,
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: map['updatedAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  // 从 JSON 创建 Doodle 实例
  factory Doodle.fromJson(Map<String, dynamic> json) {
    return Doodle(
      id: json['id'] as int?,
      name: json['name'] ?? '', // 防止 name 为 null
      time: json['time'] ?? '', // 防止 time 为 null
      content: json['content'] ?? '', // 防止 content 为 null
      doodle: json['doodle'] ?? '', // 防止 doodle 为 null
      audio: json['audio'] ?? '', // 防止 doodle 为 null
      video: json['video'] ?? '',
      isTop: json['isTop'] as int?,
      label: (json['label'] as String?)?.split(',') ?? ['1'], // 防止 label 为 null
      weather: json['weather'] ?? '', // 防止 weather 为 null
      location: json['location'] ?? '', // 防止 location 为 null
    );
  }

  // 将 Doodle 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'time': time,
      'content': content,
      'doodle': doodle,
      'audio': audio,
      'video': video,
      'isTop': isTop,
      'label': label?.join(',') ?? '1',
      'weather': weather,
      'location': location,
    };
  }
}

// comment表
class Comment {
  final int? id; // 评论 ID
  final int doodleId; // 关联的 doodle ID
  final String commenter; // 评论者
  final String comment; // 评论内容
  final String time; // 评论时间
  final String? createdAt; // 创建时间
  final String? updatedAt; // 更新时间

  Comment({
    this.id,
    required this.doodleId,
    required this.commenter,
    required this.comment,
    required this.time,
    this.createdAt,
    this.updatedAt,
  });

  // 将 Comment 对象转换为 Map，用于插入到数据库
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doodle_id': doodleId,
      'commenter': commenter,
      'comment': comment,
      'time': time,
    };
  }

  // 将 Map 转换为 Comment 对象
  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'],
      doodleId: map['doodle_id'], // 确保在查询中获取 doodle_id
      commenter: map['commenter'],
      comment: map['comment'],
      time: map['time'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }
}

// 创建demo
void test() async {
  // 创建一个新的 Comment 对象
  Comment newComment = Comment(
    doodleId: 1, // 关联的 doodle ID
    commenter: 'John Doe', // 评论者
    comment: 'Great note!', // 评论内容
    time: DateTime.now().toString(), // 评论时间
  );

  // 插入评论
  // final id = await dbHelper.createComment(newComment);
  // print('Inserted comment with id: $id');
}
