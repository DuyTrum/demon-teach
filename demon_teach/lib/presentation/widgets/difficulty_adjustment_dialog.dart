import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/performance_data.dart';

/// Dialog for confirming difficulty adjustment
class DifficultyAdjustmentDialog extends ConsumerStatefulWidget {
  final DifficultyAdjustment adjustment;
  final String userId;
  final String targetLanguage;
  final VoidCallback onConfirm;

  const DifficultyAdjustmentDialog({
    super.key,
    required this.adjustment,
    required this.userId,
    required this.targetLanguage,
    required this.onConfirm,
  });

  @override
  ConsumerState<DifficultyAdjustmentDialog> createState() =>
      _DifficultyAdjustmentDialogState();
}

class _DifficultyAdjustmentDialogState
    extends ConsumerState<DifficultyAdjustmentDialog> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.demonNodeLocked,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: _getColor().withOpacity(0.5)),
      ),
      title: Row(
        children: [
          Icon(
            _getIcon(),
            color: _getColor(),
            size: 32,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              'Adjust Difficulty',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.adjustment.description,
            style: const TextStyle(color: AppTheme.demonTextLight),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _getColor().withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What will change:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                _buildChangeItem(
                  icon: Icons.book,
                  text: _getContentChangeText(),
                ),
                _buildChangeItem(
                  icon: Icons.speed,
                  text: _getPaceChangeText(),
                ),
                _buildChangeItem(
                  icon: Icons.psychology,
                  text: 'Your learning path will be updated',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'You can always manually adjust the difficulty later in settings.',
            style: TextStyle(
              color: AppTheme.demonTextMuted,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: AppTheme.demonTextMuted)),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _handleConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: _getColor().withOpacity(0.2),
            foregroundColor: _getColor(),
            side: BorderSide(color: _getColor()),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isProcessing
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_getColor()),
                  ),
                )
              : Text('Apply ${widget.adjustment.displayName}'),
        ),
      ],
    );
  }

  Widget _buildChangeItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _getColor()),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppTheme.demonTextLight, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (widget.adjustment) {
      case DifficultyAdjustment.increase:
        return Icons.arrow_upward;
      case DifficultyAdjustment.decrease:
        return Icons.arrow_downward;
      case DifficultyAdjustment.maintain:
        return Icons.check_circle;
    }
  }

  Color _getColor() {
    switch (widget.adjustment) {
      case DifficultyAdjustment.increase:
        return Colors.green;
      case DifficultyAdjustment.decrease:
        return Colors.orange;
      case DifficultyAdjustment.maintain:
        return Colors.blue;
    }
  }

  String _getContentChangeText() {
    switch (widget.adjustment) {
      case DifficultyAdjustment.increase:
        return 'More challenging vocabulary and grammar';
      case DifficultyAdjustment.decrease:
        return 'Simpler vocabulary and more practice';
      case DifficultyAdjustment.maintain:
        return 'Content difficulty stays the same';
    }
  }

  String _getPaceChangeText() {
    switch (widget.adjustment) {
      case DifficultyAdjustment.increase:
        return 'Faster progression through topics';
      case DifficultyAdjustment.decrease:
        return 'More time on fundamentals';
      case DifficultyAdjustment.maintain:
        return 'Learning pace stays the same';
    }
  }

  Future<void> _handleConfirm() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // In a real implementation, this would call a use case to:
      // 1. Update the user's proficiency level
      // 2. Regenerate the learning path
      // 3. Notify the user

      // For now, we'll simulate the adjustment
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pop();
        widget.onConfirm();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Difficulty ${widget.adjustment.displayName.toLowerCase()}d successfully!',
            ),
            backgroundColor: _getColor(),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to adjust difficulty: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
