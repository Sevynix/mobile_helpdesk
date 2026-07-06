import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/ticket_model.dart';
import '../../domain/models/ticket_history_model.dart';
import '../../domain/models/comment_model.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/models/attachment_model.dart';
import 'dart:io';

class TicketRepository {
  final SupabaseClient _supabase;

  TicketRepository(this._supabase);

  Future<List<TicketModel>> getTickets() async {
    final response = await _supabase.from('tickets').select().order('created_at', ascending: false);
    return (response as List).map((json) => TicketModel.fromJson(json)).toList();
  }

  Future<TicketModel> getTicketById(String id) async {
    final response = await _supabase.from('tickets').select().eq('id', id).single();
    return TicketModel.fromJson(response);
  }

  Future<String> createTicket(String title, String description, String userId) async {
    final response = await _supabase.from('tickets').insert({
      'title': title,
      'description': description,
      'user_id': userId,
    }).select('id').single();
    return response['id'];
  }

  Future<void> uploadAttachment(String ticketId, File file) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final filePath = '$ticketId/$fileName';
    await _supabase.storage.from('ticket_attachments').upload(filePath, file);
    
    await _supabase.from('ticket_attachments').insert({
      'ticket_id': ticketId,
      'file_path': filePath,
      'file_type': file.path.split('.').last,
    });
  }

  Future<List<AttachmentModel>> getAttachments(String ticketId) async {
    final response = await _supabase.from('ticket_attachments').select().eq('ticket_id', ticketId).order('uploaded_at', ascending: true);
    return (response as List).map((json) => AttachmentModel.fromJson(json)).toList();
  }

  Future<void> assignTicket(String ticketId, String helpdeskId) async {
    await _supabase.rpc('assign_ticket', params: {
      'p_ticket_id': ticketId,
      'p_helpdesk_id': helpdeskId,
    });
  }

  Future<void> startTicket(String ticketId) async {
    await _supabase.rpc('start_ticket', params: {
      'p_ticket_id': ticketId,
    });
  }

  Future<void> finishTicket(String ticketId) async {
    await _supabase.rpc('finish_ticket', params: {
      'p_ticket_id': ticketId,
    });
  }

  Future<List<TicketHistoryModel>> getTicketHistory(String ticketId) async {
    final response = await _supabase.from('ticket_status_history').select('*, users(name)').eq('ticket_id', ticketId).order('changed_at', ascending: true);
    return (response as List).map((json) => TicketHistoryModel.fromJson(json)).toList();
  }

  Future<List<CommentModel>> getComments(String ticketId) async {
    final response = await _supabase.from('ticket_comments').select('*, users(name, role)').eq('ticket_id', ticketId).order('created_at', ascending: true);
    return (response as List).map((json) => CommentModel.fromJson(json)).toList();
  }

  Future<void> addComment(String ticketId, String userId, String text) async {
    await _supabase.from('ticket_comments').insert({
      'ticket_id': ticketId,
      'user_id': userId,
      'comment_text': text,
    });
  }

  Future<List<NotificationModel>> getNotifications(String userId) async {
    final response = await _supabase.from('notifications').select().eq('user_id', userId).order('created_at', ascending: false);
    return (response as List).map((json) => NotificationModel.fromJson(json)).toList();
  }
  
  Future<void> markNotificationRead(String notificationId) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', notificationId);
  }
}
