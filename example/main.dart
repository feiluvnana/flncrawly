import 'package:flncrawly/flncrawly.dart';

/// A processor that searches for packages on pub.dev and extracts the top 5 results.
class PubSearchProcessor
    extends Processor<Map<String, String>, Request, HtmlResponse> {
  final String query;

  PubSearchProcessor(this.query);

  @override
  List<Request> get seeds => [
    Request(url: Uri.parse('https://pub.dev/packages?q=$query')),
  ];

  @override
  Stream<Result<Map<String, String>, Request>> process(
    HtmlResponse res,
  ) async* {
    // Select all package list items
    final packages = res.$all('.packages .packages-item');

    // Take the top 5
    for (var i = 0; i < 5 && i < packages.length; i++) {
      final pkg = packages.items[i];

      final titleNode = pkg.$('.packages-title a');
      final name = titleNode?.text() ?? 'Unknown';
      final link = titleNode?.attr('href') ?? '';
      final description = pkg.$('.packages-description')?.text() ?? '';

      yield Result.item({
        'name': name,
        'url': res.urljoin(link).toString(),
        'description': description,
      });
    }
  }
}

void main() async {
  // Search for 'http' packages and print the top 5
  final processor = PubSearchProcessor('http');

  final crawler = Crawly<Map<String, String>, Request, HtmlResponse>()
      .processor(processor);

  // We can also add a simple pipeline to print results
  crawler.pipe(
    FunctionalPipeline((item) async {
      print('📦 ${item['name']}');
      print('   🔗 ${item['url']}');
      print('   📝 ${item['description']}\n');
      return item;
    }),
  );

  print('🔎 Searching pub.dev for "${processor.query}"...\n');
  await crawler.run();
}
