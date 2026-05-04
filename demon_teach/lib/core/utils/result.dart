import 'package:demon_teach/core/errors/failures.dart';

/// A Result type that represents either a success or a failure
sealed class Result<T> {
  const Result();

  /// Creates a successful result
  factory Result.success(T value) = Success<T>;

  /// Creates a failed result
  factory Result.failure(Failure failure) = Failed<T>;

  /// Returns true if this is a success result
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a failure result
  bool get isFailure => this is Failed<T>;

  /// Gets the value if success, throws if failure
  T get value {
    if (this is Success<T>) {
      return (this as Success<T>).value;
    }
    throw StateError('Cannot get value from a Failed result');
  }

  /// Gets the failure if failed, throws if success
  Failure get failure {
    if (this is Failed<T>) {
      return (this as Failed<T>).failure;
    }
    throw StateError('Cannot get failure from a Success result');
  }

  /// Transforms the value if success, otherwise returns the failure
  Result<R> map<R>(R Function(T value) transform) {
    if (this is Success<T>) {
      return Result.success(transform((this as Success<T>).value));
    }
    return Result.failure((this as Failed<T>).failure);
  }

  /// Executes the appropriate callback based on success or failure
  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).value);
    }
    return failure((this as Failed<T>).failure);
  }
}

/// Represents a successful result
class Success<T> extends Result<T> {
  @override
  final T value;

  const Success(this.value);

  @override
  String toString() => 'Success($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Represents a failed result
class Failed<T> extends Result<T> {
  @override
  final Failure failure;

  const Failed(this.failure);

  @override
  String toString() => 'Failed($failure)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failed<T> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;
}
