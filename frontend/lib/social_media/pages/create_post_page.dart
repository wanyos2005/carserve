import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:driveon_car_platform/social_media/services/social_service.dart';
import 'package:driveon_car_platform/social_media/models/social_content_models.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _contentController = TextEditingController();
  final List<String> _hashtags = [];
  final TextEditingController _hashtagController = TextEditingController();
  
  final List<String> _mediaUrls = [];
  final List<File> _selectedFiles = [];
  bool _isUploading = false;
  bool _isCreating = false;
  
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _contentController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedFiles.add(File(image.path));
        });
        await _uploadMedia(File(image.path));
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (video != null) {
        setState(() {
          _selectedFiles.add(File(video.path));
        });
        await _uploadMedia(File(video.path), isVideo: true);
      }
    } catch (e) {
      _showErrorSnackBar('Error picking video: $e');
    }
  }

  Future<void> _uploadMedia(File file, {bool isVideo = false}) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final url = await SocialService.uploadMedia(
        file,
        folder: 'posts',
        type: isVideo ? 'video' : 'image',
      );
      
      if (url != null) {
        setState(() {
          _mediaUrls.add(url);
        });
        _showSuccessSnackBar('Media uploaded successfully!');
      } else {
        _showErrorSnackBar('Upload failed. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Upload error: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _addHashtag() {
    String hashtag = _hashtagController.text.trim();
    if (hashtag.isNotEmpty && !hashtag.startsWith('#')) {
      hashtag = '#$hashtag';
    }
    
    if (hashtag.isNotEmpty && !_hashtags.contains(hashtag)) {
      setState(() {
        _hashtags.add(hashtag);
        _hashtagController.clear();
      });
    }
  }

  void _removeHashtag(String hashtag) {
    setState(() {
      _hashtags.remove(hashtag);
    });
  }

  PostType _getPostType() {
    if (_mediaUrls.isEmpty) return PostType.text;
    
    // Check if any media URL is a video
    for (String url in _mediaUrls) {
      final extension = url.toLowerCase().split('.').last;
      if (['mp4', 'webm', 'mov', 'avi'].contains(extension)) {
        return PostType.video;
      }
    }
    
    return PostType.image;
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty) {
      _showErrorSnackBar('Please write some content for your post');
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final post = await SocialService.createPost(
        content: _contentController.text.trim(),
        mediaUrls: _mediaUrls,
        hashtags: _hashtags,
        type: _getPostType(),
      );

      if (post != null) {
        _showSuccessSnackBar('Post created successfully!');
        Navigator.of(context).pop(true); // Return true to indicate success
      } else {
        _showErrorSnackBar('Failed to create post. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Error creating post: $e');
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createPost,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Post',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: "What's on your mind? Share your automotive journey...",
                  border: InputBorder.none,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Media upload section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Media',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Upload buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _pickMedia,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[50],
                            foregroundColor: Colors.blue[700],
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _pickVideo,
                          icon: const Icon(Icons.videocam),
                          label: const Text('Video'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[50],
                            foregroundColor: Colors.purple[700],
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Upload progress
                  if (_isUploading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text(
                      'Uploading media to Cloudflare R2...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  
                  // Media previews
                  if (_mediaUrls.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Uploaded Media:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _mediaUrls.map((url) => Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.broken_image);
                            },
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Hashtags section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hashtags',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Hashtag input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _hashtagController,
                          decoration: const InputDecoration(
                            hintText: 'Add hashtag...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: (_) => _addHashtag(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addHashtag,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  
                  // Hashtag chips
                  if (_hashtags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _hashtags.map((hashtag) => Chip(
                        label: Text(hashtag),
                        onDeleted: () => _removeHashtag(hashtag),
                        backgroundColor: Colors.blue[50],
                        deleteIconColor: Colors.blue[700],
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Post type indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _mediaUrls.isNotEmpty ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _mediaUrls.isNotEmpty ? Colors.green[200]! : Colors.orange[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getPostType() == PostType.video ? Icons.videocam : 
                    _getPostType() == PostType.image ? Icons.image : Icons.text_fields,
                    color: _mediaUrls.isNotEmpty ? Colors.green[700] : Colors.orange[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getPostType() == PostType.video ? 'Video Post (${_mediaUrls.length} file${_mediaUrls.length > 1 ? 's' : ''})' :
                    _getPostType() == PostType.image ? 'Image Post (${_mediaUrls.length} file${_mediaUrls.length > 1 ? 's' : ''})' :
                    'Text Post',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _mediaUrls.isNotEmpty ? Colors.green[700] : Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
