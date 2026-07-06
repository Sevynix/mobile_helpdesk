class TicketHistoryModel {
  final String id;
  final String ticketId;
  final String? fromStatus;
  final String toStatus;
  final String? changedByUserId;
  final DateTime changedAt;

  TicketHistoryModel({
    required this.id,
    required this.ticketId,
    this.fromStatus,
    required this.toStatus,
    this.changedByUserId,
    required this.changedAt,
  });

  factory TicketHistoryModel.fromJson(Map<String, dynamic> json) {
    return TicketHistoryModel(
      id: json['id'],
      ticketId: json['ticket_id'],
      fromStatus: json['from_status'],
      toStatus: json['to_status'],
      changedByUserId: json['changed_by_user_id'],
      changedAt: DateTime.parse(json['changed_at']),
    );
  }
}
