import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/domain/entities/speaking_exercise.dart';

/// Controller for managing speaking practice audio recording
class SpeakingController {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Get current recording path
  String? get currentRecordingPath => _currentRecordingPath;

  /// Request microphone permission
  Future<Result<void>> requestPermission() async {
    try {
      final status = await Permission.microphone.request();

      if (status.isDenied) {
        return Result.failure(
          const ValidationFailure(
            field: 'microphone',
            message: 'Microphone permission denied',
          ),
        );
      }

      if (status.isPermanentlyDenied) {
        return Result.failure(
          const ValidationFailure(
            field: 'microphone',
            message:
                'Microphone permission permanently denied. Please enable in settings.',
          ),
        );
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        ValidationFailure(
          field: 'microphone',
          message: 'Failed to request permission: ${e.toString()}',
        ),
      );
    }
  }

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Start recording audio
  Future<Result<void>> startRecording() async {
    try {
      // Check permission first
      if (!await hasPermission()) {
        final permissionResult = await requestPermission();
        if (!permissionResult.isSuccess) {
          return permissionResult;
        }
      }

      // Check if already recording
      if (_isRecording) {
        return Result.failure(
          const ValidationFailure(
            field: 'recording',
            message: 'Already recording',
          ),
        );
      }

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/recordings');

      // Create recordings directory if it doesn't exist
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${recordingsDir.path}/recording_$timestamp.m4a';

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      return Result.success(null);
    } catch (e) {
      _isRecording = false;
      _currentRecordingPath = null;
      return Result.failure(
        CacheFailure(message: 'Failed to start recording: ${e.toString()}'),
      );
    }
  }

  /// Stop recording and return the file path
  Future<Result<String>> stopRecording() async {
    try {
      if (!_isRecording) {
        return Result.failure(
          const ValidationFailure(
            field: 'recording',
            message: 'Not currently recording',
          ),
        );
      }

      final path = await _recorder.stop();
      _isRecording = false;

      if (path == null || path.isEmpty) {
        return Result.failure(
          const CacheFailure(message: 'Recording failed - no file created'),
        );
      }

      // Verify file exists
      final file = File(path);
      if (!await file.exists()) {
        return Result.failure(
          const CacheFailure(message: 'Recording file not found'),
        );
      }

      final recordingPath = _currentRecordingPath ?? path;
      _currentRecordingPath = null;

      return Result.success(recordingPath);
    } catch (e) {
      _isRecording = false;
      _currentRecordingPath = null;
      return Result.failure(
        CacheFailure(message: 'Failed to stop recording: ${e.toString()}'),
      );
    }
  }

  /// Cancel recording without saving
  Future<Result<void>> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;

        // Delete the recording file if it exists
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
          _currentRecordingPath = null;
        }
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to cancel recording: ${e.toString()}'),
      );
    }
  }

  /// Analyze pronunciation and provide feedback
  /// This is a placeholder implementation - can be enhanced with AI later
  Future<Result<PronunciationFeedback>> analyzePronunciation(
    String audioFilePath,
    String expectedPhrase,
  ) async {
    try {
      // Verify audio file exists
      final file = File(audioFilePath);
      if (!await file.exists()) {
        return Result.failure(
          const CacheFailure(message: 'Audio file not found'),
        );
      }

      // Get file size to check if recording has content
      final fileSize = await file.length();
      if (fileSize < 1000) {
        // Less than 1KB - likely empty or too short
        return Result.success(
          const PronunciationFeedback(
            accuracyScore: 0.3,
            feedback:
                'Recording too short. Please try speaking the phrase clearly.',
            suggestions: [
              'Speak louder and more clearly',
              'Hold the record button while speaking',
              'Try recording in a quieter environment',
            ],
          ),
        );
      }

      // Placeholder algorithm - generates feedback based on file size
      // In a real implementation, this would use speech recognition and comparison
      final score = _calculatePlaceholderScore(fileSize);
      final feedback = _generateFeedback(score);
      final suggestions = _generateSuggestions(score);

      return Result.success(
        PronunciationFeedback(
          accuracyScore: score,
          feedback: feedback,
          suggestions: suggestions,
        ),
      );
    } catch (e) {
      return Result.failure(
        CacheFailure(
            message: 'Failed to analyze pronunciation: ${e.toString()}'),
      );
    }
  }

  /// Calculate placeholder score based on file size
  /// This is a simple heuristic - real implementation would use AI
  double _calculatePlaceholderScore(int fileSize) {
    // Assume good recordings are between 10KB and 500KB
    if (fileSize < 5000) {
      return 0.4; // Too short
    } else if (fileSize > 1000000) {
      return 0.5; // Too long
    } else if (fileSize >= 10000 && fileSize <= 500000) {
      return 0.75 + (0.2 * (fileSize % 100) / 100); // Good range: 0.75-0.95
    } else {
      return 0.6 + (0.15 * (fileSize % 100) / 100); // Acceptable: 0.6-0.75
    }
  }

  /// Generate feedback message based on score
  String _generateFeedback(double score) {
    if (score >= 0.9) {
      return 'Excellent pronunciation! Your speech is clear and accurate.';
    } else if (score >= 0.75) {
      return 'Good job! Your pronunciation is quite clear with minor improvements needed.';
    } else if (score >= 0.6) {
      return 'Fair attempt. Keep practicing to improve clarity and accuracy.';
    } else {
      return 'Needs improvement. Try speaking more slowly and clearly.';
    }
  }

  /// Generate suggestions based on score
  List<String> _generateSuggestions(double score) {
    if (score >= 0.9) {
      return [
        'Keep up the great work!',
        'Try more challenging phrases',
      ];
    } else if (score >= 0.75) {
      return [
        'Focus on pronunciation of individual sounds',
        'Listen to the model audio carefully',
        'Practice speaking at a steady pace',
      ];
    } else if (score >= 0.6) {
      return [
        'Break the phrase into smaller parts',
        'Repeat after the model audio multiple times',
        'Record in a quiet environment',
        'Speak more slowly and clearly',
      ];
    } else {
      return [
        'Listen to the model audio several times',
        'Practice each word separately first',
        'Speak louder and more clearly',
        'Ensure you\'re in a quiet environment',
      ];
    }
  }

  /// Delete a recording file
  Future<Result<void>> deleteRecordingFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to delete recording: ${e.toString()}'),
      );
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (_isRecording) {
      await cancelRecording();
    }
    await _recorder.dispose();
  }
}
