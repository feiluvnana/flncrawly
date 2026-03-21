import 'package:flncrawly/src/response/text_response.dart';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

/// A response containing XML content, providing powerful query tools.
class XmlResponse extends TextResponse {
  late final XmlDocument _doc = XmlDocument.parse(text);

  /// Creates a new [XmlResponse] instance.
  XmlResponse({
    required super.url,
    required super.status,
    required super.headers,
    required super.body,
    required super.request,
    required super.meta,
  });

  /// The root selector for this document.
  XmlSelector get selector => XmlSelector.document(_doc);

  /// Find a single node matching the given XPath [expression].
  XmlSelector? $x(String expression) => selector.$x(expression);

  /// Find all nodes matching the given XPath [expression].
  XmlSelectionList $xall(String expression) => selector.$xall(expression);
}

/// Helper for querying and extracting data from XML nodes.
class XmlSelector {
  final XmlNode _node;

  XmlSelector._(this._node);

  /// Creates a selector for an entire XML [document].
  factory XmlSelector.document(XmlDocument document) => XmlSelector._(document);

  /// Creates a selector for a specific XML [node].
  factory XmlSelector.node(XmlNode node) => XmlSelector._(node);

  /// Find a single node matching the XPath [expression].
  XmlSelector? $x(String expression) {
    // ignore: experimental_member_use
    final match = _node.xpath(expression);
    return match.isEmpty ? null : XmlSelector.node(match.first);
  }

  /// Find all nodes matching the XPath [expression].
  XmlSelectionList $xall(String expression) {
    final nodes = _node
        // ignore: experimental_member_use
        .xpath(expression)
        .map((match) => XmlSelector.node(match))
        .toList();
    return XmlSelectionList(nodes);
  }

  /// Transform the current node into another type using [fn].
  T map<T>(T Function(XmlNode node) fn) => fn(_node);

  /// Get the trimmed text content of the current node.
  String text() => _node.innerText.trim();

  /// Get the XML content of the current node.
  String xml() => _node.toXmlString();

  /// Get the trimmed value of the attribute with the given [name].
  String attr(String name) {
    final node = _node;
    if (node is XmlElement) {
      return node.getAttribute(name)?.trim() ?? '';
    }
    return '';
  }
}

/// A list of [XmlSelector]s, providing batch extraction methods.
final class XmlSelectionList {
  final List<XmlSelector> _items;

  /// Creates a new [XmlSelectionList].
  const XmlSelectionList(this._items);

  /// The number of selected items.
  int get length => _items.length;

  /// The underlying list of selectors.
  List<XmlSelector> get items => _items;

  /// Transform each selected node using [fn].
  List<T> map<T>(T Function(XmlSelector) fn) => _items.map(fn).toList();

  /// Extract the trimmed text content of all selected elements.
  List<String> text() => map((node) => node.text());

  /// Extract the XML content of all selected elements.
  List<String> xml() => map((node) => node.xml());

  /// Extract the trimmed value of the attribute [name] for all selected nodes.
  List<String> attr(String name) => map((element) => element.attr(name));
}
