class Comment {
  final int commentId;
  final int adId;
  final String userPhoneNumber;
  final String? nickname;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.commentId,
    required this.adId,
    required this.userPhoneNumber,
    required this.nickname,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['comment_id'],
      adId: json['ad_id'],
      userPhoneNumber: json['user_phone_number'],
      nickname: json['nickname'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comment_id': commentId,
      'ad_id': adId,
      'user_phone_number': userPhoneNumber,
      'nickname': nickname,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
