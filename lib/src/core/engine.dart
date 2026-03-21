import 'package:flncrawly/src/core/dispatcher.dart';
import 'package:flncrawly/src/core/downloader.dart';
import 'package:flncrawly/src/core/pipeline.dart';
import 'package:flncrawly/src/core/processor.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// The core orchestrator that drives the entire crawling process.
class Engine<T, Req extends Request, Res extends Response> {
  final Dispatcher<Req> dispatcher;
  final Downloader<Req, Res> downloader;
  final Processor<T, Req, Res> processor;
  final List<Pipeline<T>> pipelines;

  void Function(String msg) log = print;
  final Stats stats = Stats();

  Engine({
    required this.dispatcher,
    required this.downloader,
    required this.processor,
    required this.pipelines,
  }) {
    dispatcher.engine = this;
    downloader.engine = this;
    processor.engine = this;
    for (var p in pipelines) {
      p.engine = this;
    }
  }

  final List<Future<void>> _active = [];

  /// Starts the engine using provided seeds or processor's defaults.
  Future<void> start({List<Req>? seeds}) async {
    final startSeeds = seeds ?? processor.seeds;
    stats.start = DateTime.now();

    log('Starting crawl with ${startSeeds.length} seeds');

    final done = dispatcher.requests.forEach((req) {
      final task = _run(req);
      _active.add(task);
      task.whenComplete(() => _active.remove(task));
    });

    for (var seed in startSeeds) {
      dispatcher.push(seed);
    }

    await done;
    await Future.wait(_active);

    stats.end = DateTime.now();
    log('Engine stopped. $stats');
  }

  /// Programmatically stops the engine by closing the dispatcher.
  void stop() {
    log('Stopping engine...');
    dispatcher.close();
  }

  Future<void> _run(Req req) async {
    stats.requests++;

    try {
      var res = await downloader.download(req);
      stats.successes++;

      for (final m in processor.middlewares) {
        res = await m.handle(res);
      }

      await for (final r in processor.process(res)) {
        switch (r) {
          case Item<T, Req>(:final item):
            await _feed(item);
          case Follow<T, Req>(:final request):
            dispatcher.push(request);
          case Retry<T, Req>(:final request):
            dispatcher.retry(request);
          case Error<T, Req>(:final error, :final stackTrace):
            stats.failures++;
            log('Error: $error');
            if (stackTrace != null) log(stackTrace.toString());
          case Finish<T, Req>():
            dispatcher.close();
        }
      }
    } catch (e, s) {
      stats.failures++;
      log('Execution error: $e\n$s');
    } finally {
      dispatcher.complete(req);
    }
  }

  Future<void> _feed(T item) async {
    stats.items++;
    T? current = item;

    for (final p in pipelines) {
      if (current == null) break;
      current = await p.handle(current);
    }
  }
}

/// A collector for crawl performance metrics.
class Stats {
  int requests = 0;
  int successes = 0;
  int failures = 0;
  int items = 0;

  DateTime? start;
  DateTime? end;

  Duration? get duration =>
      (start != null && end != null) ? end!.difference(start!) : null;

  @override
  String toString() =>
      'Stats(reqs: $requests, ok: $successes, fail: $failures, items: $items, time: ${duration?.inSeconds}s)';
}
