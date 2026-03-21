import 'package:flncrawly/src/core/engine.dart';

abstract class Pipeline<T> {
  /// The engine instance running this pipeline.
  late final Engine engine;

  /// Handle an item. Returns null to drop the item.
  Future<T?> handle(T data);
}

/// A simple pipeline that delegates handling to a function.
class FunctionalPipeline<T> extends Pipeline<T> {
  final Future<T?> Function(T data) _handler;

  FunctionalPipeline(this._handler);

  @override
  Future<T?> handle(T data) => _handler(data);
}
