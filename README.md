# 🕸️ flncrawly

A robust, fluent, and **Scrapy-inspired** web crawling framework for Dart. Built for developers who love concise naming, type safety, and powerful extraction tools.

## 🚀 Key Features

*   **Scrapy-Inspired API**: Familiar concepts like Processors, Dispatchers, and Result yielding.
*   **Fluent & Concise**: A developer-friendly DSL for configuring and running crawls.
*   **Powerful Selectors**: Built-in support for CSS and XPath selectors across HTML, XML, and JSON.
*   **Automatic URL Resolution**: Use `absUrl()` on any selector node to resolve links against the response URL.
*   **Smart Stats**: Built-in tracking for requests, successes, failures, and item counts.
*   **User-Agent Presets**: Easily rotate or set common browser User-Agents.
*   **Modular Architecture**: Easily swap or extend the Dispatcher, Downloader, or Pipelines.

## 📦 Installation

Add `flncrawly` to your `pubspec.yaml`:

```yaml
dependencies:
  flncrawly: ^1.0.0
```

## 🛠️ Usage Example

Define your `Processor` and run it with the fluent `Crawly` interface.

```dart
import 'package:flncrawly/flncrawly.dart';

// 1. Define your data model
class Book {
  final String title;
  final String price;
  final String url;
  Book(this.title, this.price, this.url);
  @override
  String toString() => '$title ($price) -> $url';
}

// 2. Define your Processor
class BookProcessor extends Processor<Book, HtmlResponse, Request> {
  // Define entry points
  @override
  List<Request> get seeds => [
        Request(
          url: Uri.parse('http://books.toscrape.com/'),
          headers: {'User-Agent': UserAgents.random()},
        ),
      ];

  @override
  Stream<Result<Book, Request>> process(HtmlResponse res) async* {
    final bookNodes = res.$all('.product_pod');
    
    for (final node in bookNodes.map((e) => e)) {
      yield Result.item(Book(
        node.$('h3 a')?.attr('title') ?? '',
        node.$('.price_color')?.text() ?? '',
        node.$('h3 a')?.absUrl('href') ?? '', // Resolves relative URL
      ));
    }

    // Easy link following
    final nextPath = res.$('.next a')?.attr('href');
    if (nextPath != null) {
      yield Result.follow(res.follow(nextPath));
    }
  }
}

void main() async {
  // 3. Run the crawl with the fluent API
  await Crawly<Book, Request, HtmlResponse>()
      .run(BookProcessor());
  
  // The engine automatically logs stats at the end:
  // Engine stopped. Stats(reqs: 5, ok: 5, fail: 0, items: 100, time: 12s)
}
```

## 🧩 Core Concepts

### Processor
The core logic of your crawler. It defines **where** to start (`seeds`) and **how** to extract data (`process`).

### Result (Yielding)
Processors return a `Stream<Result>`, which can yield:
*   `Result.item(data)`: Emits an extracted item to the pipelines.
*   `Result.follow(request)`: Schedules a new request.
*   `Result.retry(request)`: Retries a failed request.
*   `Result.error(e)`: Reports an error to the engine.

### Selectors (Extraction)
*   **HTML**: `res.$('.selector')`, `res.$x('//expression')`
*   **XML**: `res.$x('//expression')`
*   **JSON**: `res.$j('$.path')` (JSONPath) or `res.$m('path.to.value')` (JMESPath)

Use `.absUrl('attrName')` on any selector to resolve relative paths into absolute URLs automatically.

### Monitoring & Logging
The `Engine` automatically tracks statistics and provides a customizable logger:

```dart
final engine = Crawly<MyItem>()
    .build();

engine.log = (msg) => myCustomLogger.info(msg);
print(engine.stats.items); // Access stats programmatically
```

## ⚙️ Advanced Configuration

`Crawly` allows you to customize every aspect:

```dart
final crawler = Crawly<MyItem>()
    .dispatcher(DefaultDispatcher(maxConcurrent: 5, maxRetries: 3))
    .downloader(MyProxyDownloader())
    .use(SaveToDatabasePipeline())
    .build();
```

---

Built with ❤️ for the Dart community.
