/// Offline content entity
///
/// Represents content that is available offline.
class OfflineContent {
  final String contentId;
  final String contentType; // 'lesson', 'audio', 'image'
  final String localPath;
  final int sizeBytes;
  final DateTime downloadedAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;

  const OfflineContent({
    required this.contentId,
    required this.contentType,
    required this.localPath,
    required this.sizeBytes,
    required this.downloadedAt,
    this.expiresAt,
    this.metadata = const {},
  });

  OfflineContent copyWith({
    String? contentId,
    String? contentType,
    String? localPath,
    int? sizeBytes,
    DateTime? downloadedAt,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) {
    return OfflineContent(
      contentId: contentId ?? this.contentId,
      contentType: contentType ?? this.contentType,
      localPath: localPath ?? this.localPath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OfflineContent &&
        other.contentId == contentId &&
        other.contentType == contentType &&
        other.localPath == localPath &&
        other.sizeBytes == sizeBytes &&
        other.downloadedAt == downloadedAt &&
        other.expiresAt == expiresAt;
  }

  @override
  int get hashCode {
    return contentId.hashCode ^
        contentType.hashCode ^
        localPath.hashCode ^
        sizeBytes.hashCode ^
        downloadedAt.hashCode ^
        expiresAt.hashCode;
  }

  @override
  String toString() {
    return 'OfflineContent(contentId: $contentId, contentType: $contentType, '
        'localPath: $localPath, sizeBytes: $sizeBytes, '
        'downloadedAt: $downloadedAt, expiresAt: $expiresAt)';
  }
}

/// Offline availability info
class OfflineAvailability {
  final bool isAvailable;
  final int totalLessons;
  final int downloadedLessons;
  final int totalSizeBytes;
  final int usedSizeBytes;
  final DateTime? lastDownloadAt;

  const OfflineAvailability({
    required this.isAvailable,
    required this.totalLessons,
    required this.downloadedLessons,
    required this.totalSizeBytes,
    required this.usedSizeBytes,
    this.lastDownloadAt,
  });

  double get downloadProgress {
    if (totalLessons == 0) return 0.0;
    return downloadedLessons / totalLessons;
  }

  double get storageUsagePercent {
    if (totalSizeBytes == 0) return 0.0;
    return usedSizeBytes / totalSizeBytes;
  }

  @override
  String toString() {
    return 'OfflineAvailability(isAvailable: $isAvailable, '
        'totalLessons: $totalLessons, downloadedLessons: $downloadedLessons, '
        'totalSizeBytes: $totalSizeBytes, usedSizeBytes: $usedSizeBytes, '
        'lastDownloadAt: $lastDownloadAt)';
  }
}
