import 'dart:convert';

import 'package:flncrawly/src/response/text_response.dart';
import 'package:jmespath/jmespath.dart';
import 'package:json_path/json_path.dart';

/// A response containing JSON content, providing JSONPath query tools.
class JsonResponse extends TextResponse {
  /// Creates a new [JsonResponse] instance.
  JsonResponse({
    required super.url,
    required super.status,
    required super.headers,
    required super.body,
    required super.request,
    required super.meta,
  });

  /// The root JSON selector for this response.
  JsonSelector get selector => JsonSelector(jsonDecode(text));

  /// Find a single value matching the given JSONPath [selector].
  JsonSelector? $path(String selector) => this.selector.$path(selector);

  /// Find all values matching the given JSONPath [selector].
  JsonSelectionList $pathall(String selector) =>
      this.selector.$pathall(selector);

  /// Find a single value matching the given JMESPath [selector].
  JsonSelector? $jmes(String selector) => this.selector.$jmes(selector);

  /// Find all values matching the given JMESPath [selector].
  JsonSelectionList $jmesall(String selector) =>
      this.selector.$jmesall(selector);

  /// Get the raw decoded JSON data.
  dynamic data() => selector.raw();
}

/// Helper for querying and extracting data from JSON objects.
final class JsonSelector {
  final dynamic _value;

  /// Creates a new selector for the given raw JSON [_value].
  const JsonSelector(this._value);

  /// Find a single sub-value matching the JSONPath [expr].
  JsonSelector? $path(String expr) {
    final match = JsonPath(expr).read(_value).firstOrNull;
    return match == null ? null : JsonSelector(match.value);
  }

  /// Find all sub-values matching the JSONPath [expr].
  JsonSelectionList $pathall(String expr) {
    final values = JsonPath(
      expr,
    ).read(_value).map((m) => JsonSelector(m.value)).toList();
    return JsonSelectionList(values);
  }

  /// Find a single sub-value matching the JMESPath [expr].
  JsonSelector? $jmes(String expr) {
    final result = search(expr, _value);
    return result == null ? null : JsonSelector(result);
  }

  /// Find all sub-values matching the JMESPath [expr].
  JsonSelectionList $jmesall(String expr) {
    final result = search(expr, _value);
    if (result is List) {
      return JsonSelectionList(result.map((m) => JsonSelector(m)).toList());
    }
    return JsonSelectionList(result == null ? [] : [JsonSelector(result)]);
  }

  /// Transform the current JSON value into another type using [fn].
  T map<T>(T Function(dynamic value) fn) => fn(_value);

  /// Get the string representation of the current value, trimmed.
  String text() => _value?.toString().trim() ?? '';

  /// Get the raw underlying value at this node.
  dynamic raw() => _value;
}

/// A list of [JsonSelector]s, providing batch extraction methods.
final class JsonSelectionList {
  final List<JsonSelector> _items;

  /// Creates a new [JsonSelectionList].
  const JsonSelectionList(this._items);

  /// The number of selected items.
  int get length => _items.length;

  /// The underlying list of selectors.
  List<JsonSelector> get items => _items;

  /// Transform each selected JSON node using [fn].
  List<T> map<T>(T Function(JsonSelector) fn) => _items.map(fn).toList();

  /// Extract the string representation of all selected items.
  List<String> text() => map((value) => value.text());

  /// Extract the raw underlying values for all selected items.
  List<dynamic> raw() => map((value) => value.raw());
}
