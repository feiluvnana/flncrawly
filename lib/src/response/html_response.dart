import 'package:flncrawly/src/response/text_response.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

/// A response containing HTML content, providing powerful query tools.
class HtmlResponse extends TextResponse {
  late final Document _doc = parse(text);

  /// Creates a new [HtmlResponse] instance.
  HtmlResponse({
    required super.url,
    required super.status,
    required super.headers,
    required super.body,
    required super.request,
    required super.meta,
  });

  /// The root selector for this document.
  HtmlSelector get selector => HtmlSelector.document(_doc);

  /// Find a single element matching the given CSS [selector].
  HtmlSelector? $(String selector) => this.selector.$(selector);

  /// Find all elements matching the given CSS [selector].
  HtmlSelectionList $all(String selector) => this.selector.$all(selector);

  /// Find a single element matching the given XPath [expression].
  HtmlSelector? $x(String expression) => selector.$x(expression);

  /// Find all elements matching the given XPath [expression].
  HtmlSelectionList $xall(String expression) => selector.$xall(expression);
}

/// Helper for querying and extracting data from HTML elements.
class HtmlSelector {
  final Element _element;
  final HtmlXPath _xpath;

  HtmlSelector._(this._element) : _xpath = HtmlXPath.node(_element);

  /// Creates a selector for an entire HTML [document].
  factory HtmlSelector.document(Document document) {
    final root = document.documentElement;
    if (root == null) {
      throw StateError('Parsed HTML document has no documentElement.');
    }
    return HtmlSelector._(root);
  }

  /// Creates a selector for a specific HTML [element].
  factory HtmlSelector.element(Element element) => HtmlSelector._(element);

  /// Find a single sub-element matching the CSS [selector].
  HtmlSelector? $(String selector) {
    final element = _element.querySelector(selector);
    return element == null ? null : HtmlSelector.element(element);
  }

  /// Find all sub-elements matching the CSS [selector].
  HtmlSelectionList $all(String selector) {
    return HtmlSelectionList(
      _element.querySelectorAll(selector).map(HtmlSelector.element).toList(),
    );
  }

  /// Find a single node matching the XPath [expression].
  HtmlSelector? $x(String expression) {
    final node = _xpath.query(expression).node?.node;
    return node is Element ? HtmlSelector.element(node) : null;
  }

  /// Find all nodes matching the XPath [expression].
  HtmlSelectionList $xall(String expression) {
    final elements = _xpath
        .query(expression)
        .nodes
        .map((match) => match.node)
        .whereType<Element>()
        .map(HtmlSelector.element)
        .toList();
    return HtmlSelectionList(elements);
  }

  /// Transform the current element into another type using [fn].
  T map<T>(T Function(Element element) fn) => fn(_element);

  /// Get the trimmed text content of the current element.
  String text() => _element.text.trim();

  /// Get the trimmed value of the attribute with the given [name].
  String attr(String name) => (_element.attributes[name] ?? '').trim();

  /// Get the inner HTML content of the current element.
  String innner() => _element.innerHtml;

  /// Get the outer HTML content of the current element.
  String outer() => _element.outerHtml;

  /// Get the tag name of the current element.
  String tag() => _element.localName ?? '';
}

/// A list of [HtmlSelector]s, providing batch extraction methods.
final class HtmlSelectionList {
  final List<HtmlSelector> _items;

  /// Creates a new [HtmlSelectionList].
  const HtmlSelectionList(this._items);

  /// The number of selected items.
  int get length => _items.length;

  /// The underlying list of selectors.
  List<HtmlSelector> get items => _items;

  /// Transform each selected element using [fn].
  List<T> map<T>(T Function(HtmlSelector) fn) => _items.map(fn).toList();

  /// Extract the trimmed text content of all selected elements.
  List<String> text() => map((el) => el.text());

  /// Extract the trimmed value of the attribute [name] for all selected elements.
  List<String> attr(String name) => map((element) => element.attr(name));

  /// Extract the inner HTML content of all selected elements.
  List<String> inner() => map((element) => element.innner());

  /// Extract the outer HTML content of all selected elements.
  List<String> outer() => map((element) => element.outer());
}
