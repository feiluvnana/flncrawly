import 'dart:async';

import 'package:flncrawly/src/dispatcher/dispatcher.dart';
import 'package:flncrawly/src/downloader/downloader.dart';
import 'package:flncrawly/src/downloader/middleware/downloader_middleware.dart';
import 'package:flncrawly/src/pipeline/pipeline.dart';
import 'package:flncrawly/src/processor/middleware/processor_middleware.dart';
import 'package:flncrawly/src/processor/processor.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// The central orchestrator that drives the entire crawling lifecycle.
///
/// It coordinates between the [Dispatcher] (scheduling), [Downloader] (fetching),
/// and [Processor] (extraction), while enforcing middleware and pipeline logic.
class Engine<T, Req extends Request, Res extends Response> {
  /// The scheduler responsible for managing the request queue and deduplication.
  final Dispatcher<Req> dispatcher;

  /// The network client that fetches responses for each dispatched request.
  final Downloader<Req, Res> downloader;

  /// The spider logic that extracts data and discoveries from responses.
  final Processor<T, Req, Res> processor;

  /// The chain of middlewares that intercept processor inputs and outputs.
  final List<ProcessorMiddleware<T, Req, Res>> processorMiddlewares;

  /// The post-processing chain for items extracted by the processor.
  final List<Pipeline<T>> pipelines;

  /// The logging function used by the engine. Defaults to [print].
  void Function(String msg) log = print;

  /// The real-time statistics of the current crawl session.
  final Stats stats = Stats();

  /// Orchestrates the engine's sub-components.
  Engine({
    required this.dispatcher,
    required this.downloader,
    required this.processor,
    this.processorMiddlewares = const [],
    this.pipelines = const [],
  }) {
    dispatcher.engine = this;
    downloader.engine = this;
    processor.engine = this;
    for (var p in pipelines) {
      p.engine = this;
    }
  }

  final List<Future<void>> _active = [];

  /// Begins the crawling process using the [seeds] list or processor defaults.
  ///
  /// The engine runs until the queue is empty, a [Finish] result is yielded,
  /// or [stop] is called manually.
  Future<void> start({List<Req>? seeds}) async {
    final startSeeds = seeds ?? processor.seeds;
    stats.start = DateTime.now();

    log('Starting crawl with ${startSeeds.length} seeds');

    final done = dispatcher.requests.forEach((req) {
      final task = _run(req);
      _active.add(task);
      task.whenComplete(() => _active.remove(task));
    });

    // Handle Start Requests through Processor Middleware (Top-to-Bottom)
    Stream<Req> seedsStream = Stream.fromIterable(startSeeds);
    for (final m in processorMiddlewares) {
      seedsStream = m.onStart(seedsStream);
    }

    await for (final seed in seedsStream) {
      dispatcher.push(seed);
    }

    try {
      await done;
      await Future.wait(_active);
    } finally {
      close();
    }

    stats.end = DateTime.now();
    log('Engine stopped. $stats');
  }

  /// Commands the engine to stop gracefully by closing the scheduler.
  void stop() {
    log('Stopping engine...');
    dispatcher.close();
  }

  /// Forcibly closes all internal components and releases system resources.
  void close() {
    dispatcher.close();
    downloader.close();
    processor.close();
    for (final m in processorMiddlewares) {
      m.close();
    }
    for (final p in pipelines) {
      p.close();
    }
  }

  Future<void> _run(Req req) async {
    stats.requests++;

    try {
      final downloadResult = await downloader.download(req);

      switch (downloadResult) {
        case ProxyResponse(response: final res):
          stats.successes++;
          await _processResponse(res);
        case RescheduleRequest(request: final r):
          dispatcher.push(r);
        case ReportError(:final error, :final stackTrace):
          stats.failures++;
          log('Downloader Error: $error');
          if (stackTrace != null) log(stackTrace.toString());
        case IgnoreResult():
          return;
        case NextRequest():
          throw StateError('Downloader returned NextRequest');
      }
    } catch (e, s) {
      stats.failures++;
      log('Engine Failure: $e\n$s');
    } finally {
      dispatcher.complete(req);
    }
  }

  Future<void> _processResponse(Res res) async {
    try {
      // 1. Processor Middleware Input chain (Top-to-Bottom)
      for (final m in processorMiddlewares) {
        await m.onInput(res);
      }

      // 2. Call processor.process() and wrap with Output chain (Bottom-to-Top)
      Stream<PCResult<T, Req>> results = processor.process(res);
      for (final m in processorMiddlewares.reversed) {
        results = m.onOutput(res, results);
      }

      // 3. Handle results
      await for (final r in results) {
        await _handleResult(r);
      }
    } catch (e, s) {
      // 4. processException chain (Bottom-to-Top)
      final exceptionResults = await _processException(res, e, s);
      if (exceptionResults != null) {
        await for (final r in exceptionResults) {
          await _handleResult(r);
        }
      } else {
        stats.failures++;
        log('Processor Final Error: $e\n$s');
      }
    }
  }

  Future<Stream<PCResult<T, Req>>?> _processException(
    Res res,
    Object error,
    StackTrace stackTrace,
  ) async {
    for (final m in processorMiddlewares.reversed) {
      final results = m.onException(res, error);
      if (results != null) return results;
    }
    return null;
  }

  Future<void> _handleResult(PCResult<T, Req> r) async {
    switch (r) {
      case Item<T, Req>(:final item):
        await _feed(item);
      case Follow<T, Req>(:final request):
        dispatcher.push(request);
      case Retry<T, Req>(:final request):
        dispatcher.retry(request);
      case Error<T, Req>(:final error, :final stackTrace):
        stats.failures++;
        log('Processor Error: $error');
        if (stackTrace != null) log(stackTrace.toString());
      case Finish<T, Req>():
        dispatcher.close();
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

/// A collection of session-wide crawl performance metrics.
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
