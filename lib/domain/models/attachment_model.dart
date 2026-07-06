class AttachmentModel {
  final String id;
  final String ticketId;
  final String filePath;
  final String? fileType;
  final String uploadedAt;

  AttachmentModel({
    required this.id,
    required this.ticketId,
    required this.filePath,
    this.fileType,
    required this.uploadedAt,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'],
      ticketId: json['ticket_id'],
      filePath: json['file_path'],
      fileType: json['file_type'],
      uploadedAt: json['uploaded_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'file_path': filePath,
      'file_type': fileType,
      'uploaded_at': uploadedAt,
    };
  }
}
