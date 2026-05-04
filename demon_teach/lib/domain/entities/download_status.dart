/// Download status entity
///
/// Represents the download status of a lesson or content item.
class DownloadStatus {
  final String contentId;
  final DownloadState state;
  final double progress; // 0.0 to 1.0
  final int totalBytes;
  final int downloadedBytes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? error;

  const DownloadStatus({
    required this.contentId,
    required this.state,
    this.progress = 0.0,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.startedAt,
    this.completedAt,
    this.error,
  });

  DownloadStatus copyWith({
    String? contentId,
    DownloadState? state,
    double? progress,
    int? totalBytes,
    int? downloadedBytes,
    DateTime? startedAt,
    DateTime? completedAt,
    String? error,
  }) {
    return DownloadStatus(
      contentId: contentId ?? this.contentId,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      error: error ?? this.error,
    );
  }

  bool get isDownloading => state == DownloadState.downloading;
  bool get isCompleted => state == DownloadState.completed;
  bool get isFailed => state == DownloadState.failed;
  bool get isPending => state == DownloadState.pending;
  bool get isPaused => state == DownloadState.paused;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DownloadStatus &&
        other.contentId == contentId &&
        other.state == state &&
        other.progress == progress &&
        other.totalBytes == totalBytes &&
        other.downloadedBytes == downloadedBytes &&
        other.startedAt == startedAt &&
        other.completedAt == completedAt &&
        other.error == error;
  }

  @override
  int get hashCode {
    return contentId.hashCode ^
        state.hashCode ^
        progress.hashCode ^
        totalBytes.hashCode ^
        downloadedBytes.hashCode ^
        startedAt.hashCode ^
        completedAt.hashCode ^
        error.hashCode;
  }

  @override
  String toString() {
    return 'DownloadStatus(contentId: $contentId, state: $state, progress: $progress, '
        'totalBytes: $totalBytes, downloadedBytes: $downloadedBytes, '
        'startedAt: $startedAt, completedAt: $completedAt, error: $error)';
  }
}

/// Download state enum
enum DownloadState {
  pending,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

/// Extension for DownloadState
extension DownloadStateExtension on DownloadState {
  String get displayName {
    switch (this) {
      case DownloadState.pending:
        return 'Pending';
      case DownloadState.downloading:
        return 'Downloading';
      case DownloadState.paused:
        return 'Paused';
      case DownloadState.completed:
        return 'Completed';
      case DownloadState.failed:
        return 'Failed';
      case DownloadState.cancelled:
        return 'Cancelled';
    }
  }

  bool get isActive => this == DownloadState.downloading;
  bool get isTerminal =>
      this == DownloadState.completed ||
      this == DownloadState.failed ||
      this == DownloadState.cancelled;
}
