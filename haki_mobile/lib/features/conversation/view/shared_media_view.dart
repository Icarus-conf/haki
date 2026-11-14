import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/message_model.dart';
import '../../../services/api_service.dart';
import '../../../widgets/chat/encrypted_image.dart';
import '../../../widgets/loading_indicator.dart';

class SharedMediaView extends StatefulWidget {
  final int recipientId;
  final String recipientName;

  const SharedMediaView({super.key, required this.recipientId, required this.recipientName});

  @override
  State<SharedMediaView> createState() => _SharedMediaViewState();
}

class _SharedMediaViewState extends State<SharedMediaView> {
  bool _isLoading = true;
  List<MessageModel> _mediaMessages = [];

  @override
  void initState() {
    super.initState();
    _loadSharedMedia();
  }

  Future<void> _loadSharedMedia() async {
    setState(() => _isLoading = true);

    final allMessages = await context.read<ApiService>().getSharedMedia(widget.recipientId);
    if (!mounted) return;

    setState(() {
      _mediaMessages = allMessages;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Shared photos', style: TextStyle(fontSize: 18)),
            Text(widget.recipientName, style: TextStyle(fontSize: 12, color: Color(0xFF8E8EA6))),
          ],
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _mediaMessages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64, color: const Color(0xFF8E8EA6)),
                  const SizedBox(height: 16),
                  Text(
                    'No shared media',
                    style: TextStyle(fontSize: 16, color: const Color(0xFF8E8EA6)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Photos and videos you share will appear here',
                    style: TextStyle(fontSize: 14, color: const Color(0xFF8E8EA6)),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _mediaMessages.length,
              itemBuilder: (context, index) {
                final message = _mediaMessages[index];
                return _MediaThumbnail(message: message);
              },
            ),
    );
  }
}

class _MediaThumbnail extends StatelessWidget {
  final MessageModel message;

  const _MediaThumbnail({required this.message});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => _FullScreenMedia(message: message)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C26),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(8), child: _buildThumbnail(context)),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    if (message.attachmentUrl == null) {
      return const Center(child: Icon(Icons.broken_image));
    }

    final isRemote =
        message.attachmentUrl!.startsWith('http') || message.attachmentUrl!.startsWith('/uploads');
    final isEncrypted = message.mediaIv != null && message.mediaKeys != null;

    if (isRemote) {
      if (isEncrypted) {
        return EncryptedImage(
          url: message.attachmentUrl!,
          iv: message.mediaIv!,
          keys: message.mediaKeys!,
        );
      } else {
        return CachedNetworkImage(
          imageUrl: message.attachmentUrl!.startsWith('http')
              ? message.attachmentUrl!
              : '${ApiService.baseUrl}${message.attachmentUrl}',
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: LoadingIndicator(size: 20)),
          errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
        );
      }
    } else {
      final file = File(message.attachmentUrl!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      } else {
        return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
      }
    }
  }
}

class _FullScreenMedia extends StatelessWidget {
  final MessageModel message;

  const _FullScreenMedia({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(message.sender, style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: InteractiveViewer(minScale: 0.5, maxScale: 4.0, child: _buildFullImage(context)),
      ),
    );
  }

  Widget _buildFullImage(BuildContext context) {
    if (message.attachmentUrl == null) {
      return const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 64));
    }

    final isRemote =
        message.attachmentUrl!.startsWith('http') || message.attachmentUrl!.startsWith('/uploads');
    final isEncrypted = message.mediaIv != null && message.mediaKeys != null;

    if (isRemote) {
      if (isEncrypted) {
        return EncryptedImage(
          url: message.attachmentUrl!,
          iv: message.mediaIv!,
          keys: message.mediaKeys!,
        );
      } else {
        return CachedNetworkImage(
          imageUrl: message.attachmentUrl!.startsWith('http')
              ? message.attachmentUrl!
              : '${ApiService.baseUrl}${message.attachmentUrl}',
          fit: BoxFit.contain,
          placeholder: (context, url) => const Center(child: LoadingIndicator(size: 40)),
          errorWidget: (context, url, error) =>
              const Center(child: Icon(Icons.error, color: Colors.white, size: 64)),
        );
      }
    } else {
      final file = File(message.attachmentUrl!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.contain);
      } else {
        return const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 64));
      }
    }
  }
}
