import 'package:demon_teach/core/utils/result.dart';

/// Base class for all use cases
/// 
/// [Type] is the return type
/// [Params] is the parameter type
abstract class UseCase<Type, Params> {
  Future<Result<Type>> call(Params params);
}

/// Use case with no parameters
abstract class NoParamsUseCase<Type> {
  Future<Result<Type>> call();
}

/// Synchronous use case
abstract class SyncUseCase<Type, Params> {
  Result<Type> call(Params params);
}

/// Synchronous use case with no parameters
abstract class NoParamsSyncUseCase<Type> {
  Result<Type> call();
}
