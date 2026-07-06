class TicketHistoryModel {
  final String id;
  final String ticketId;
  final String? fromStatus;
  final String toStatus;
  final String? changedByUserId;
  final String? changedByUserName;
  final DateTime changedAt;

  TicketHistoryModel({
    required this.id,
    required this.ticketId,
    this.fromStatus,
    required this.toStatus,
    this.changedByUserId,
    this.changedByUserName,
    required this.changedAt,
  });

  factory TicketHistoryModel.fromJson(Map<String, dynamic> json) {
    return TicketHistoryModel(
      id: json['id'],
      ticketId: json['ticket_id'],
      fromStatus: json['from_status'],
      toStatus: json['to_status'],
      changedByUserId: json['changed_by_user_id'],
      changedByUserName: json['users'] != null ? json['users']['name'] : null,
      changedAt: DateTime.parse(json['changed_at']),
    );
  }
}
