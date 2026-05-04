/// Sync status entity
///
/// Represents the synchronization status of data.
class SyncStatus {
  final String userId;
  final SyncState state;
  final DateTime? lastSyncAt;
  final DateTime? nextSyncAt;
  final int pendingChanges;
  final Map<String, SyncItemStatus> itemStatuses;
  final String? error;

  const SyncStatus({
    required this.userId,
    required this.state,
    this.lastSyncAt,
    this.nextSyncAt,
    this.pendingChanges = 0,
    this.itemStatuses = const {},
    this.error,
  });

  SyncStatus copyWith({
    String? userId,
    SyncState? state,
    DateTime? lastSyncAt,
    DateTime? nextSyncAt,
    int? pendingChanges,
    Map<String, SyncItemStatus>? itemStatuses,
    String? error,
  }) {
    return SyncStatus(
      userId: userId ?? this.userId,
      state: state ?? this.state,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      nextSyncAt: nextSyncAt ?? this.nextSyncAt,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      itemStatuses: itemStatuses ?? this.itemStatuses,
      error: error ?? this.error,
    );
  }

  bool get isSyncing => state == SyncState.syncing;
  bool get isSynced => state == SyncState.synced;
  bool get hasPendingChanges => pendingChanges > 0;
  bool get hasError => state == SyncState.error;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SyncStatus &&
        other.userId == userId &&
        other.state == state &&
        other.lastSyncAt == lastSyncAt &&
        other.nextSyncAt == nextSyncAt &&
        other.pendingChanges == pendingChanges &&
        other.error == error;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        state.hashCode ^
        lastSyncAt.hashCode ^
        nextSyncAt.hashCode ^
        pendingChanges.hashCode ^
        error.hashCode;
  }

  @override
  String toString() {
    return 'SyncStatus(userId: $userId, state: $state, lastSyncAt: $lastSyncAt, '
        'nextSyncAt: $nextSyncAt, pendingChanges: $pendingChanges, error: $error)';
  }
}

/// Sync state enum
enum SyncState {
  idle,
  syncing,
  synced,
  error,
  offline,
}

/// Extension for SyncState
extension SyncStateExtension on SyncState {
  String get displayName {
    switch (this) {
      case SyncState.idle:
        return 'Idle';
      case SyncState.syncing:
        return 'Syncing';
      case SyncState.synced:
        return 'Synced';
      case SyncState.error:
        return 'Error';
      case SyncState.offline:
        return 'Offline';
    }
  }

  bool get isActive => this == SyncState.syncing;
  bool get isComplete => this == SyncState.synced;
}

/// Sync item status
class SyncItemStatus {
  final String itemId;
  final String itemType; // 'progress', 'performance', 'review', 'content'
  final SyncItemState state;
  final DateTime? lastSyncAt;
  final String? error;

  const SyncItemStatus({
    required this.itemId,
    required this.itemType,
    required this.state,
    this.lastSyncAt,
    this.error,
  });

  SyncItemStatus copyWith({
    String? itemId,
    String? itemType,
    SyncItemState? state,
    DateTime? lastSyncAt,
    String? error,
  }) {
    return SyncItemStatus(
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      state: state ?? this.state,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'SyncItemStatus(itemId: $itemId, itemType: $itemType, '
        'state: $state, lastSyncAt: $lastSyncAt, error: $error)';
  }
}

/// Sync item state enum
enum SyncItemState {
  pending,
  syncing,
  synced,
  conflict,
  error,
}

/// Sync conflict
class SyncConflict<T> {
  final String itemId;
  final String itemType;
  final T localData;
  final T remoteData;
  final DateTime localTimestamp;
  final DateTime remoteTimestamp;
  final ConflictResolutionStrategy strategy;

  const SyncConflict({
    required this.itemId,
    required this.itemType,
    required this.localData,
    required this.remoteData,
    required this.localTimestamp,
    required this.remoteTimestamp,
    required this.strategy,
  });

  /// Resolve conflict based on strategy
  T resolve() {
    switch (strategy) {
      case ConflictResolutionStrategy.useLocal:
        return localData;
      case ConflictResolutionStrategy.useRemote:
        return remoteData;
      case ConflictResolutionStrategy.useMostRecent:
        return localTimestamp.isAfter(remoteTimestamp) ? localData : remoteData;
      case ConflictResolutionStrategy.merge:
        // Merge logic depends on data type
        // Default to most recent
        return localTimestamp.isAfter(remoteTimestamp) ? localData : remoteData;
    }
  }

  @override
  String toString() {
    return 'SyncConflict(itemId: $itemId, itemType: $itemType, '
        'localTimestamp: $localTimestamp, remoteTimestamp: $remoteTimestamp, '
        'strategy: $strategy)';
  }
}

/// Conflict resolution strategy
enum ConflictResolutionStrategy {
  useLocal,
  useRemote,
  useMostRecent,
  merge,
}
