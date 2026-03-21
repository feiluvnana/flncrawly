import 'package:flncrawly/src/pipeline/pipeline.dart';

/// A pipeline that delegates handling to a function.
class FunctionalPipeline<T> extends Pipeline<T> {
  final Future<T?> Function(T data) _handler;
  final void Function()? _closer;

  FunctionalPipeline(this._handler, [this._closer]);

  @override
  Future<T?> handle(T data) => _handler(data);

  @override
  void close() => _closer?.call();
}
