import 'dart:async';
import 'package:flncrawly/src/core/engine.dart';

/// Defines how to process, transform, or store extracted items.
/// 
/// Pipelines are executed sequentially for each item yielded by a [Processor].
/// Items can be filtered out by returning `null`.
abstract class Pipeline<T> {
  /// The engine instance running this pipeline.
  late final Engine engine;

  /// Processes an extracted [item].
  /// 
  /// Return the transformed [item] to continue the chain, 
  /// or `null` to drop it.
  FutureOr<T?> handle(T item);

  /// Cleanup logic called when the engine stops.
  void close() {}
}
