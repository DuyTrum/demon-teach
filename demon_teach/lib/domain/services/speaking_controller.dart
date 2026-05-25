import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:demon_teach/domain/entities/speaking_exercise.dart';

/// Controller for managing speaking practice audio recording
class SpeakingController {
  final Dio? _dio;
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;

  SpeakingController([this._dio]);

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Get current recording path
  String? get currentRecordingPath => _currentRecordingPath;

  /// Request microphone permission
  Future<Result<void>> requestPermission() async {
    try {
      if (kIsWeb) {
        final granted = await _recorder.hasPermission();
        if (granted) {
          return Result.success(null);
        } else {
          return Result.failure(
            const ValidationFailure(
              field: 'microphone',
              message: 'Microphone permission denied',
            ),
          );
        }
      }

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
    if (kIsWeb) {
      return _recorder.hasPermission();
    }
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

      if (kIsWeb) {
        _currentRecordingPath = '';
      } else {
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
      }

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

      // On Web, the path is a blob: URL, not a local file, so we do not verify with File(path)
      if (!kIsWeb) {
        final file = File(path);
        if (!await file.exists()) {
          return Result.failure(
            const CacheFailure(message: 'Recording file not found'),
          );
        }
      }

      final recordingPath = (kIsWeb || _currentRecordingPath == '') ? path : (_currentRecordingPath ?? path);
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
        if (_currentRecordingPath != null && !kIsWeb && _currentRecordingPath!.isNotEmpty) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
        _currentRecordingPath = null;
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to cancel recording: ${e.toString()}'),
      );
    }
  }

  /// Analyze pronunciation and provide feedback
  /// Call the backend AI speech evaluator if available, otherwise fall back to placeholder
  Future<Result<PronunciationFeedback>> analyzePronunciation(
    String audioFilePath,
    String expectedPhrase, {
    String language = 'en',
  }) async {
    try {
      int fileSize = 0;
      Uint8List? audioBytes;

      if (kIsWeb) {
        try {
          // On Web, we fetch the blob bytes using a fresh Dio client
          // Do NOT use the injected _dio here because it has a baseUrl set,
          // which causes Dio to prepend the baseUrl to the 'blob:' URL.
          // We also configure validateStatus to accept status 0 or null,
          // as fetching local blob URLs via XMLHttpRequest returns status 0 on success.
          final dioClient = Dio();
          final response = await dioClient.get<List<int>>(
            audioFilePath,
            options: Options(
              responseType: ResponseType.bytes,
              validateStatus: (status) => status == 200 || status == 0 || status == null,
            ),
          );
          if (response.data != null) {
            audioBytes = Uint8List.fromList(response.data!);
            fileSize = audioBytes.length;
          }
        } catch (e) {
          print('⚠️ Error reading blob bytes on web: $e');
        }
      } else {
        // Verify audio file exists
        final file = File(audioFilePath);
        if (!await file.exists()) {
          return Result.failure(
            const CacheFailure(message: 'Audio file not found'),
          );
        }
        fileSize = await file.length();
        audioBytes = await file.readAsBytes();
      }

      if (fileSize < 1000) {
        // Less than 1KB - likely empty or too short
        return Result.success(
          const PronunciationFeedback(
            accuracyScore: 0.0,
            feedback:
                '😈 Ngươi im lặng như một cái xác không hồn dưới nấm mồ vậy! Đừng hòng qua mắt Giáo Viên Ác Quỷ, hãy cất cái giọng phàm trần của ngươi lên xem nào!',
            suggestions: [
              'Cất giọng to lên để đánh thức linh hồn quỷ dữ đang ngủ say!',
              'Giữ chặt nút ghi âm như thể mạng sống của ngươi phụ thuộc hoàn toàn vào nó!',
              'Tìm một góc yên tĩnh nơi âm ty để giọng nói không bị nuốt chửng!',
            ],
          ),
        );
      }

      // If Dio client is available, call the backend AI speech evaluator API
      if (_dio != null) {
        try {
          String audioPayload;
          
          try {
            if (kIsWeb) {
              // Web uses base64 fallback directly to bypass Firebase Storage Blaze plan requirements & CORS issues
              throw Exception('Bypass Firebase Storage on Web');
            }

            print('🌐 Uploading recording to Firebase Cloud Storage...');
            final storageRef = FirebaseStorage.instance.ref();
            final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
            final fileRef = storageRef.child('recordings/$fileName');
            
            if (kIsWeb) {
              if (audioBytes != null) {
                // Upload raw bytes on Web
                await fileRef.putData(audioBytes);
                audioPayload = await fileRef.getDownloadURL();
              } else {
                throw Exception('Audio bytes are null');
              }
            } else {
              final file = File(audioFilePath);
              await fileRef.putFile(file);
              audioPayload = await fileRef.getDownloadURL();
            }
            print('🌐 Uploaded successfully! URL: $audioPayload');
          } catch (storageErr) {
            print('⚠️ Firebase Storage upload failed, falling back to base64: $storageErr');
            if (audioBytes != null) {
              audioPayload = base64Encode(audioBytes);
            } else if (!kIsWeb) {
              final file = File(audioFilePath);
              final bytes = await file.readAsBytes();
              audioPayload = base64Encode(bytes);
            } else {
              throw Exception('Cannot generate base64 payload on Web');
            }
          }

          print('🎤 Sending speech recording to backend for AI evaluation...');
          final response = await _dio!.post(
            '/api/generator/evaluate-speech',
            data: {
              'audio': audioPayload,
              'phrase': expectedPhrase,
              'language': language,
            },
          );

          dynamic responseData = response.data;
          if (responseData is String) {
            responseData = jsonDecode(responseData);
          }

          if (response.statusCode == 200 && responseData != null && responseData['success'] == true) {
            final data = responseData['data'];
            return Result.success(
              PronunciationFeedback(
                accuracyScore: (data['accuracyScore'] as num).toDouble(),
                feedback: data['feedback'] as String,
                suggestions: List<String>.from(data['suggestions'] as List),
                feedbackAudioBase64: data['feedbackAudio'] as String?,
              ),
            );
          }
        } catch (e) {
          print('⚠️ Backend AI speech evaluation failed (falling back to local placeholder): $e');
        }
      }

      // Fallback: Placeholder algorithm
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
      return '😈 Ngươi phát âm xuất sắc đến bất ngờ! Có vẻ móng vuốt của ta chưa thể chạm vào linh hồn ngươi hôm nay. Hãy tiếp tục giữ lấy sự sống đó!';
    } else if (score >= 0.75) {
      return '😈 Khá khen cho nỗ lực của kẻ phàm trần! Phát âm tương đối rõ ràng, nhưng chỉ cần một chút sơ hở là ngươi sẽ rơi thẳng xuống vực sâu địa ngục ngay!';
    } else if (score >= 0.6) {
      return '😈 Tiếng thì thầm của ngươi nghe thật yếu ớt! Giọng nói này chưa đủ sức thuyết phục quỷ dữ đâu. Hãy luyện tập trước khi ta mất kiên nhẫn!';
    } else {
      return '😈 Phát âm kinh khủng! Nghe như tiếng thét đau đớn của các linh hồn tội lỗi vậy! Đừng lười biếng nữa, cất giọng rõ ràng lên trước khi ta trừng phạt ngươi!';
    }
  }

  /// Generate suggestions based on score
  List<String> _generateSuggestions(double score) {
    if (score >= 0.9) {
      return [
        'Giữ vững phong độ ma mị này đi!',
        'Thử thách bản thân với những câu chú khó hơn!',
      ];
    } else if (score >= 0.75) {
      return [
        'Tập trung vào từng âm tiết như cách quỷ dữ săn mồi!',
        'Lắng nghe kỹ giọng đọc mẫu để hấp thu năng lượng chuẩn xác!',
        'Kiểm soát tốc độ nói để không bị quỷ thần bắt lỗi!',
      ];
    } else if (score >= 0.6) {
      return [
        'Chia nhỏ câu nói ra để không bị hụt hơi trước mặt ác quỷ!',
        'Lặp đi lặp lại nhiều lần như một lời nguyền rủa!',
        'Đừng để tiếng ồn xung quanh nuốt mất giọng nói yếu ớt của ngươi!',
        'Nói chậm rãi nhưng đầy uy lực để quỷ dữ nghe thấy!',
      ];
    } else {
      return [
        'Nghe đi nghe lại câu mẫu hàng trăm lần để khai sáng tai trần!',
        'Luyện tập từng từ riêng lẻ trước khi cố gắng kết nối chúng!',
        'Hét to và rõ ràng hơn để xua tan bóng tối u ám!',
        'Hãy tìm một nơi cực kỳ yên tĩnh, nơi chỉ có âm vang của ngươi tồn tại!',
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
