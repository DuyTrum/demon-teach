import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/domain/repositories/sync_repository.dart';
import 'package:demon_teach/domain/services/sync_manager.dart';

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  throw UnimplementedError('syncRepositoryProvider must be overridden');
});

final syncManagerProvider = Provider<SyncManager>((ref) {
  final repository = ref.watch(syncRepositoryProvider);
  return SyncManager(repository);
});
