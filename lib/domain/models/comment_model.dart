class CommentModel {
  final String id;
  final String ticketId;
  final String userId;
  final String commentText;
  final DateTime createdAt;
  final String? userName;
  final String? userRole;

  CommentModel({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.commentText,
    required this.createdAt,
    this.userName,
    this.userRole,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      ticketId: json['ticket_id'],
      userId: json['user_id'],
      commentText: json['comment_text'],
      createdAt: DateTime.parse(json['created_at']),
      userName: json['users'] != null ? json['users']['name'] : null,
      userRole: json['users'] != null ? json['users']['role'] : null,
    );
  }
}
