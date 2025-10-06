// ignore_for_file: use_setters_to_change_properties, use_build_context_synchronously

import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/utils.dart';
import '../../views/wallet_view/send_zaps_view/send_zaps_view.dart';

part 'smart_widget_app_state.dart';

class SmartWidgetAppCubit extends Cubit<SmartWidgetAppState> {
  SmartWidgetAppCubit({required this.onSignEvent, this.onCustomDataAdded})
      : super(const SmartWidgetAppState(isReady: false));
  // ========================
  // PROPERTIES & CONSTRUCTOR
  // ========================

  late WebViewController controller;
  final Function(String)? onCustomDataAdded;
  final Future<bool> Function(bool isSignPublish, Map<String, dynamic> content)
      onSignEvent;

  // ========================
  // WEBVIEW CONTROLLER SETUP
  // ========================

  void setController(WebViewController controller) {
    this.controller = controller;
  }

  // ========================
  // MESSAGE HANDLING
  // ========================

  /// Main entry point for handling messages from the WebView JavaScript
  Future<void> handleFrameMessage(JavaScriptMessage message) async {
    try {
      final messageData = jsonDecode(message.message);
      lg.i(messageData);
      if (messageData['scope'] != 'sw-data') {
        return;
      }

      final data = messageData['data'];
      final kind = messageData['kind'];

      await _routeMessage(kind, data);
    } catch (e) {
      lg.i('Error handling frame message: $e');
    }
  }

  /// Routes messages to appropriate handlers based on message kind
  Future<void> _routeMessage(String kind, dynamic data) async {
    switch (kind) {
      case 'app-loaded':
        _handleAppLoaded();
      case 'sign-event':
        await _handleSignEvent(data, shouldPublish: false);
      case 'sign-publish':
        await _handleSignEvent(data, shouldPublish: true);
      case 'payment-request':
        await _handlePaymentRequest(data);
      case 'custom-data':
        _handleCustomData(data);
    }
  }

  // ========================
  // APP INITIALIZATION
  // ========================

  void _handleAppLoaded() {
    emit(state.copyWith(isReady: true));

    final responseData = _buildUserMetadataResponse();
    sendData(jsonEncode(responseData));
  }

  Map<String, dynamic> _buildUserMetadataResponse() {
    if (canSign() || canRoam()) {
      return {
        'scope': 'sw-data',
        'kind': 'user-metadata',
        'data': {
          'user': {
            ...nostrRepository.currentMetadata.toMap(),
            'hasWallet':
                canSign() && walletManagerCubit.state.wallets.isNotEmpty,
          },
          'host_origin': '*',
        },
      };
    } else {
      return {
        'scope': 'sw-data',
        'kind': 'err-msg',
        'data': gc.t.userNotConnected,
      };
    }
  }

  // ========================
  // PAYMENT HANDLING
  // ========================

  Future<void> _handlePaymentRequest(Map<String, dynamic>? data) async {
    if (data == null) {
      return;
    }

    final paymentData = _extractPaymentData(data);
    final context = nostrRepository.mainCubit.context;

    doIfCanSign(
      func: () => _showPaymentBottomSheet(context, paymentData),
      context: context,
    );
  }

  Map<String, dynamic> _extractPaymentData(Map<String, dynamic> data) {
    final address = data['address'];
    final nostrPubkey = data['nostrPubkey'];
    final amount = data['amount']?.toString();
    final encodedEvent = data['nostrEventIDEncode']?.toString() ?? '';

    String? aTag;
    String? eventId;

    try {
      final decodedData = _decodeNostrEvent(encodedEvent);
      eventId = decodedData['eventId'];
      aTag = decodedData['aTag'];
    } catch (_) {
      // Handle decoding errors gracefully
    }

    return {
      'address': address,
      'nostrPubkey': nostrPubkey,
      'amount': amount,
      'eventId': eventId,
      'aTag': aTag,
    };
  }

  Map<String, String?> _decodeNostrEvent(String encodedEvent) {
    String? aTag;
    String? eventId;

    if (encodedEvent.startsWith('note1')) {
      eventId = Nip19.decodeNote(encodedEvent);
    } else if (encodedEvent.startsWith('nevent1') ||
        encodedEvent.startsWith('naddr1')) {
      final nostrDecode = Nip19.decodeShareableEntity(encodedEvent);
      final hexCode = hex.decode(nostrDecode['special']);
      final author = nostrDecode['author'];
      final special = String.fromCharCodes(hexCode);
      final kind = nostrDecode['kind'];

      if (kind == EventKind.TEXT_NOTE) {
        eventId = special;
      } else {
        aTag = '$kind$author$special';
      }
    }

    return {'eventId': eventId, 'aTag': aTag};
  }

  void _showPaymentBottomSheet(
      BuildContext context, Map<String, dynamic> paymentData) {
    showModalBottomSheet(
      elevation: 0,
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => SendZapsView(
        metadata: Metadata.empty().copyWith(
          pubkey: paymentData['nostrPubkey'],
          lud06: paymentData['address'],
          lud16: paymentData['address'],
        ),
        initialVal: paymentData['amount'] != null
            ? int.tryParse(paymentData['amount'])
            : null,
        onSuccess: (preimage, amount) => _sendPaymentResponse(preimage, true),
        onFailure: (message) => _sendPaymentResponse('', false),
        isZapSplit: false,
        zapSplits: const [],
        eventId: paymentData['eventId'],
        aTag: paymentData['aTag'],
        lnbc: paymentData['address'].startsWith('lnbc')
            ? paymentData['address']
            : null,
      ),
    );
  }

  void _sendPaymentResponse(String preimage, bool success) {
    final data = {
      'scope': 'sw-data',
      'kind': 'payment-response',
      'data': {
        'preimage': preimage,
        'status': success,
        'host_origin': '*',
      },
    };
    sendData(jsonEncode(data));
  }

  // ========================
  // EVENT SIGNING & PUBLISHING
  // ========================

  Future<void> _handleSignEvent(Map<String, dynamic>? unsignedEvent,
      {required bool shouldPublish}) async {
    if (!canSign()) {
      _sendErrorResponse(gc.t.userCannotSignEvent);
      return;
    }

    if (unsignedEvent == null) {
      _sendErrorResponse(gc.t.invalidEvent);
      return;
    }

    try {
      final canProceed =
          await _checkSigningPermission(shouldPublish, unsignedEvent);
      if (!canProceed) {
        _sendErrorResponse(gc.t.eventCannotBeSigned);
        return;
      }

      await _processEventSigning(unsignedEvent, shouldPublish);
    } catch (e) {
      lg.i('Error signing event: $e');
      _sendErrorResponse(gc.t.invalidEvent);
    }
  }

  Future<bool> _checkSigningPermission(
    bool shouldPublish,
    Map<String, dynamic> unsignedEvent,
  ) async {
    if (localDatabaseRepository.getAutomaticSigning()) {
      return true;
    }

    return onSignEvent.call(shouldPublish, unsignedEvent);
  }

  Future<void> _processEventSigning(
      Map<String, dynamic> unsignedEvent, bool shouldPublish) async {
    final content = unsignedEvent['content'];
    final kind = unsignedEvent['kind'];
    final tags = _parseTags(unsignedEvent['tags']);

    final event = await Event.genEvent(
      content: content,
      kind: kind,
      tags: tags,
      signer: currentSigner,
    );

    if (event == null) {
      _sendErrorResponse(gc.t.eventCannotBeSigned);
      return;
    }

    if (shouldPublish) {
      await _publishEvent(event);
    } else {
      _sendEventResponse(event);
    }
  }

  List<List<String>> _parseTags(dynamic tagsData) {
    return (tagsData as List<dynamic>)
        .map((innerList) => (innerList as List<dynamic>)
            .map((item) => item.toString())
            .toList())
        .toList();
  }

  Future<void> _publishEvent(Event event) async {
    final isSuccessful = await NostrFunctionsRepository.sendEvent(
      event: event,
      setProgress: true,
      relays: currentUserRelayList.writes,
    );

    final status =
        isSuccessful ? EventStatus.success.name : EventStatus.error.name;

    final data = {
      'scope': 'sw-data',
      'kind': 'nostr-event',
      'data': {
        'event': event.toJson(),
        'status': status,
      },
    };

    sendData(jsonEncode(data));
  }

  void _sendEventResponse(Event event) {
    final data = {
      'scope': 'sw-data',
      'kind': 'nostr-event',
      'data': event.toJson(),
    };
    sendData(jsonEncode(data));
  }

  // ========================
  // CUSTOM DATA HANDLING
  // ========================

  void _handleCustomData(dynamic data) {
    onCustomDataAdded?.call(data?.toString() ?? '');
  }

  // ========================
  // UTILITY METHODS
  // ========================

  void _sendErrorResponse(String errorMessage) {
    final data = {
      'scope': 'sw-data',
      'kind': 'err-msg',
      'data': errorMessage,
    };
    sendData(jsonEncode(data));
  }

  Future<void> sendData(String data) async {
    try {
      await controller.runJavaScript('window.postMessage($data, "*");');
    } catch (e) {
      lg.i('Error sending data to WebView: $e');
    }
  }
}
