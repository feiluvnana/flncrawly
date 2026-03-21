import 'package:flncrawly/src/processor/middleware/processor_middleware.dart';
import 'package:flncrawly/src/processor/processor.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// A middleware that tracks and limits the depth of a crawl.
/// Depth is stored in `request.meta['depth']`.
class DepthMiddleware<T, Req extends Request, Res extends Response>
    extends ProcessorMiddleware<T, Req, Res> {
  final int maxDepth;
  final bool verbose;

  DepthMiddleware({this.maxDepth = 5, this.verbose = false});

  @override
  Stream<Req> onStart(Stream<Req> seeds) async* {
    await for (final s in seeds) {
      if (!s.meta.containsKey('depth')) {
        yield s.copyWith(meta: {...s.meta, 'depth': 0}) as Req;
      } else {
        yield s;
      }
    }
  }

  @override
  Stream<PCResult<T, Req>> onOutput(
    Res res,
    Stream<PCResult<T, Req>> result,
  ) async* {
    final currentDepth = (res.request.meta['depth'] as int?) ?? 0;

    await for (final r in result) {
      if (r is Follow<T, Req>) {
        final nextDepth = currentDepth + 1;
        if (nextDepth <= maxDepth) {
          yield PCResult.follow(
            r.request.copyWith(meta: {...r.request.meta, 'depth': nextDepth})
                as Req,
          );
        } else if (verbose) {
          print(
            '⚠️ Depth limit ($maxDepth) reached for ${r.request.url}. Dropping.',
          );
        }
      } else {
        yield r;
      }
    }
  }
}
