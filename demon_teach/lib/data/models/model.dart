/// Base class for all data models (DTOs)
/// 
/// Models are responsible for converting between domain entities and data sources
abstract class Model<T> {
  /// Converts this model to a domain entity
  T toEntity();

  /// Converts this model to JSON
  Map<String, dynamic> toJson();
}
