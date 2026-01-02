// ignore_for_file: constant_identifier_names, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart' as dioinstance;
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';

import '../../common/common_regex.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/media_manager_data.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'media_servers_state.dart';

class MediaServersCubit extends Cubit<MediaServersState> {
  MediaServersCubit()
      : super(
          MediaServersState(
            activeBlossomServer: '',
            activeRegularServer: '',
            regularServers:
                MediaServer.values.map((e) => e.displayName).toList(),
            blossomServers: const [],
            enableMirroring: false,
            isBlossomActive: false,
          ),
        );

  final dio = Dio();
  final blurredImages = <String, String>{};

  static const Map<MediaServer, ServerConfig> _serverConfigs = {
    MediaServer.nostrBuild: ServerConfig(
      baseUrl: 'https://nostr.build',
      uploadPath: '/api/v2/nip96/upload',
    ),
    MediaServer.nostrMedia: ServerConfig(
      baseUrl: 'https://nostrmedia.com',
      uploadPath: '/upload',
    ),
    MediaServer.nostrCheck: ServerConfig(
      baseUrl: 'https://nostrcheck.me',
      uploadPath: '/api/v2/media',
    ),
    MediaServer.voidCat: ServerConfig(
      baseUrl: 'https://void.cat',
      uploadPath: '/n96',
    ),
  };

  Future<void> init() async {
    await Future.wait([
      loadMediaManager(),
      fetchBlossomServers(),
    ]);
  }

  void reset() {
    _updateState(
      activeBlossomServer: '',
      activeRegularServer: '',
      regularServers: MediaServer.values.map((e) => e.displayName).toList(),
      blossomServers: const [],
      enableMirroring: false,
      isBlossomActive: false,
    );
  }

  Future<void> loadMediaManager() async {
    reset();

    final mediaManager = nostrRepository.getMediaManagerItem(
      currentSigner!.getPublicKey(),
    );

    _updateState(
      activeRegularServer: mediaManager.activeRegularServer,
      isBlossomActive: mediaManager.isBlossomEnabled,
      enableMirroring: mediaManager.isMirroringEnabled,
    );
  }

  Future<bool> addBlossomServer(String server) async {
    if (!_isValidUrl(server)) {
      _showError(gc.t.invalidUrl);
      return false;
    }

    if (state.blossomServers.contains(server)) {
      _showError(gc.t.serverExists);
      return false;
    }

    final updatedServers = [server, ...state.blossomServers];
    final success = await _updateBlossomServersOnNostr(updatedServers);

    if (success) {
      _updateState(
        activeBlossomServer: server,
        blossomServers: updatedServers,
      );
      return true;
    }

    _showError(gc.t.errorAddingBlossom);
    return false;
  }

  Future<void> selectBlossomServer(int index) async {
    final servers = List<String>.from(state.blossomServers);
    final selectedServer = servers.removeAt(index);
    servers.insert(0, selectedServer);

    final success = await _updateBlossomServersOnNostr(servers);

    if (success) {
      _updateState(
        activeBlossomServer: selectedServer,
        blossomServers: servers,
      );
    } else {
      _showError(gc.t.errorSelectBlossom);
    }
  }

  Future<void> deleteBlossomServer(int index) async {
    final servers = List<String>.from(state.blossomServers);
    servers.removeAt(index);

    final success = await _updateBlossomServersOnNostr(servers);

    if (success) {
      _updateState(
        activeBlossomServer:
            index == 0 && servers.isNotEmpty ? servers.first : null,
        blossomServers: servers,
      );
    } else {
      _showError(gc.t.errorDeleteBlossom);
    }
  }

  Future<void> fetchBlossomServers() async {
    if (!canSign()) {
      return;
    }

    final pubkey = currentSigner!.getPublicKey();

    Event? event = await nc.db.loadEvent(
      kind: EventKind.BLOSSOM_SET,
      pubkey: pubkey,
    );

    event ??= await NostrFunctionsRepository.getEventById(
      isIdentifier: false,
      author: pubkey,
      kinds: [EventKind.BLOSSOM_SET],
    );

    if (event != null) {
      nc.db.saveEvent(event);
      _parseAndSetBlossomServers(event);
    }
  }

  void setBlossomStatus(bool isBlossomActive) {
    _updateState(isBlossomActive: isBlossomActive);
    updateMediaManager(isBlossomActive: isBlossomActive);
  }

  void setMirrorStatus(bool enableMirroring) {
    _updateState(enableMirroring: enableMirroring);
    updateMediaManager(enableMirroring: enableMirroring);
  }

  void setActiveRegularServer(String uploadServer) {
    final normalizedServer = _normalizeServerName(uploadServer);
    _updateState(activeRegularServer: normalizedServer);
    updateMediaManager(activeRegularServer: normalizedServer);
  }

  void updateMediaManager({
    bool? enableMirroring,
    bool? isBlossomActive,
    String? activeRegularServer,
  }) {
    nostrRepository.setMediaManager(
      pubkey: currentSigner!.getPublicKey(),
      isBlossomActive: isBlossomActive ?? state.isBlossomActive,
      enableMirroring: enableMirroring ?? state.enableMirroring,
      activeRegularServer: activeRegularServer ?? state.activeRegularServer,
    );
  }

  // Future<String?> pasteImage(
  //   Function() onRegularPaste,
  //   Function(bool)? onLoading,
  // ) async {
  //   try {
  //     final Uint8List? imageBytes = await Pasteboard.image;
  //     final clipboard = SystemClipboard.instance;
  //     if (clipboard == null) {
  //       await onRegularPaste();
  //       return null;
  //     }

  //     final reader = await clipboard.read();
  //     final supportedFormats = [
  //       Formats.png,
  //       Formats.jpeg,
  //       Formats.gif,
  //       Formats.bmp,
  //       Formats.tiff
  //     ];

  //     for (final format in supportedFormats) {
  //       if (reader.canProvide(format)) {
  //         return await _handleImagePaste(reader, format, onLoading);
  //       }
  //     }

  //     await onRegularPaste();
  //     return null;
  //   } catch (e) {
  //     await onRegularPaste();
  //     return null;
  //   }
  // }

  // Future<String?> _handleImagePaste(
  //   DataReader reader,
  //   SimpleFileFormat format,
  //   Function(bool)? onLoading,
  // ) async {
  //   final completer = Completer<String?>();

  //   try {
  //     reader.getFile(format, (file) async {
  //       try {
  //         String? imageUrl;

  //         final stream = file.getStream();
  //         final bytes = <int>[];
  //         await stream.forEach((chunk) => bytes.addAll(chunk));

  //         final imageData = Uint8List.fromList(bytes);
  //         final fileExtension = getFileExtension(format);

  //         if (fileExtension == null) {
  //           BotToastUtils.showError(t.errorUploadingImage);
  //           completer.complete(null);
  //         }

  //         onLoading?.call(true);
  //         imageUrl = await mediaServersCubit.uploadMediaFromUint8List(
  //           imageData: imageData,
  //           extension: format.providerFormat,
  //         );

  //         if (imageUrl == null) {
  //           BotToastUtils.showError(t.errorUploadingImage);
  //         }

  //         onLoading?.call(false);
  //         completer.complete(imageUrl);
  //       } catch (e) {
  //         BotToastUtils.showError(t.errorUploadingImage);
  //         onLoading?.call(false);
  //         completer.complete(null);
  //       }
  //     });
  //   } catch (e) {
  //     BotToastUtils.showError(t.errorUploadingImage);
  //     completer.complete(null);
  //   }

  //   return completer.future;
  // }
  Future<String?> pasteImage(
    Function() onRegularPaste,
    Function(bool)? onLoading,
  ) async {
    try {
      // Check if there's an image in clipboard
      final imageBytes = await Pasteboard.image;

      if (imageBytes == null || imageBytes.isEmpty) {
        await onRegularPaste();
        return null;
      }

      return await _handleImagePaste(imageBytes, onLoading);
    } catch (e) {
      await onRegularPaste();
      return null;
    }
  }

  Future<String?> _handleImagePaste(
    Uint8List imageBytes,
    Function(bool)? onLoading,
  ) async {
    try {
      onLoading?.call(true);

      // Detect format from image bytes (PNG starts with specific bytes)
      final extension = _detectImageFormat(imageBytes);

      // Upload the image
      final imageUrl = await mediaServersCubit.uploadMediaFromUint8List(
        imageData: imageBytes,
        extension: extension,
      );

      if (imageUrl == null) {
        BotToastUtils.showError(t.errorUploadingImage);
        onLoading?.call(false);
        return null;
      }

      onLoading?.call(false);
      return imageUrl;
    } catch (e) {
      BotToastUtils.showError(t.errorUploadingImage);
      onLoading?.call(false);
      return null;
    }
  }

  String _detectImageFormat(Uint8List bytes) {
    // PNG signature
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }

    // JPEG signature
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return 'jpeg';
    }

    // GIF signature
    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46) {
      return 'gif';
    }

    // BMP signature
    if (bytes.length >= 2 && bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return 'bmp';
    }

    // TIFF signature (little-endian)
    if (bytes.length >= 4 &&
        bytes[0] == 0x49 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x2A &&
        bytes[3] == 0x00) {
      return 'tiff';
    }

    // TIFF signature (big-endian)
    if (bytes.length >= 4 &&
        bytes[0] == 0x4D &&
        bytes[1] == 0x4D &&
        bytes[2] == 0x00 &&
        bytes[3] == 0x2A) {
      return 'tiff';
    }

    lg.i('not found');
    // Default to PNG if unknown
    return 'png';
  }

  Future<String?> uploadMediaFromUint8List({
    required Uint8List imageData,
    String? extension,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final fileName =
        'clipboard_image_${DateTime.now().millisecondsSinceEpoch}${extension != null ? '.$extension' : ''}';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(imageData);

    final res = (await uploadMedia(file: file))['url'];

    await file.delete();

    return res;
  }

  Future<Map<String, String>> uploadMedia({
    required File file,
    Function(int, int)? onSendProgress,
  }) async {
    try {
      if (state.isBlossomActive && state.activeBlossomServer.isNotEmpty) {
        return await _uploadToBlossom(
          file,
          onSendProgress,
        );
      } else {
        return await _uploadToRegularServer(
          file,
          onSendProgress: onSendProgress,
        );
      }
    } catch (e) {
      lg.e('Upload error: $e');
      _showError('Error occurred while uploading the file');
      return {};
    }
  }

  // Blossom upload implementation
  Future<Map<String, String>> _uploadToBlossom(
    File file,
    Function(int, int)? onSendProgress,
  ) async {
    try {
      final fileBytes = await file.readAsBytes();
      final hash = _calculateSHA256(fileBytes);
      final mimeType = _getMimeType(file.path);

      // Create Blossom auth event
      final authEvent = await _createBlossomAuthEvent(hash);
      if (authEvent == null) {
        _showError('Error creating Blossom authentication event');
        return {};
      }

      // Upload to primary server
      final res = await _uploadToBlossomServer(
        state.activeBlossomServer,
        hash,
        fileBytes,
        authEvent,
        mimeType,
        onSendProgress,
      );

      if (res.isEmpty) {
        _showError('Failed to upload to primary Blossom server');
        return {};
      }

      // Mirror to additional servers if enabled
      if (state.enableMirroring && state.blossomServers.length > 1) {
        _mirrorToBlossomServers(
          url: res['url']!,
          authEvent: authEvent,
        );
      }

      return res;
    } catch (e) {
      lg.e('Blossom upload error: $e');
      _showError('Error uploading to Blossom server');
      return {};
    }
  }

  // Regular server upload (existing NIP-96 implementation)
  Future<Map<String, String>> _uploadToRegularServer(
    File file, {
    Function(int, int)? onSendProgress,
  }) async {
    final authEvent = await _createRegularAuthEvent();

    if (authEvent == null) {
      _showError('Error occurred while signing the authentication event.');
      return {};
    }

    final formData = await _createFormData(file);
    final response = await _performRegularUpload(
      formData,
      authEvent,
      onSendProgress,
    );

    return _parseUploadResponse(response, false);
  }

  // Private helper methods
  bool _isValidUrl(String url) => urlRegex2.hasMatch(url);

  void _showError(String message) => BotToastUtils.showError(message);

  void _updateState({
    String? activeBlossomServer,
    String? activeRegularServer,
    List<String>? blossomServers,
    List<String>? regularServers,
    bool? enableMirroring,
    bool? isBlossomActive,
  }) {
    if (!isClosed) {
      emit(state.copyWith(
        activeBlossomServer: activeBlossomServer,
        activeRegularServer: activeRegularServer,
        blossomServers: blossomServers,
        regularServers: regularServers,
        enableMirroring: enableMirroring,
        isBlossomActive: isBlossomActive,
      ));
    }
  }

  Future<bool> _updateBlossomServersOnNostr(List<String> servers) async {
    final tags = servers.map((server) => ['server', server]).toList();

    final event = await Event.genEvent(
      kind: EventKind.BLOSSOM_SET,
      tags: tags,
      content: '',
      signer: currentSigner,
    );

    if (event == null) {
      return false;
    }

    final isSuccessful = await NostrFunctionsRepository.sendEvent(
      event: event,
      setProgress: true,
    );

    if (isSuccessful) {
      nc.db.saveEvent(event);
    }

    return isSuccessful;
  }

  void _parseAndSetBlossomServers(Event event) {
    final blossomServers = event.tags
        .where((tag) => tag.first == 'server' && tag.length > 1)
        .map((tag) => tag[1])
        .toList();

    final activeBlossomServer =
        blossomServers.isNotEmpty ? blossomServers.first : '';

    _updateState(
      activeBlossomServer: activeBlossomServer,
      blossomServers: blossomServers,
    );
  }

  String _normalizeServerName(String uploadServer) {
    return MediaServer.values
        .firstWhere(
          (server) => server.displayName == uploadServer,
          orElse: () => MediaServer.nostrBuild,
        )
        .displayName;
  }

  ServerConfig _getServerConfig(String serverName) {
    final server = MediaServer.values.firstWhere(
      (s) => s.displayName == serverName,
      orElse: () => MediaServer.nostrBuild,
    );
    return _serverConfigs[server]!;
  }

  EventSigner _getEventSigner() {
    if (canSign()) {
      return currentSigner!;
    } else {
      final keys = Keychain.generate();
      return Bip340EventSigner(keys.private, keys.public);
    }
  }

  // Blossom-specific helper methods
  String _calculateSHA256(Uint8List bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<BlossomFetchResult> fetchBlossomBlob({
    required String url,
    int timeout = 10000,
  }) async {
    try {
      // Check if it's a valid Blossom URL
      final blossomInfo = _parseBlossomUrl(url);
      if (blossomInfo == null) {
        return const BlossomFetchResult(
          success: false,
          error: 'Not a valid Blossom URL',
        );
      }

      final dio = Dio(
        BaseOptions(
          connectTimeout: Duration(milliseconds: timeout),
          receiveTimeout: Duration(milliseconds: timeout),
        ),
      );

      // Try to fetch from available mirror servers
      return await _fetchFromMirrors(
        dio,
        blossomInfo,
        originalUrl: url,
      );
    } catch (e) {
      lg.e('Blossom fetch error: $e');
      return BlossomFetchResult(
        success: false,
        error: 'Fetch error: $e',
      );
    }
  }

  Future<BlossomFetchResult> _fetchFromMirrors(
    Dio dio,
    BlossomInfo blossomInfo, {
    String? originalUrl,
  }) async {
    // Use the cubit's available Blossom servers
    final availableServers = state.blossomServers;

    if (availableServers.isEmpty) {
      lg.w('No Blossom servers available for mirroring');
      return const BlossomFetchResult(
        success: false,
        error: 'No Blossom servers available for fallback',
      );
    }

    for (final serverUrl in availableServers) {
      try {
        // Construct mirror URL
        final mirrorUrl = _constructMirrorUrl(serverUrl, blossomInfo);

        // Skip if this is the same as the original URL
        if (originalUrl != null && mirrorUrl == originalUrl) {
          continue;
        }

        lg.i('Trying mirror server: $mirrorUrl');
        final response = await _fetchFromUrl(dio, mirrorUrl);

        if (response.success && response.data != null) {
          if (_verifyBlobHash(response.data!, blossomInfo.hash)) {
            lg.i('Successfully fetched from mirror: $mirrorUrl');
            return BlossomFetchResult(
              success: true,
              data: response.data,
              mimeType: response.mimeType,
              sourceUrl: mirrorUrl,
            );
          } else {
            lg.w('Hash mismatch from mirror: $mirrorUrl');
          }
        }
      } catch (e) {
        lg.w('Failed to fetch from mirror $serverUrl: $e');
        continue;
      }
    }

    return const BlossomFetchResult(
      success: false,
      error: 'Failed to fetch from all available mirror servers',
    );
  }

  Future<FetchResponse> _fetchFromUrl(Dio dio, String url) async {
    try {
      final response = await dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = Uint8List.fromList(response.data!);
        final mimeType = response.headers.value('content-type');

        return FetchResponse(
          success: true,
          data: data,
          mimeType: mimeType,
        );
      }

      return FetchResponse(
        success: false,
        error: 'HTTP ${response.statusCode}',
      );
    } catch (e) {
      return FetchResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  String _constructMirrorUrl(String serverUrl, BlossomInfo blossomInfo) {
    final baseUrl = serverUrl.endsWith('/') ? serverUrl : '$serverUrl/';

    if (blossomInfo.extension != null) {
      return '$baseUrl${blossomInfo.hash}.${blossomInfo.extension}';
    } else {
      return '$baseUrl${blossomInfo.hash}';
    }
  }

  bool _verifyBlobHash(Uint8List data, String expectedHash) {
    final digest = sha256.convert(data);
    final actualHash = digest.toString().toLowerCase();
    return actualHash == expectedHash.toLowerCase();
  }

  BlossomInfo? _parseBlossomUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;

      // Remove leading slash if present
      final cleanPath = path.startsWith('/') ? path.substring(1) : path;

      // Check for 64-character hex string (SHA-256 hash)
      final hashRegex = RegExp(r'^([a-fA-F0-9]{64})(?:\.([a-zA-Z0-9]+))?');
      final match = hashRegex.firstMatch(cleanPath);

      if (match != null) {
        final hash = match.group(1)!.toLowerCase();
        final extension = match.group(2);
        final baseUrl =
            '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';

        return BlossomInfo(
          hash: hash,
          extension: extension,
          baseUrl: baseUrl,
        );
      }

      return null;
    } catch (e) {
      lg.e('Error parsing Blossom URL: $e');
      return null;
    }
  }

  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      case 'mov':
        return 'video/quicktime';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  Future<Event?> _createBlossomAuthEvent(String hash) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return Event.genEvent(
      kind: EventKind.BLOSSOM_HTTP_AUTH,
      tags: [
        ['t', 'upload'],
        ['x', hash],
        ['expiration', (now + 3600).toString()],
      ],
      content: '',
      signer: _getEventSigner(),
    );
  }

  Future<Map<String, String>> _uploadToBlossomServer(
    String serverUrl,
    String hash,
    Uint8List fileBytes,
    Event authEvent,
    String mimeType,
    Function(int, int)? onSendProgress,
  ) async {
    try {
      // Ensure server URL ends with /
      final baseUrl = serverUrl.endsWith('/') ? serverUrl : '$serverUrl/';
      final uploadUrl = '${baseUrl}upload';

      final authBytes = utf8.encode(authEvent.toJsonString());
      final authBase64 = base64.encode(authBytes);

      final response = await dio.put(
        uploadUrl,
        data: Stream.fromIterable([fileBytes]),
        onSendProgress: onSendProgress,
        options: Options(
          headers: {
            'Content-Type': mimeType,
            'Authorization': 'Nostr $authBase64',
            'Content-Length': fileBytes.length.toString(),
          },
        ),
      );

      return _parseUploadResponse(response, true);
    } on DioException catch (e) {
      lg.e(e.stackTrace);
      return {};
    } catch (e, stack) {
      lg.i(stack);
      return {};
    }
  }

  Future<void> _mirrorToBlossomServers({
    required String url,
    required Event authEvent,
  }) async {
    final mirrorServers = state.blossomServers.skip(1).toList();

    for (final server in mirrorServers) {
      await _mirror(
        url: url,
        server: server,
        authEvent: authEvent,
      );
    }
  }

  Future<void> _mirror({
    required String server,
    required String url,
    required Event authEvent,
  }) async {
    try {
      final baseUrl = server.endsWith('/') ? server : '$server/';
      final mirrorUrl = '${baseUrl}mirror';

      final authBytes = utf8.encode(authEvent.toJsonString());
      final authBase64 = base64.encode(authBytes);

      final res = await dio.put(
        mirrorUrl,
        data: jsonEncode({'url': url}),
        options: Options(
          headers: {
            'Authorization': 'Nostr $authBase64',
          },
        ),
      );

      lg.i(res);
    } on DioException catch (e) {
      lg.i(e);
    }
  }

  // Regular server methods (renamed for clarity)
  Future<Event?> _createRegularAuthEvent() async {
    final config = _getServerConfig(state.activeRegularServer);

    return Event.genEvent(
      kind: EventKind.HTTP_AUTH,
      tags: [
        ['u', config.fullUrl],
        ['method', 'POST'],
      ],
      content: '',
      signer: _getEventSigner(),
    );
  }

  Future<dioinstance.FormData> _createFormData(File file) async {
    final fileName = file.path.split('/').last;
    final userMap = <String, dynamic>{
      'file': await dioinstance.MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
    };
    return dioinstance.FormData.fromMap(userMap);
  }

  Future<Response> _performRegularUpload(dioinstance.FormData formData,
      Event authEvent, Function(int, int)? onSendProgress) async {
    final config = _getServerConfig(state.activeRegularServer);
    final bytes = utf8.encode(authEvent.toJsonString());
    final base64Str = base64.encode(bytes);

    final dio = Dio(BaseOptions(
      contentType: 'multipart/form-data',
      baseUrl: config.baseUrl,
      headers: {'Authorization': 'Nostr $base64Str'},
    ));

    return dio.post(
      config.uploadPath,
      data: formData,
      onSendProgress: onSendProgress,
    );
  }

  Map<String, String> _parseUploadResponse(Response response, bool isBlossom) {
    if (isBlossom) {
      String? url;
      String? type;
      String? blurhash;
      String? dim;
      String? duration;
      int? size;
      String? x;

      if (response.data.runtimeType == String) {
        final decode = jsonDecode(response.data);

        url = decode['url'];
        type = decode['type'];
        blurhash = decode['blurhash'];
        dim = decode['dim'];
        duration = decode['duration'];
        size = decode['size'];
        x = decode['sha256'];
      } else {
        url = response.data['url'];
        type = response.data['type'];
        blurhash = response.data['blurhash'];
        dim = response.data['dim'];
        duration = response.data['duration'];
        size = response.data['size'];
        x = response.data['sha256'];
      }

      if (url == null) {
        _showError('File could not be uploaded');
        return {};
      }

      return {
        'url': url,
        if (type != null) 'm': type,
        if (blurhash != null) 'blurhash': blurhash,
        if (dim != null) 'dim': dim,
        if (duration != null) 'duration': duration,
        if (size != null) 'size': size.toString(),
        if (x != null) 'sha256': x,
      };
    } else {
      if (response.data['status'] != 'success') {
        _showError('File could not be uploaded');
        return {};
      }

      final tags = response.data['nip94_event']['tags'] as List?;
      if (tags == null || tags.isEmpty) {
        _showError('File could not be uploaded');
        return {};
      }

      String url = '';
      String mimeType = '';

      for (final tag in tags) {
        final tagList = tag as List;
        final firstElement = tagList.first;

        if (firstElement == 'url') {
          url = tagList[1];
        } else if (firstElement == 'm') {
          mimeType = tagList[1];
        }
      }

      if (url.isEmpty) {
        _showError('File could not be uploaded');
        return {};
      }

      return {'m': mimeType, 'url': url};
    }
  }

  // Public utility methods (if needed externally)
  String getUploadServerUrl(String uploadServer) =>
      _getServerConfig(uploadServer).fullUrl;

  String getUploadServerBaseUrl(String uploadServer) =>
      _getServerConfig(uploadServer).baseUrl;

  String getUploadServerPath(String uploadServer) =>
      _getServerConfig(uploadServer).uploadPath;

  /// Compute imgproxy signature over `salt + path` using hex KEY/SALT.
  String generateImgProxySignature({
    required String key,
    required String salt,
    required String path,
  }) {
    // Decode hex key and salt to bytes
    final keyBytes = _hexToBytes(key);
    final saltBytes = _hexToBytes(salt);

    // Create HMAC-SHA256 instance with the key
    final hmac = Hmac(sha256, keyBytes);

    // Combine salt and path
    final message = saltBytes + utf8.encode(path);

    // Generate the digest
    final digest = hmac.convert(message);

    // Convert to base64url (URL-safe base64 without padding)
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Helper function to convert hex string to bytes
  Uint8List _hexToBytes(String hex) {
    // Remove any spaces or special characters
    hex = hex.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');

    final length = hex.length;
    final bytes = Uint8List(length ~/ 2);

    for (var i = 0; i < length; i += 2) {
      bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }

    return bytes;
  }

  /// Helper to encode base64url without padding
  String _b64UrlNoPad(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Build a path that uses the *plain* source URL (no encoding).
  String buildPlainPath(String options, String sourceUrl, {String? outExt}) {
    var path = '/$options/plain/$sourceUrl';
    if (outExt != null && outExt.isNotEmpty) {
      path += '.$outExt';
    }
    return path;
  }

  /// Build a path that uses the *base64url-encoded* source URL.
  /// (Avoids escaping issues. Add .<ext> to force output format if desired.)
  String buildEncodedPath(String options, String sourceUrl, {String? outExt}) {
    final encSrc = _b64UrlNoPad(utf8.encode(sourceUrl));
    var path = '/$options/$encSrc';
    if (outExt != null && outExt.isNotEmpty) {
      path += '.$outExt';
    }
    return path;
  }

  /// Produce a full signed URL.
  String makeSignedUrl({
    required String sourceUrl, // The original image URL
    String options = 'bl:50/q:50', // Processing options
    String? outExt, // Optional output extension
    bool useEncoded = false, // Whether to use encoded or plain URL
  }) {
    final current = blurredImages[sourceUrl];

    if (current != null) {
      return current;
    }

    final keyHex = dotenv.env['IMGPROXY_KEY']!;
    final saltHex = dotenv.env['IMGPROXY_SALT']!;

    // Build the path first
    final path = useEncoded
        ? buildEncodedPath(options, sourceUrl, outExt: outExt)
        : buildPlainPath(options, sourceUrl, outExt: outExt);

    // Generate signature for the path
    final sig = generateImgProxySignature(
      key: keyHex,
      salt: saltHex,
      path: path,
    );

    // Build final URL: baseUrl/signature/path
    final url = '$imgProxy/$sig$path';
    blurredImages[sourceUrl] = url;

    return url;
  }
}
