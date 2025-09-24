// lib/src/services/usm_custom_merge_strategies.dart

import 'dart:math' as math;

import 'usm_enhanced_conflict_resolver.dart';

/// Array merge strategy for handling list conflicts
class ArrayMergeStrategy implements CustomMergeStrategy {
  @override
  String get name => 'ArrayMerge';

  @override
  dynamic mergeValues(
    String fieldName,
    dynamic localValue,
    dynamic remoteValue,
    Map<String, dynamic> context,
  ) {
    if (localValue is! List || remoteValue is! List) {
      // Not lists, return remote value as fallback
      return remoteValue;
    }

    final localList = List<dynamic>.from(localValue);
    final remoteList = List<dynamic>.from(remoteValue);

    // Determine merge strategy based on field characteristics
    if (_isIdList(localList) || _isIdList(remoteList)) {
      return _mergeIdLists(localList, remoteList);
    } else if (_isTimestampOrderedList(localList) ||
        _isTimestampOrderedList(remoteList)) {
      return _mergeTimestampOrderedLists(localList, remoteList);
    } else {
      return _mergeGenericLists(localList, remoteList);
    }
  }

  @override
  double getConfidenceScore(
      String fieldName, dynamic localValue, dynamic remoteValue) {
    if (localValue is! List || remoteValue is! List) {
      return 0.1; // Low confidence for non-list values
    }

    final localList = localValue;
    final remoteList = remoteValue;

    // Higher confidence for structured lists
    if (_isIdList(localList) || _isIdList(remoteList)) {
      return 0.9;
    } else if (_isTimestampOrderedList(localList) ||
        _isTimestampOrderedList(remoteList)) {
      return 0.8;
    } else {
      return 0.6; // Medium confidence for generic lists
    }
  }

  @override
  bool validateMergedValue(dynamic mergedValue, Map<String, dynamic> context) {
    return mergedValue is List;
  }

  bool _isIdList(List<dynamic> list) {
    if (list.isEmpty) return false;

    return list.every((item) {
      if (item is String) {
        // Check if it looks like an ID (UUID-like or starts with common prefixes)
        return item.length >= 8 &&
            (item.contains('-') ||
                item.startsWith('id_') ||
                item.startsWith('user_') ||
                item.startsWith('org_'));
      }
      return false;
    });
  }

  bool _isTimestampOrderedList(List<dynamic> list) {
    if (list.length < 2) return false;

    // Check if list contains objects with timestamp fields
    return list.every((item) {
      if (item is Map<String, dynamic>) {
        return item.containsKey('timestamp') ||
            item.containsKey('createdAt') ||
            item.containsKey('updatedAt');
      }
      return false;
    });
  }

  List<dynamic> _mergeIdLists(
      List<dynamic> localList, List<dynamic> remoteList) {
    // Union merge for ID lists (no duplicates)
    final merged = <dynamic>{};
    merged.addAll(localList);
    merged.addAll(remoteList);
    return merged.toList();
  }

  List<dynamic> _mergeTimestampOrderedLists(
      List<dynamic> localList, List<dynamic> remoteList) {
    final merged = <Map<String, dynamic>>[];

    // Convert to maps for easier processing
    final localMaps = localList.cast<Map<String, dynamic>>();
    final remoteMaps = remoteList.cast<Map<String, dynamic>>();

    // Merge by timestamp, keeping most recent versions
    final itemsById = <String, Map<String, dynamic>>{};

    for (final item in localMaps) {
      final id = item['id']?.toString() ?? item.hashCode.toString();
      itemsById[id] = item;
    }

    for (final item in remoteMaps) {
      final id = item['id']?.toString() ?? item.hashCode.toString();
      final existing = itemsById[id];

      if (existing != null) {
        // Compare timestamps
        final existingTime = _extractTimestamp(existing);
        final remoteTime = _extractTimestamp(item);

        if (remoteTime != null &&
            existingTime != null &&
            remoteTime.isAfter(existingTime)) {
          itemsById[id] = item;
        }
      } else {
        itemsById[id] = item;
      }
    }

    merged.addAll(itemsById.values);

    // Sort by timestamp
    merged.sort((a, b) {
      final timeA = _extractTimestamp(a);
      final timeB = _extractTimestamp(b);

      if (timeA != null && timeB != null) {
        return timeA.compareTo(timeB);
      }
      return 0;
    });

    return merged;
  }

  List<dynamic> _mergeGenericLists(
      List<dynamic> localList, List<dynamic> remoteList) {
    // For generic lists, combine and remove duplicates
    final merged = <dynamic>[];
    final seen = <dynamic>{};

    // Add local items first
    for (final item in localList) {
      if (!seen.contains(item)) {
        merged.add(item);
        seen.add(item);
      }
    }

    // Add remote items that aren't duplicates
    for (final item in remoteList) {
      if (!seen.contains(item)) {
        merged.add(item);
        seen.add(item);
      }
    }

    return merged;
  }

  DateTime? _extractTimestamp(Map<String, dynamic> item) {
    for (final field in ['timestamp', 'createdAt', 'updatedAt']) {
      final value = item[field];
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          // Continue to next field
        }
      } else if (value is DateTime) {
        return value;
      }
    }
    return null;
  }
}

/// Numeric merge strategy for handling numerical conflicts
class NumericMergeStrategy implements CustomMergeStrategy {
  @override
  String get name => 'NumericMerge';

  @override
  dynamic mergeValues(
    String fieldName,
    dynamic localValue,
    dynamic remoteValue,
    Map<String, dynamic> context,
  ) {
    final localNum = _toNumber(localValue);
    final remoteNum = _toNumber(remoteValue);

    if (localNum == null || remoteNum == null) {
      return remoteValue; // Fallback to remote if not numeric
    }

    // Apply field-specific logic
    if (fieldName.toLowerCase().contains('count') ||
        fieldName.toLowerCase().contains('total') ||
        fieldName.toLowerCase().contains('sum')) {
      // For counts/totals, use the maximum value
      return math.max(localNum, remoteNum);
    } else if (fieldName.toLowerCase().contains('rate') ||
        fieldName.toLowerCase().contains('percent') ||
        fieldName.toLowerCase().contains('ratio')) {
      // For rates/percentages, use average
      return (localNum + remoteNum) / 2;
    } else if (fieldName.toLowerCase().contains('version') ||
        fieldName.toLowerCase().contains('revision')) {
      // For versions, use the higher version
      return math.max(localNum, remoteNum);
    } else {
      // Default: use remote value for safety
      return remoteNum;
    }
  }

  @override
  double getConfidenceScore(
      String fieldName, dynamic localValue, dynamic remoteValue) {
    final localNum = _toNumber(localValue);
    final remoteNum = _toNumber(remoteValue);

    if (localNum == null || remoteNum == null) {
      return 0.1; // Low confidence for non-numeric values
    }

    // Higher confidence for well-known numeric field patterns
    if (fieldName.toLowerCase().contains('count') ||
        fieldName.toLowerCase().contains('total') ||
        fieldName.toLowerCase().contains('version')) {
      return 0.9;
    } else {
      return 0.7; // Good confidence for general numeric fields
    }
  }

  @override
  bool validateMergedValue(dynamic mergedValue, Map<String, dynamic> context) {
    return _toNumber(mergedValue) != null;
  }

  double? _toNumber(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}

/// Text merge strategy for handling string conflicts
class TextMergeStrategy implements CustomMergeStrategy {
  @override
  String get name => 'TextMerge';

  @override
  dynamic mergeValues(
    String fieldName,
    dynamic localValue,
    dynamic remoteValue,
    Map<String, dynamic> context,
  ) {
    if (localValue is! String || remoteValue is! String) {
      return remoteValue; // Fallback to remote
    }

    final localText = localValue;
    final remoteText = remoteValue;

    // Apply field-specific logic
    if (fieldName.toLowerCase().contains('description') ||
        fieldName.toLowerCase().contains('comment') ||
        fieldName.toLowerCase().contains('note')) {
      // For descriptive text, merge intelligently
      return _mergeDescriptiveText(localText, remoteText);
    } else if (fieldName.toLowerCase().contains('name') ||
        fieldName.toLowerCase().contains('title')) {
      // For names/titles, prefer the longer, more descriptive one
      return localText.length > remoteText.length ? localText : remoteText;
    } else if (fieldName.toLowerCase().contains('email') ||
        fieldName.toLowerCase().contains('url') ||
        fieldName.toLowerCase().contains('phone')) {
      // For structured text, prefer remote (assume it's more up-to-date)
      return remoteText;
    } else {
      // Default: use remote value
      return remoteText;
    }
  }

  @override
  double getConfidenceScore(
      String fieldName, dynamic localValue, dynamic remoteValue) {
    if (localValue is! String || remoteValue is! String) {
      return 0.1; // Low confidence for non-string values
    }

    final localText = localValue;
    final remoteText = remoteValue;

    // Calculate similarity score
    final similarity = _calculateSimilarity(localText, remoteText);

    // Higher confidence for similar text
    if (similarity > 0.8) {
      return 0.9;
    } else if (similarity > 0.5) {
      return 0.7;
    } else {
      return 0.4; // Lower confidence for very different text
    }
  }

  @override
  bool validateMergedValue(dynamic mergedValue, Map<String, dynamic> context) {
    return mergedValue is String && mergedValue.isNotEmpty;
  }

  String _mergeDescriptiveText(String localText, String remoteText) {
    // If one is empty, use the other
    if (localText.isEmpty) return remoteText;
    if (remoteText.isEmpty) return localText;

    // If they're similar, use the longer one
    final similarity = _calculateSimilarity(localText, remoteText);
    if (similarity > 0.8) {
      return localText.length > remoteText.length ? localText : remoteText;
    }

    // If they're different, combine them
    if (!localText.endsWith('.') &&
        !localText.endsWith('!') &&
        !localText.endsWith('?')) {
      return '$localText. $remoteText';
    } else {
      return '$localText $remoteText';
    }
  }

  double _calculateSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    // Simple similarity calculation using common words
    final wordsA = a.toLowerCase().split(RegExp(r'\W+'));
    final wordsB = b.toLowerCase().split(RegExp(r'\W+'));

    final setA = wordsA.toSet();
    final setB = wordsB.toSet();

    final intersection = setA.intersection(setB);
    final union = setA.union(setB);

    return union.isEmpty ? 0.0 : intersection.length / union.length;
  }
}

/// JSON object merge strategy for handling complex object conflicts
class JsonObjectMergeStrategy implements CustomMergeStrategy {
  @override
  String get name => 'JsonObjectMerge';

  @override
  dynamic mergeValues(
    String fieldName,
    dynamic localValue,
    dynamic remoteValue,
    Map<String, dynamic> context,
  ) {
    if (localValue is! Map<String, dynamic> ||
        remoteValue is! Map<String, dynamic>) {
      return remoteValue; // Fallback to remote
    }

    final localMap = Map<String, dynamic>.from(localValue);
    final remoteMap = Map<String, dynamic>.from(remoteValue);

    // Deep merge objects
    return _deepMerge(localMap, remoteMap);
  }

  @override
  double getConfidenceScore(
      String fieldName, dynamic localValue, dynamic remoteValue) {
    if (localValue is! Map<String, dynamic> ||
        remoteValue is! Map<String, dynamic>) {
      return 0.1; // Low confidence for non-object values
    }

    final localMap = localValue;
    final remoteMap = remoteValue;

    // Calculate structural similarity
    final localKeys = localMap.keys.toSet();
    final remoteKeys = remoteMap.keys.toSet();
    final commonKeys = localKeys.intersection(remoteKeys);
    final allKeys = localKeys.union(remoteKeys);

    final structuralSimilarity =
        allKeys.isEmpty ? 0.0 : commonKeys.length / allKeys.length;

    // Higher confidence for similar structure
    return math.max(0.6, structuralSimilarity * 0.9);
  }

  @override
  bool validateMergedValue(dynamic mergedValue, Map<String, dynamic> context) {
    return mergedValue is Map<String, dynamic>;
  }

  Map<String, dynamic> _deepMerge(
      Map<String, dynamic> local, Map<String, dynamic> remote) {
    final merged =
        Map<String, dynamic>.from(remote); // Start with remote as base

    for (final entry in local.entries) {
      final key = entry.key;
      final localValue = entry.value;
      final remoteValue = remote[key];

      if (remoteValue == null) {
        // Key only exists locally
        merged[key] = localValue;
      } else if (localValue is Map<String, dynamic> &&
          remoteValue is Map<String, dynamic>) {
        // Both are objects, merge recursively
        merged[key] = _deepMerge(localValue, remoteValue);
      } else if (localValue is List && remoteValue is List) {
        // Both are arrays, merge using array strategy
        final arrayStrategy = ArrayMergeStrategy();
        merged[key] =
            arrayStrategy.mergeValues(key, localValue, remoteValue, {});
      } else {
        // Different types or values, prefer remote for safety
        merged[key] = remoteValue;
      }
    }

    return merged;
  }
}

/// Boolean merge strategy for handling boolean conflicts
class BooleanMergeStrategy implements CustomMergeStrategy {
  @override
  String get name => 'BooleanMerge';

  @override
  dynamic mergeValues(
    String fieldName,
    dynamic localValue,
    dynamic remoteValue,
    Map<String, dynamic> context,
  ) {
    if (localValue is! bool || remoteValue is! bool) {
      return remoteValue; // Fallback to remote
    }

    // Apply field-specific logic
    if (fieldName.toLowerCase().contains('active') ||
        fieldName.toLowerCase().contains('enabled') ||
        fieldName.toLowerCase().contains('visible')) {
      // For status flags, prefer true (active state)
      return localValue || remoteValue;
    } else if (fieldName.toLowerCase().contains('deleted') ||
        fieldName.toLowerCase().contains('archived') ||
        fieldName.toLowerCase().contains('disabled')) {
      // For negative flags, prefer true (if either side says it's deleted/disabled)
      return localValue || remoteValue;
    } else if (fieldName.toLowerCase().contains('dirty') ||
        fieldName.toLowerCase().contains('modified')) {
      // For sync flags, prefer true (if either side has changes)
      return localValue || remoteValue;
    } else {
      // Default: use remote value
      return remoteValue;
    }
  }

  @override
  double getConfidenceScore(
      String fieldName, dynamic localValue, dynamic remoteValue) {
    if (localValue is! bool || remoteValue is! bool) {
      return 0.1; // Low confidence for non-boolean values
    }

    // High confidence for well-known boolean field patterns
    if (fieldName.toLowerCase().contains('active') ||
        fieldName.toLowerCase().contains('deleted') ||
        fieldName.toLowerCase().contains('enabled') ||
        fieldName.toLowerCase().contains('dirty')) {
      return 0.95;
    } else {
      return 0.8; // Good confidence for general boolean fields
    }
  }

  @override
  bool validateMergedValue(dynamic mergedValue, Map<String, dynamic> context) {
    return mergedValue is bool;
  }
}

/// Timestamp merge strategy for handling date/time conflicts
class TimestampMergeStrategy implements CustomMergeStrategy {
  @override
  String get name => 'TimestampMerge';

  @override
  dynamic mergeValues(
    String fieldName,
    dynamic localValue,
    dynamic remoteValue,
    Map<String, dynamic> context,
  ) {
    final localTime = _parseTimestamp(localValue);
    final remoteTime = _parseTimestamp(remoteValue);

    if (localTime == null && remoteTime == null) {
      return remoteValue;
    } else if (localTime == null) {
      return remoteValue;
    } else if (remoteTime == null) {
      return localValue;
    }

    // Apply field-specific logic
    if (fieldName.toLowerCase().contains('created')) {
      // For creation timestamps, use the older one
      return localTime.isBefore(remoteTime) ? localValue : remoteValue;
    } else if (fieldName.toLowerCase().contains('updated') ||
        fieldName.toLowerCase().contains('modified') ||
        fieldName.toLowerCase().contains('synced')) {
      // For update timestamps, use the newer one
      return localTime.isAfter(remoteTime) ? localValue : remoteValue;
    } else {
      // Default: use the newer timestamp
      return localTime.isAfter(remoteTime) ? localValue : remoteValue;
    }
  }

  @override
  double getConfidenceScore(
      String fieldName, dynamic localValue, dynamic remoteValue) {
    final localTime = _parseTimestamp(localValue);
    final remoteTime = _parseTimestamp(remoteValue);

    if (localTime == null || remoteTime == null) {
      return 0.1; // Low confidence for non-timestamp values
    }

    // High confidence for timestamp fields
    if (fieldName.toLowerCase().contains('created') ||
        fieldName.toLowerCase().contains('updated') ||
        fieldName.toLowerCase().contains('timestamp')) {
      return 0.95;
    } else {
      return 0.7; // Good confidence for other date-like fields
    }
  }

  @override
  bool validateMergedValue(dynamic mergedValue, Map<String, dynamic> context) {
    return _parseTimestamp(mergedValue) != null;
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
