import 'package:flncrawly/src/pipeline/pipeline.dart';

/// A simple pipeline that logs items with a prefix.
class LogPipeline<T> extends Pipeline<T> {
  final String prefix;
  LogPipeline([this.prefix = 'ITEM: ']);

  @override
  Future<T?> handle(T data) async {
    print('$prefix$data');
    return data;
  }
}
