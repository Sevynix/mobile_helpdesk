import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/ticket_provider.dart';
import '../../../providers/auth_provider.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;
  File? _attachment;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _attachment = File(pickedFile.path);
      });
    }
  }

  Future<void> _handleCreate() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan deskripsi harus diisi', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.accent),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) throw Exception("Belum login");

      final repo = ref.read(ticketRepositoryProvider);
      final ticketId = await repo.createTicket(title, desc, user.id);
      
      if (_attachment != null) {
        await repo.uploadAttachment(ticketId, _attachment!);
      }
      
      if (mounted) {
        ref.invalidate(ticketsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tiket berhasil dibuat', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.statusClose),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString(), style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.accent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Tiket Baru', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FadeInUp(
          duration: const Duration(milliseconds: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Masalah',
                  prefixIcon: Icon(LucideIcons.heading, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Lengkap',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(LucideIcons.alignLeft, color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(LucideIcons.image),
                label: const Text('Lampirkan Gambar'),
              ),
              if (_attachment != null) ...[
                const SizedBox(height: 16),
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_attachment!, height: 150, width: double.infinity, fit: BoxFit.cover),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.white),
                      onPressed: () => setState(() => _attachment = null),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleCreate,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Kirim Tiket'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
