/// Compression Service for Universal Sync Manager
///
/// This service handles compression and decompression of sync payloads
/// to reduce bandwidth usage and improve sync performance, especially
/// important for mobile networks and large datasets.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../config/usm_sync_enums.dart';

/// Service for handling compression and decompression of sync data
///
/// This service supports multiple compression algorithms and provides
/// automatic compression strategy selection based on data characteristics
/// and network conditions.
class SyncCompressionService {
  /// Creates a new sync compression service
  const SyncCompressionService();

  /// Compress data using the specified compression type
  ///
  /// Returns a [CompressionResult] containing the compressed data,
  /// compression ratio, and metadata about the compression operation.
  ///
  /// Example:
  /// ```dart
  /// final data = {'large': 'data' * 1000};
  /// final result = await service.compress(data, CompressionType.gzip);
  /// print('Compression ratio: ${result.compressionRatio}');
  /// ```
  Future<CompressionResult> compress(
    Map<String, dynamic> data,
    CompressionType type, {
    int? level,
    Map<String, dynamic>? metadata,
  }) async {
    final originalData = utf8.encode(jsonEncode(data));
    final originalSize = originalData.length;

    if (type == CompressionType.none) {
      return CompressionResult(
        compressedData: originalData,
        originalSize: originalSize,
        compressedSize: originalSize,
        compressionType: type,
        compressionLevel: 0,
        compressionTime: Duration.zero,
        metadata: metadata ?? {},
      );
    }

    final stopwatch = Stopwatch()..start();
    Uint8List compressedData;

    switch (type) {
      case CompressionType.gzip:
        compressedData = await _compressGzip(originalData, level ?? 6);
        break;
      case CompressionType.brotli:
        // Note: Brotli is not available in dart:io by default
        // This is a placeholder - in production, use a package like 'brotli'
        compressedData = await _compressBrotli(originalData, level ?? 6);
        break;
      case CompressionType.lz4:
        // Note: LZ4 is not available in dart:io by default
        // This is a placeholder - in production, use a package like 'lz4'
        compressedData = await _compressLz4(originalData, level ?? 1);
        break;
      case CompressionType.none:
        compressedData = originalData;
        break;
    }

    stopwatch.stop();

    return CompressionResult(
      compressedData: compressedData,
      originalSize: originalSize,
      compressedSize: compressedData.length,
      compressionType: type,
      compressionLevel: level ?? _getDefaultLevel(type),
      compressionTime: stopwatch.elapsed,
      metadata: metadata ?? {},
    );
  }

  /// Decompress data that was compressed with this service
  ///
  /// Takes a [CompressionResult] and returns the original data.
  /// The compression metadata is used to determine the decompression method.
  Future<Map<String, dynamic>> decompress(CompressionResult result) async {
    if (result.compressionType == CompressionType.none) {
      final jsonString = utf8.decode(result.compressedData);
      return Map<String, dynamic>.from(jsonDecode(jsonString) as Map);
    }

    Uint8List decompressedData;

    switch (result.compressionType) {
      case CompressionType.gzip:
        decompressedData = await _decompressGzip(result.compressedData);
        break;
      case CompressionType.brotli:
        decompressedData = await _decompressBrotli(result.compressedData);
        break;
      case CompressionType.lz4:
        decompressedData = await _decompressLz4(result.compressedData);
        break;
      case CompressionType.none:
        decompressedData = result.compressedData;
        break;
    }

    final jsonString = utf8.decode(decompressedData);
    return Map<String, dynamic>.from(jsonDecode(jsonString) as Map);
  }

  /// Automatically select the best compression type for the given data
  ///
  /// Analyzes the data characteristics and selects the most appropriate
  /// compression algorithm based on size, content type, and performance requirements.
  ///
  /// Factors considered:
  /// - Data size (small data may not benefit from compression)
  /// - Data type (text vs binary-like data)
  /// - Speed requirements (real-time vs batch operations)
  /// - Network conditions (slow networks benefit more from compression)
  CompressionStrategy selectCompressionStrategy(
    Map<String, dynamic> data, {
    NetworkCondition networkCondition = NetworkCondition.good,
    SyncPriority priority = SyncPriority.normal,
    bool favorSpeed = false,
  }) {
    final dataSize = utf8.encode(jsonEncode(data)).length;

    // Small data - compression overhead not worth it
    if (dataSize < 1024) {
      return CompressionStrategy(
        type: CompressionType.none,
        level: 0,
        reason: 'Data too small for compression benefit',
      );
    }

    // Large data with slow network - prioritize compression ratio
    if (dataSize > 100000 && networkCondition == NetworkCondition.limited) {
      return CompressionStrategy(
        type: CompressionType.gzip,
        level: 9, // Maximum compression
        reason: 'Large data with limited network - maximize compression',
      );
    }

    // Real-time or speed-critical operations
    if (priority == SyncPriority.critical || favorSpeed) {
      if (dataSize > 10000) {
        return CompressionStrategy(
          type: CompressionType.lz4,
          level: 1, // Fast compression
          reason: 'Speed-critical operation - fast compression',
        );
      } else {
        return CompressionStrategy(
          type: CompressionType.none,
          level: 0,
          reason: 'Speed-critical with small data - no compression',
        );
      }
    }

    // Analyze data compressibility
    final compressibility = _analyzeCompressibility(data);

    if (compressibility < 0.1) {
      return CompressionStrategy(
        type: CompressionType.none,
        level: 0,
        reason: 'Data appears to be already compressed or binary',
      );
    }

    // Default strategy - balanced compression
    return CompressionStrategy(
      type: CompressionType.gzip,
      level: 6, // Balanced speed/ratio
      reason: 'Balanced compression for general use',
    );
  }

  /// Benchmark different compression algorithms on sample data
  ///
  /// Useful for performance testing and algorithm selection.
  /// Returns results for all supported compression types.
  Future<CompressionBenchmark> benchmark(
    Map<String, dynamic> sampleData, {
    List<CompressionType>? typesToTest,
  }) async {
    final types = typesToTest ??
        [
          CompressionType.none,
          CompressionType.gzip,
          CompressionType.brotli,
          CompressionType.lz4,
        ];

    final results = <CompressionType, CompressionResult>{};

    for (final type in types) {
      try {
        final result = await compress(sampleData, type);
        results[type] = result;
      } catch (e) {
        // Skip types that aren't available
        continue;
      }
    }

    return CompressionBenchmark(
      sampleDataSize: utf8.encode(jsonEncode(sampleData)).length,
      results: results,
      timestamp: DateTime.now(),
    );
  }

  // Private compression implementations

  Future<Uint8List> _compressGzip(Uint8List data, int level) async {
    final codec = GZipCodec(level: level);
    return Uint8List.fromList(codec.encode(data));
  }

  Future<Uint8List> _decompressGzip(Uint8List data) async {
    final codec = GZipCodec();
    return Uint8List.fromList(codec.decode(data));
  }

  Future<Uint8List> _compressBrotli(Uint8List data, int level) async {
    // Placeholder implementation
    // In production, use a proper Brotli package
    // For now, fall back to GZIP
    return _compressGzip(data, level);
  }

  Future<Uint8List> _decompressBrotli(Uint8List data) async {
    // Placeholder implementation
    // In production, use a proper Brotli package
    // For now, fall back to GZIP
    return _decompressGzip(data);
  }

  Future<Uint8List> _compressLz4(Uint8List data, int level) async {
    // Placeholder implementation
    // In production, use a proper LZ4 package
    // For now, fall back to GZIP with low compression for speed
    return _compressGzip(data, 1);
  }

  Future<Uint8List> _decompressLz4(Uint8List data) async {
    // Placeholder implementation
    // In production, use a proper LZ4 package
    // For now, fall back to GZIP
    return _decompressGzip(data);
  }

  int _getDefaultLevel(CompressionType type) {
    switch (type) {
      case CompressionType.none:
        return 0;
      case CompressionType.gzip:
        return 6;
      case CompressionType.brotli:
        return 6;
      case CompressionType.lz4:
        return 1;
    }
  }

  /// Analyze how compressible the data is (0.0 = not compressible, 1.0 = highly compressible)
  double _analyzeCompressibility(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);

    // Simple heuristic: count character frequency
    final charCounts = <String, int>{};
    for (final char in jsonString.split('')) {
      charCounts[char] = (charCounts[char] ?? 0) + 1;
    }

    // Calculate entropy (simplified)
    var entropy = 0.0;
    final length = jsonString.length;

    for (final count in charCounts.values) {
      final probability = count / length;
      if (probability > 0) {
        entropy -= probability * (probability * 8.0); // Simplified log base 2
      }
    }

    // Normalize entropy to 0-1 scale (higher = more compressible)
    final maxEntropy = 8.0; // Maximum entropy for random data
    return (maxEntropy - entropy) / maxEntropy;
  }
}

/// Result of a compression operation
class CompressionResult {
  /// The compressed data
  final Uint8List compressedData;

  /// Size of the original data in bytes
  final int originalSize;

  /// Size of the compressed data in bytes
  final int compressedSize;

  /// Compression algorithm used
  final CompressionType compressionType;

  /// Compression level used
  final int compressionLevel;

  /// Time taken to perform compression
  final Duration compressionTime;

  /// Additional metadata about the compression
  final Map<String, dynamic> metadata;

  /// Creates a new compression result
  const CompressionResult({
    required this.compressedData,
    required this.originalSize,
    required this.compressedSize,
    required this.compressionType,
    required this.compressionLevel,
    required this.compressionTime,
    required this.metadata,
  });

  /// Compression ratio (0.0 = no compression, 1.0 = 100% compression)
  double get compressionRatio {
    if (originalSize == 0) return 0.0;
    return 1.0 - (compressedSize / originalSize);
  }

  /// Space savings in bytes
  int get spaceSavings => originalSize - compressedSize;

  /// Space savings as a percentage
  double get spaceSavingsPercent => compressionRatio * 100;

  /// Whether compression was beneficial
  bool get isWorthwhile => compressionRatio > 0.1; // At least 10% savings

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'compressedData': base64Encode(compressedData),
      'originalSize': originalSize,
      'compressedSize': compressedSize,
      'compressionType': compressionType.name,
      'compressionLevel': compressionLevel,
      'compressionTime': compressionTime.inMilliseconds,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory CompressionResult.fromJson(Map<String, dynamic> json) {
    return CompressionResult(
      compressedData: base64Decode(json['compressedData'] as String),
      originalSize: json['originalSize'] as int,
      compressedSize: json['compressedSize'] as int,
      compressionType: CompressionType.values.firstWhere(
        (type) => type.name == json['compressionType'],
      ),
      compressionLevel: json['compressionLevel'] as int,
      compressionTime: Duration(milliseconds: json['compressionTime'] as int),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }

  @override
  String toString() {
    return 'CompressionResult(${compressionType.name}, '
        'ratio: ${(compressionRatio * 100).toStringAsFixed(1)}%, '
        'time: ${compressionTime.inMilliseconds}ms)';
  }
}

/// Strategy recommendation for compression
class CompressionStrategy {
  /// Recommended compression type
  final CompressionType type;

  /// Recommended compression level
  final int level;

  /// Reason for this recommendation
  final String reason;

  /// Creates a new compression strategy
  const CompressionStrategy({
    required this.type,
    required this.level,
    required this.reason,
  });

  @override
  String toString() {
    return 'CompressionStrategy(${type.name}, level: $level, reason: $reason)';
  }
}

/// Benchmark results comparing compression algorithms
class CompressionBenchmark {
  /// Size of the sample data used for benchmarking
  final int sampleDataSize;

  /// Results for each compression type tested
  final Map<CompressionType, CompressionResult> results;

  /// When this benchmark was performed
  final DateTime timestamp;

  /// Creates a new compression benchmark
  const CompressionBenchmark({
    required this.sampleDataSize,
    required this.results,
    required this.timestamp,
  });

  /// Get the best compression type by ratio
  CompressionType? get bestByRatio {
    CompressionType? best;
    double bestRatio = 0.0;

    for (final entry in results.entries) {
      if (entry.value.compressionRatio > bestRatio) {
        bestRatio = entry.value.compressionRatio;
        best = entry.key;
      }
    }

    return best;
  }

  /// Get the fastest compression type
  CompressionType? get fastestCompression {
    CompressionType? fastest;
    Duration fastestTime = const Duration(days: 1);

    for (final entry in results.entries) {
      if (entry.value.compressionTime < fastestTime) {
        fastestTime = entry.value.compressionTime;
        fastest = entry.key;
      }
    }

    return fastest;
  }

  /// Get a balanced recommendation (good ratio + reasonable speed)
  CompressionType? get balanced {
    CompressionType? best;
    double bestScore = 0.0;

    for (final entry in results.entries) {
      final result = entry.value;
      // Score balances ratio and speed (lower time = higher score)
      final speedScore = 1000.0 / (result.compressionTime.inMilliseconds + 1);
      final ratioScore = result.compressionRatio * 100;
      final combinedScore = (ratioScore + speedScore) / 2;

      if (combinedScore > bestScore) {
        bestScore = combinedScore;
        best = entry.key;
      }
    }

    return best;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('CompressionBenchmark(sampleSize: $sampleDataSize bytes)');

    for (final entry in results.entries) {
      final type = entry.key;
      final result = entry.value;
      buffer.writeln(
          '  ${type.name}: ${result.spaceSavingsPercent.toStringAsFixed(1)}% '
          'in ${result.compressionTime.inMilliseconds}ms');
    }

    buffer.writeln('  Best ratio: ${bestByRatio?.name ?? 'N/A'}');
    buffer.writeln('  Fastest: ${fastestCompression?.name ?? 'N/A'}');
    buffer.writeln('  Balanced: ${balanced?.name ?? 'N/A'}');

    return buffer.toString();
  }
}
