import 'package:flutter/material.dart';
import 'package:driveon_car_platform/models/social_content_models.dart';
import 'package:driveon_car_platform/services/social_service.dart';

class CommentsSection extends StatefulWidget {
  final String postId;
  final List<SocialComment> initialComments;
  final Function(int) onCommentCountChanged;

  const CommentsSection({
    super.key,
    required this.postId,
    required this.initialComments,
    required this.onCommentCountChanged,
  });

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  List<SocialComment> _comments = [];
  bool _isAddingComment = false;
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _comments = widget.initialComments;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isAddingComment = true;
    });

    try {
      final newComment = await SocialService.addComment(widget.postId, content);
      if (newComment != null) {
        setState(() {
          _comments.insert(0, newComment);
        });
        _commentController.clear();
        widget.onCommentCountChanged(_comments.length);
        
        // Scroll to top to show new comment
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to add comment: $e');
    } finally {
      setState(() {
        _isAddingComment = false;
      });
    }
  }

  Future<void> _toggleCommentLike(SocialComment comment) async {
    try {
      final success = await SocialService.toggleCommentLike(comment.id);
      if (success) {
        setState(() {
          final index = _comments.indexWhere((c) => c.id == comment.id);
          if (index != -1) {
            _comments[index] = SocialComment(
              id: comment.id,
              postId: comment.postId,
              userId: comment.userId,
              content: comment.content,
              createdAt: comment.createdAt,
              updatedAt: comment.updatedAt,
              likes: comment.isLikedByUser ? comment.likes - 1 : comment.likes + 1,
              isLikedByUser: !comment.isLikedByUser,
            );
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to like comment: $e');
    }
  }

  Future<void> _deleteComment(SocialComment comment) async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    try {
      final success = await SocialService.deleteComment(comment.id);
      if (success) {
        setState(() {
          _comments.removeWhere((c) => c.id == comment.id);
        });
        widget.onCommentCountChanged(_comments.length);
        _showSuccessSnackBar('Comment deleted');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to delete comment: $e');
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Comments (${_comments.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Comments list
          Expanded(
            child: _comments.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No comments yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          'Be the first to comment!',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return _buildCommentItem(comment);
                    },
                  ),
          ),
          
          const Divider(height: 1),
          
          // Add comment input
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                const SizedBox(width: 8),
                _isAddingComment
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        onPressed: _addComment,
                        icon: const Icon(Icons.send),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue[50],
                          foregroundColor: Colors.blue[700],
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(SocialComment comment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue[100],
            child: Text(
              'U${comment.userId}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info and time
                Row(
                  children: [
                    Text(
                      'user_${comment.userId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimeAgo(comment.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // Comment text
                Text(
                  comment.content,
                  style: const TextStyle(fontSize: 14),
                ),
                
                const SizedBox(height: 8),
                
                // Actions
                Row(
                  children: [
                    // Like button
                    InkWell(
                      onTap: () => _toggleCommentLike(comment),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            comment.isLikedByUser ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: comment.isLikedByUser ? Colors.red : Colors.grey[600],
                          ),
                          if (comment.likes > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${comment.likes}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Reply button
                    InkWell(
                      onTap: () {
                        // TODO: Implement reply functionality
                        _showErrorSnackBar('Reply feature coming soon!');
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.reply, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Reply',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // More options
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteComment(comment);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 16),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: Icon(Icons.more_vert, size: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
