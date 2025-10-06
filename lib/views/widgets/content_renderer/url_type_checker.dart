import 'dart:collection';

import 'package:flutter/material.dart';

import '../../../common/common_regex.dart';
import '../../../common/linkify/linkifiers.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../repositories/http_functions_repository.dart';
import '../../../utils/utils.dart';

/// Optimized URL type checker with proper cache management and performance improvements
class UrlTypeChecker {
  // Use LRU cache with size limit to prevent memory leaks
  static final _urlTypeCache = LRUCache<String, UrlType>(maxSize: 1000);

  // Cache for expensive regex operations
  static final _regexCache = LRUCache<String, bool>(maxSize: 500);

  // Debounce expensive HTTP operations
  static final Map<String, Future<UrlType>> _pendingRequests = {};

  /// Get instant URL type with optimized caching
  static UrlType getInstantUrlType(String url, {bool? disableUrlParsing}) {
    if (disableUrlParsing ?? false) {
      return UrlType.text;
    }

    // Check cache first
    final cached = _urlTypeCache.get(url);
    if (cached != null) {
      return cached;
    }

    final type = _determineUrlTypeFromExtension(url);
    _urlTypeCache.put(url, type);
    return type;
  }

  /// Optimized URL type determination from extension
  static UrlType _determineUrlTypeFromExtension(String url) {
    // Cache expensive base64 regex check
    if (_isBase64Cached(url)) {
      return UrlType.image;
    }

    final extension = _getFileExtension(url);
    if (extension.isEmpty) {
      return UrlType.text;
    }

    if (_isImageExtensionCached(extension)) {
      return UrlType.image;
    } else if (_isVideoExtensionCached(extension)) {
      return UrlType.video;
    } else if (_isAudioExtensionCached(extension)) {
      return UrlType.audio;
    }

    return UrlType.text;
  }

  /// Optimized file extension extraction
  static String _getFileExtension(String url) {
    try {
      // Remove query parameters and fragments
      final cleanUrl = url.split('?').first.split('#').first;
      final parts = cleanUrl.split('.');
      return parts.length > 1 ? parts.last.toLowerCase() : '';
    } catch (e) {
      return '';
    }
  }

  /// Cached base64 check
  static bool _isBase64Cached(String url) {
    final cacheKey = 'base64_$url';
    final cached = _regexCache.get(cacheKey);
    if (cached != null) {
      return cached;
    }

    final isBase64El = isBase64(url);
    _regexCache.put(cacheKey, isBase64El);
    return isBase64El;
  }

  /// Cached image extension check
  static bool _isImageExtensionCached(String extension) {
    final cacheKey = 'img_$extension';
    final cached = _regexCache.get(cacheKey);
    if (cached != null) {
      return cached;
    }

    final isImage = isImageExtension(extension);
    _regexCache.put(cacheKey, isImage);
    return isImage;
  }

  /// Cached video extension check
  static bool _isVideoExtensionCached(String extension) {
    final cacheKey = 'vid_$extension';
    final cached = _regexCache.get(cacheKey);
    if (cached != null) {
      return cached;
    }

    final isVideo = isVideoExtension(extension);
    _regexCache.put(cacheKey, isVideo);
    return isVideo;
  }

  /// Cached audio extension check
  static bool _isAudioExtensionCached(String extension) {
    final cacheKey = 'aud_$extension';
    final cached = _regexCache.get(cacheKey);
    if (cached != null) {
      return cached;
    }

    final isAudio = isAudioExtension(extension);
    _regexCache.put(cacheKey, isAudio);
    return isAudio;
  }

  /// Get element URL with caching
  static String getElementUrl(LinkableElement element) {
    return element is ArtCurSchemeElement || element is UserSchemeElement
        ? element.text
        : element.url;
  }

  /// Get instant URL types without async calls - optimized
  static Map<int, UrlType> getInstantUrlTypes(
    List<LinkifyElement> elements,
    bool? disableUrlParsing,
  ) {
    final urlTypes = <int, UrlType>{};

    for (int i = 0; i < elements.length; i++) {
      final element = elements[i];
      if (element is LinkableElement) {
        final url = getElementUrl(element);
        urlTypes[i] = getInstantUrlType(
          url,
          disableUrlParsing: disableUrlParsing,
        );
      }
    }

    return urlTypes;
  }

  /// Get URL types with optimized async processing
  static Future<Map<int, UrlType>> getUrlTypesAsync(
    List<LinkifyElement> elements,
    Map<int, UrlType> readyTypes,
    bool? disableUrlParsing,
  ) async {
    final urlsToProcess = <int, String>{};
    final finalTypes = Map<int, UrlType>.from(readyTypes);

    // Collect URLs that need async processing
    for (int i = 0; i < elements.length; i++) {
      final element = elements[i];

      if (element is LinkableElement && readyTypes[i] == null) {
        final url = getElementUrl(element);
        // Only process URLs that might need HTTP checking
        if (urlRegExp.hasMatch(url) &&
            !_hasKnownExtension(url) &&
            !_isBase64Cached(url)) {
          urlsToProcess[i] = url;
        } else {
          // Set as text for URLs we won't process
          finalTypes[i] = UrlType.text;
        }
      }
    }

    if (urlsToProcess.isEmpty) {
      return finalTypes;
    }

    // Process URLs in batches to avoid overwhelming the network
    const batchSize = 5;
    final batches = <List<MapEntry<int, String>>>[];

    final entries = urlsToProcess.entries.toList();
    for (int i = 0; i < entries.length; i += batchSize) {
      final end =
          (i + batchSize < entries.length) ? i + batchSize : entries.length;
      batches.add(entries.sublist(i, end));
    }

    // Process batches sequentially to avoid rate limiting
    for (final batch in batches) {
      final futures = batch.map((entry) => _getUrlTypeWithDebounce(entry.value,
          disableUrlParsing: disableUrlParsing));

      try {
        final results = await Future.wait(futures);

        for (int i = 0; i < batch.length; i++) {
          finalTypes[batch[i].key] = results[i];
        }
      } catch (e) {
        debugPrint('Error processing URL batch: $e');
        // Set remaining URLs as text on error
        for (final entry in batch) {
          finalTypes[entry.key] = UrlType.text;
        }
      }
    }

    return finalTypes;
  }

  /// Check if URL has a known extension that doesn't require HTTP checking
  static bool _hasKnownExtension(String url) {
    final extension = _getFileExtension(url);
    return extension.isNotEmpty &&
        (_isImageExtensionCached(extension) ||
            _isVideoExtensionCached(extension) ||
            _isAudioExtensionCached(extension));
  }

  /// Get URL type with debouncing to prevent duplicate requests
  static Future<UrlType> _getUrlTypeWithDebounce(
    String url, {
    bool? disableUrlParsing,
  }) async {
    // Check if request is already pending
    if (_pendingRequests.containsKey(url)) {
      return _pendingRequests[url]!;
    }

    // Create new request
    final future =
        _performUrlTypeCheck(url, disableUrlParsing: disableUrlParsing);
    _pendingRequests[url] = future;

    try {
      final result = await future;
      return result;
    } finally {
      // Clean up pending request
      _pendingRequests.remove(url);
    }
  }

  /// Perform actual URL type check with timeout and error handling
  static Future<UrlType> _performUrlTypeCheck(
    String url, {
    bool? disableUrlParsing,
  }) async {
    if (disableUrlParsing ?? false) {
      return UrlType.text;
    }

    // Check cache first
    final cached = _urlTypeCache.get(url);
    if (cached != null) {
      return cached;
    }

    UrlType type = UrlType.text;

    try {
      // Add timeout to prevent hanging requests
      type = await HttpFunctionsRepository.getUrlType(url)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Error getting URL type for $url: $e');

      // Fallback to extension-based detection
      final extension = _getFileExtension(url);
      if (_isImageExtensionCached(extension)) {
        type = UrlType.image;
      } else if (_isVideoExtensionCached(extension)) {
        type = UrlType.video;
      } else if (_isAudioExtensionCached(extension)) {
        type = UrlType.audio;
      } else if (base64ImageRegex.hasMatch(url)) {
        type = UrlType.image;
      } else {
        type = UrlType.text;
      }
    }

    _urlTypeCache.put(url, type);
    return type;
  }

  /// Get URL type - legacy method for compatibility
  static Future<UrlType> getUrlType(
    String url, {
    bool? disableUrlParsing,
  }) async {
    return _getUrlTypeWithDebounce(url, disableUrlParsing: disableUrlParsing);
  }

  /// Clear caches to free memory - enhanced
  static void clearCache() {
    _urlTypeCache.clear();
    _regexCache.clear();
    _pendingRequests.clear();
  }

  /// Get cache statistics for monitoring
  static Map<String, dynamic> getCacheStats() {
    return {
      'urlTypeCache': {
        'size': _urlTypeCache.length,
        'maxSize': _urlTypeCache.maxSize,
        'hitRate': _urlTypeCache.hitRate,
      },
      'regexCache': {
        'size': _regexCache.length,
        'maxSize': _regexCache.maxSize,
        'hitRate': _regexCache.hitRate,
      },
      'pendingRequests': _pendingRequests.length,
    };
  }

  /// Preload common URL types for better performance
  static void preloadCommonUrlTypes(List<String> urls) {
    for (final url in urls) {
      if (!_urlTypeCache.containsKey(url)) {
        final type = _determineUrlTypeFromExtension(url);
        _urlTypeCache.put(url, type);
      }
    }
  }
}

/// LRU Cache implementation for efficient memory management
class LRUCache<K, V> {
  LRUCache({required this.maxSize});

  final int maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();
  int _hits = 0;
  int _misses = 0;

  int get length => _cache.length;

  double get hitRate =>
      (_hits + _misses) == 0 ? 0.0 : _hits / (_hits + _misses);

  V? get(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value; // Move to end (most recently used)
      _hits++;
      return value;
    }
    _misses++;
    return null;
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxSize) {
      // Remove least recently used (first item)
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = value;
  }

  bool containsKey(K key) {
    return _cache.containsKey(key);
  }

  void clear() {
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }

  void remove(K key) {
    _cache.remove(key);
  }
}
