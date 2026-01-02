// ignore_for_file: avoid_dynamic_calls, constant_identifier_names, use_build_context_synchronously, prefer_foreach

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/nostr_core.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../common/common_regex.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../models/lightning_invoice_model.dart';
import '../../models/points_system_models.dart';
import '../../models/wallet_model.dart';
import '../../repositories/http_functions_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/app_cycle.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/global_keys.dart';
import '../../utils/utils.dart';
import '../../views/wallet_view/widgets/export_wallets.dart';
import '../../views/widgets/modal_with_blur.dart';

part 'wallets_manager_state.dart';

class WalletsManagerCubit extends Cubit<WalletsManagerState>
    with WidgetsBindingObserver {
  WalletsManagerCubit() : super(WalletsManagerState.initial()) {
    _initializeSubscriptions();
  }

  // =============================================================================
  // CONSTANTS
  // =============================================================================

  static const String NWC_GET_BALANCE = 'get_balance';
  static const String NWC_PAY_INVOICE = 'pay_invoice';
  static const String NWC_MULTI_PAY_INVOICE = 'multi_pay_invoice';
  static const String NWC_TRANSACTIONS_LIST = 'list_transactions';
  static const String NWC_MAKE_INVOICE = 'make_invoice';
  static const String YAKIHONNE_NWC_LINK =
      'https://my.albyhub.com/apps/new?c=Yakihonne';

  // =============================================================================
  // PROPERTIES
  // =============================================================================

  late BuildContext mainContext;
  late StreamSubscription _sub;
  late StreamSubscription _userStatusStream;
  StreamSubscription? _appLifeCycle;

  Map<String, List<WalletModel>> globalWallets = <String, List<WalletModel>>{};
  List<ZapsToPoints> zapsToPoints = <ZapsToPoints>[];
  List<LightningInvoice> unprocessedInvoices = <LightningInvoice>[];
  Set<String> requests = <String>{};

  NostrCore wnc = NostrCore(db: nc.db, loadRemoteCache: false);
  Map<String, int> btcInFiat = {};
  int index = -1;

  final AppLifecycleNotifier _appLifecycleNotifier = AppLifecycleNotifier();

  // =============================================================================
  // INITIALIZATION
  // =============================================================================

  void _initializeSubscriptions() {
    _userStatusStream = nostrRepository.currentSignerStream.listen((_) {
      if (!isClosed) {
        _emitRefresh();
      }
    });
  }

  Future<void> init() async {
    try {
      final results = await _loadStoredData();
      final wallets = await _parseWallets(results.wallets);

      final selectedWalletId =
          _determineSelectedWallet(results.selectedWalletId, wallets);

      _updateStateAfterInit(
        wallets,
        selectedWalletId,
        results.defaultWallet,
        results.useDefaultWallet,
      );

      _requestBalanceForSelectedWallet(wallets[selectedWalletId]);
      getBtcInFiat();
    } catch (e) {
      _logError('Failed to initialize wallet cubit', e);
    }
  }

  Future<_LoadedData> _loadStoredData() async {
    final results = await Future.wait([
      localDatabaseRepository.getWallets(),
      localDatabaseRepository.getDefaultWallet(),
      localDatabaseRepository.getUseDefaultWallet(),
    ]);

    return _LoadedData(
      wallets: results[0] as String,
      defaultWallet: results[1] as String,
      useDefaultWallet: results[2] as bool,
      selectedWalletId: localDatabaseRepository.getSelectedWalletId(),
    );
  }

  Future<Map<String, WalletModel>> _parseWallets(
      String stringifiedWallets) async {
    final wallets = <String, WalletModel>{};

    if (stringifiedWallets.isEmpty) {
      return wallets;
    }

    try {
      final globalWalletsData = jsonDecode(stringifiedWallets) as Map;
      _updateGlobalWallets(globalWalletsData);

      final selectedWallets = globalWallets[currentSigner?.getPublicKey()];
      if (selectedWallets != null) {
        for (final wallet in selectedWallets) {
          wallets[wallet.id] = wallet;
        }
      }
    } catch (e) {
      _logError('Failed to parse wallets', e);
    }

    return wallets;
  }

  void _updateGlobalWallets(Map globalWalletsData) {
    for (final item in globalWalletsData.entries) {
      globalWallets[item.key] = (item.value as List).map((e) {
        return e['kind'] == 1
            ? NostrWalletConnectModel.fromMap(e)
            : AlbyConnectModel.fromMap(e);
      }).toList();
    }
  }

  String _determineSelectedWallet(
      String selectedWalletId, Map<String, WalletModel> wallets) {
    if (selectedWalletId.isEmpty && wallets.isNotEmpty) {
      final firstWalletId = wallets.entries.first.key;
      localDatabaseRepository.setSelectedWalletId(firstWalletId);
      return firstWalletId;
    }
    return selectedWalletId;
  }

  void _updateStateAfterInit(
    Map<String, WalletModel> wallets,
    String selectedWalletId,
    String defaultWallet,
    bool useDefaultWallet,
  ) {
    if (!isClosed) {
      emit(state.copyWith(
        selectedWalletId: selectedWalletId,
        wallets: wallets,
        defaultExternalWallet: defaultWallet,
        useDefaultWallet: useDefaultWallet,
      ));
    }
  }

  Future<void> _requestBalanceForSelectedWallet(
      WalletModel? selectedWallet) async {
    if (selectedWallet == null) {
      return;
    }

    if (selectedWallet is NostrWalletConnectModel) {
      await requestNwcBalance(selectedWallet);
    } else if (selectedWallet is AlbyConnectModel) {
      await requestAlbyBalance(selectedWallet);
    }
  }

  // =============================================================================
  // WALLET MANAGEMENT
  // =============================================================================

  Future<void> createWallet({
    required String name,
    required BuildContext context,
    required Function() onNameFailure,
  }) async {
    final cancel = BotToastUtils.showLoading();

    try {
      final wallet = await _createWalletOnServer(name);

      if (wallet != null && context.mounted) {
        addNwc(wallet);
        _showWalletCreatedSuccess(context);
        await _showExportWalletModal(context, wallet);
      } else {
        _showWalletCreationError(context);
      }
    } catch (e) {
      _handleWalletCreationError(e, context, onNameFailure);
    } finally {
      cancel.call();
    }
  }

  Future<String?> _createWalletOnServer(String name) async {
    final data = await HttpFunctionsRepository.post(
      walletsUrl,
      {'username': name},
    ).timeout(const Duration(seconds: 5));

    return data?['connectionSecret'];
  }

  void _showWalletCreatedSuccess(BuildContext context) {
    BotToastUtils.showSuccess(context.t.walletCreated.capitalizeFirst());
  }

  Future<void> _showExportWalletModal(
      BuildContext context, String wallet) async {
    await Future.delayed(const Duration(seconds: 1));
    final walletDetails = Uri.parse(wallet);

    showBlurredModal(
      context: GlobalKeys.navigatorKey.currentState!.overlay!.context,
      isDismissable: false,
      view: ExportWalletOnCreation(
        wallet: NostrWalletConnectModel(
          id: '',
          kind: 0,
          lud16: walletDetails.queryParameters['lud16'] ?? '',
          connectionString: wallet,
          relay: '',
          secret: '',
          walletPubkey: '',
          permissions: const [],
        ),
      ),
    );
  }

  void _showWalletCreationError(BuildContext context) {
    BotToastUtils.showError(context.t.errorCreatingWallet.capitalizeFirst());
  }

  void _handleWalletCreationError(
      dynamic e, BuildContext context, Function() onNameFailure) {
    if (e is DioException && e.type == DioExceptionType.badResponse) {
      onNameFailure.call();
      return;
    }
    BotToastUtils.showError(context.t.errorCreatingWallet.capitalizeFirst());
  }

  void verifyUri(String uri) {
    if (uri.isEmpty || !uri.contains('nostr+walletconnect')) {
      BotToastUtils.showError(
          mainContext.t.invalidPairingSecret.capitalizeFirst());
      return;
    }
    addNwc(uri);
  }

  Future<void> addNwc(String uri) async {
    try {
      final walletModel = _parseNwcUri(uri);
      if (walletModel != null) {
        BotToastUtils.showSuccess(
            mainContext.t.nwcInitialized.capitalizeFirst());
        addWalletAndSave(walletModel);
      }
    } catch (e) {
      _logError('Failed to add NWC wallet', e);
    }
  }

  NostrWalletConnectModel? _parseNwcUri(String uri) {
    try {
      final details = Uri.parse(uri);
      final walletPubKey = details.host;
      final relay = details.queryParameters['relay'] ?? '';
      final secret = details.queryParameters['secret'] ?? '';
      String lud16 = details.queryParameters['lud16'] ?? '';

      if (relay.isEmpty || secret.isEmpty) {
        BotToastUtils.showError(
            mainContext.t.invalidPairingSecret.capitalizeFirst());
        return null;
      }

      if (lud16.isEmpty) {
        lud16 = _generateLud16FromWalletPubkey(walletPubKey, relay);
        if (lud16.isEmpty) {
          return null;
        }
      }

      return NostrWalletConnectModel(
        id: uuid.v4(),
        kind: NostrWalletConnectKind,
        connectionString: uri,
        relay: relay,
        secret: secret,
        walletPubkey: walletPubKey,
        lud16: lud16,
        permissions: const <String>[],
      );
    } catch (e) {
      _logError('Failed to parse NWC URI', e);
      return null;
    }
  }

  String _generateLud16FromWalletPubkey(String walletPubKey, String relay) {
    final p = walletPubKey.substring(
        walletPubKey.length - 10, walletPubKey.length - 1);
    final parts = relay.split('.');

    if (parts.length < 2) {
      BotToastUtils.showError(
          mainContext.t.invalidPairingSecret.capitalizeFirst());
      return '';
    }

    final mainDomain = '${parts[parts.length - 2]}.${parts.last}';
    return '$p-$mainDomain';
  }

  Future<void> addAlby(String uri) async {
    try {
      final albyModel = await _createAlbyModel(uri);
      if (albyModel != null) {
        addWalletAndSave(albyModel);
      } else {
        BotToastUtils.showError(
            mainContext.t.errorSettingToken.capitalizeFirst());
      }
    } catch (e) {
      _logError('Failed to add Alby wallet', e);
    }
  }

  Future<AlbyConnectModel?> _createAlbyModel(String uri) async {
    final details = Uri.parse(uri);
    final code = details.queryParameters['code'];

    if (code == null) {
      return null;
    }

    final data = await HttpFunctionsRepository.handleAlbyApiToken(
      code: code,
      isRefreshing: false,
    );

    if (data.isEmpty) {
      return null;
    }

    final lud16 = await HttpFunctionsRepository.getAlbyLightningAddress(
      token: data['token'],
    );

    return AlbyConnectModel(
      id: uuid.v4(),
      kind: AlbyConnectKind,
      lud16: lud16,
      accessToken: data['token'],
      refreshToken: data['refreshToken'],
      expiry: data['expiresIn'],
      createdAt: data['createdAt'],
    );
  }

  void addWalletAndSave(WalletModel wallet) {
    final updatedWallets = Map<String, WalletModel>.from(state.wallets);
    updatedWallets[wallet.id] = wallet;

    _updateStateWithNewWallet(updatedWallets, wallet.id);
    _updateGlobalWalletsAndSave(updatedWallets);
    _requestBalanceForWallet(wallet);
  }

  void _updateStateWithNewWallet(
      Map<String, WalletModel> updatedWallets, String walletId) {
    if (!isClosed) {
      emit(state.copyWith(
        wallets: updatedWallets,
        selectedWalletId: walletId,
        shouldPopView: !state.shouldPopView,
      ));
    }
  }

  void _updateGlobalWalletsAndSave(Map<String, WalletModel> updatedWallets) {
    globalWallets[currentSigner!.getPublicKey()] =
        updatedWallets.values.toList();
    saveWalletsToSecureStorage();
  }

  void _requestBalanceForWallet(WalletModel wallet) {
    if (wallet is NostrWalletConnectModel) {
      requestNwcBalance(wallet);
    } else if (wallet is AlbyConnectModel) {
      requestAlbyBalance(wallet);
    }
  }

  Future<void> setSelectedWallet(String walletId, Function() onSuccess) async {
    final wallet = state.wallets[walletId];
    if (wallet == null) {
      return;
    }

    _updateSelectedWalletState(walletId);
    requestBalance();
    saveWalletsToSecureStorage();
    onSuccess.call();
  }

  void _updateSelectedWalletState(String walletId) {
    if (!isClosed) {
      emit(state.copyWith(
        selectedWalletId: walletId,
        balance: -1,
        maxAmount: -1,
      ));
    }
  }

  Future<void> removeWallet(String walletId, Function() onSuccess) async {
    try {
      final updatedWallets = Map<String, WalletModel>.from(state.wallets);
      updatedWallets.remove(walletId);

      if (walletId == state.selectedWalletId) {
        await _handleSelectedWalletRemoval(updatedWallets);
      } else {
        _updateWalletsState(updatedWallets);
      }

      _updateGlobalWalletsAndSave(updatedWallets);
      onSuccess.call();
    } catch (e) {
      _logError('Failed to remove wallet', e);
    }
  }

  Future<void> _handleSelectedWalletRemoval(
      Map<String, WalletModel> updatedWallets) async {
    if (updatedWallets.isEmpty) {
      _resetWalletState();
    } else {
      final newSelectedWallet = updatedWallets.entries.first;
      _updateWalletsState(updatedWallets, newSelectedWallet.key);
      await _requestBalanceForSelectedWallet(newSelectedWallet.value);
    }
  }

  void clearWallets() {
    deleteWalletConfiguration();
    globalWallets.clear();
    saveWalletsToSecureStorage();
  }

  void deleteWalletConfiguration() {
    if (!isClosed) {
      emit(
        WalletsManagerState.initial().copyWith(
          refresh: !state.refresh,
        ),
      );
    }
  }

  void switchWallets() {
    final selectedWallets = globalWallets[currentSigner!.getPublicKey()];

    if (selectedWallets != null && selectedWallets.isNotEmpty) {
      final wallets = _convertWalletsToMap(selectedWallets);
      _updateWalletsState(wallets);
      setSelectedWallet(wallets.entries.first.key, () {});
    } else {
      _resetWalletStateAndSave();
    }
  }

  Map<String, WalletModel> _convertWalletsToMap(List<WalletModel> walletsList) {
    final wallets = <String, WalletModel>{};
    for (final wallet in walletsList) {
      wallets[wallet.id] = wallet;
    }
    return wallets;
  }

  void _resetWalletStateAndSave() {
    if (!isClosed) {
      emit(state.copyWith(
        wallets: <String, WalletModel>{},
        selectedWalletId: '',
        balance: 0,
        balanceInFiat: 0,
      ));
    }
    saveWalletsToSecureStorage();
  }

  // =============================================================================
  // WALLET UTILITIES
  // =============================================================================

  Map<String, List<NostrWalletConnectModel>> getUserWallets(
    bool currentUser, {
    String? pubkey,
  }) {
    if (canSign() && currentUser) {
      return {
        currentSigner!.getPublicKey(): List<NostrWalletConnectModel>.from(
          state.wallets.values.whereType<NostrWalletConnectModel>(),
        )
      };
    } else {
      final wallets = <String, List<NostrWalletConnectModel>>{};

      if (pubkey != null) {
        final w = globalWallets[pubkey];

        if (w != null) {
          wallets[pubkey] = List<NostrWalletConnectModel>.from(
            w.whereType<NostrWalletConnectModel>(),
          );
        }
      } else {
        for (final list in globalWallets.entries) {
          wallets[list.key] = List<NostrWalletConnectModel>.from(
            list.value.whereType<NostrWalletConnectModel>(),
          );
        }
      }

      return wallets;
    }
  }

  String? getCurrentWalletLightningAddress() {
    final wallet = state.wallets[state.selectedWalletId];
    return wallet?.lud16;
  }

  Future<void> linkWallet(WalletModel wallet) async {
    final lud16 = wallet.lud16;
    if (!emailRegExp.hasMatch(lud16)) {
      BotToastUtils.showError(mainContext.t.walletNotLinked.capitalizeFirst());
      return;
    }

    final lud06 = Zap.getLnurlFromLud16(lud16);
    if (lud06 == null) {
      BotToastUtils.showError(mainContext.t.walletNotLinked.capitalizeFirst());
      return;
    }

    final metadata = nostrRepository.currentMetadata.copyWith(
      lud16: lud16,
      lud06: lud06,
    );

    final kind0Event = await Event.genEvent(
      content: metadata.toJson(),
      kind: 0,
      signer: currentSigner,
      tags: [],
    );

    if (kind0Event == null) {
      BotToastUtils.showError(
          mainContext.t.errorGeneratingEvent.capitalizeFirst());
      return;
    }

    final isSuccessful = await NostrFunctionsRepository.sendEvent(
      event: kind0Event,
      relays: currentUserRelayList.urls.toList(),
      setProgress: true,
    );

    if (isSuccessful) {
      BotToastUtils.showSuccess(mainContext.t.walletLinked.capitalizeFirst());
      nostrRepository.currentMetadata = metadata;
      nostrRepository.setCurrentSignerState(currentSigner);
      if (!isClosed) {
        _emitRefresh();
      }
      metadataCubit.saveMetadata(Metadata.fromEvent(kind0Event)!);
    } else {
      BotToastUtils.showError(
          mainContext.t.errorSendingEvent.capitalizeFirst());
    }
  }

  void setDefaultWallet(String defaultWallet) {
    if (!isClosed) {
      emit(state.copyWith(defaultExternalWallet: defaultWallet));
    }

    localDatabaseRepository.setDefaultWallet(defaultWallet);
  }

  void setUseDefaultWallet(bool useDefaultWallet) {
    if (!isClosed) {
      emit(state.copyWith(useDefaultWallet: useDefaultWallet));
    }

    localDatabaseRepository.setUseDefaultWallet(useDefaultWallet);
  }

  Future<void> launchUrl(bool isNwc) async {
    try {
      launchUrlString(
        isNwc ? YAKIHONNE_NWC_LINK : getYakihonneAlbyApiLink(),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      _logError('Failed to launch URL', e);
    }
  }

  String getYakihonneAlbyApiLink() {
    return 'https://getalby.com/oauth?client_id=${dotenv.env['CLIENT_ID']}&response_type=code&redirect_uri=$albyRedirectUri&scope=account:read%20invoices:create%20invoices:read%20transactions:read%20balance:read%20payments:send';
  }

  // =============================================================================
  // BALANCE & PRICING
  // =============================================================================

  void requestBalance() {
    final selectedWallet = state.wallets[state.selectedWalletId];
    if (selectedWallet != null) {
      _requestBalanceForWallet(selectedWallet);
    }
  }

  Future<void> requestNwcBalance(NostrWalletConnectModel wallet) async {
    try {
      final data = await performNwcAction(
        jsonEncode({'method': NWC_GET_BALANCE}),
        wallet,
      );

      if (_isValidBalanceResponse(data)) {
        _updateBalanceFromNwcResponse(data);
        getWalletBalanceInFiat();
      }
    } catch (e) {
      _logError('Failed to request NWC balance', e);
    }
  }

  bool _isValidBalanceResponse(Map<String, dynamic> data) {
    return data['result'] != null && data['result_type'] == NWC_GET_BALANCE;
  }

  void _updateBalanceFromNwcResponse(Map<String, dynamic> data) {
    if (!isClosed) {
      emit(state.copyWith(
        balance: (data['result']['balance'] / 1000 as num).toInt(),
        maxAmount: data['result']['max_amount'] != null
            ? (((data['result']['max_amount']) / 1000) as num).toInt()
            : 0,
        refresh: !state.refresh,
      ));
    }
  }

  Future<void> requestAlbyBalance(AlbyConnectModel albyConnectModel) async {
    try {
      final token = await checkAlbyWalletBeforeRequest(
        albyConnectModel: albyConnectModel,
      );

      if (token != null) {
        final balance =
            await HttpFunctionsRepository.getAlbyBalance(token: token);
        _updateBalanceFromAlbyResponse(balance);
        getWalletBalanceInFiat();
      } else {
        _resetBalance();
      }
    } catch (e) {
      _logError('Failed to request Alby balance', e);
      _resetBalance();
    }
  }

  void _updateBalanceFromAlbyResponse(num balance) {
    if (!isClosed) {
      emit(state.copyWith(
        balance: balance >= 0 ? balance.toInt() : -1,
        maxAmount: balance >= 0 ? balance.toInt() : -1,
      ));
    }
  }

  void _resetBalance() {
    if (!isClosed) {
      emit(state.copyWith(
        balance: -1,
        maxAmount: -1,
      ));
    }
  }

  Future<String?> checkAlbyWalletBeforeRequest({
    required AlbyConnectModel albyConnectModel,
  }) async {
    if ((currentUnixTimestampSeconds()) >
        (albyConnectModel.createdAt + albyConnectModel.expiry)) {
      final Map<String, dynamic> data =
          await HttpFunctionsRepository.handleAlbyApiToken(
        code: albyConnectModel.refreshToken,
        isRefreshing: true,
      );

      if (data.isNotEmpty) {
        final AlbyConnectModel newAlbyConnectModel = albyConnectModel.copyWith(
          accessToken: data['token'],
          refreshToken: data['refreshToken'],
          expiry: data['expiresIn'],
          createAt: data['createdAt'],
        );

        final Map<String, WalletModel> updateWallets =
            Map<String, WalletModel>.from(state.wallets);
        updateWallets[newAlbyConnectModel.id] = newAlbyConnectModel;
        if (!isClosed) {
          emit(state.copyWith(
            wallets: updateWallets,
            selectedWalletId: newAlbyConnectModel.id,
          ));
        }

        globalWallets[currentSigner!.getPublicKey()] =
            updateWallets.values.toList();
        saveWalletsToSecureStorage();
        return newAlbyConnectModel.accessToken;
      } else {
        return null;
      }
    } else {
      return albyConnectModel.accessToken;
    }
  }

  void setActiveFiat(String fiat) {
    if (!isClosed) {
      emit(state.copyWith(activeCurrency: fiat));
    }

    localDatabaseRepository.setActiveCurrency(fiat);
    getSatsToFiat();
  }

  void getWalletBalanceInFiat() {
    if (state.balance == -1) {
      _updateFiatBalance(-1);
    } else if (state.balance == 0) {
      _updateFiatBalance(0);
    } else {
      getSatsToFiat();
    }
  }

  void _updateFiatBalance(double fiatBalance) {
    if (!isClosed) {
      emit(state.copyWith(balanceInFiat: fiatBalance));
    }
  }

  Future<void> getBtcInFiat() async {
    try {
      final res = await HttpFunctionsRepository.get(
        'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=${currencies.keys.join(',')}',
      );

      if (res != null) {
        final data = res['bitcoin'];
        for (final f in currencies.keys) {
          btcInFiat[f] = (data[f] as int?) ?? -1;
        }
      }
    } catch (e) {
      _logError('Failed to get BTC price', e);
    }
  }

  double getBtcInFiatFromAmount(int amount) {
    final current = btcInFiat[state.activeCurrency];
    if (current == null || current == 0) {
      return -1;
    } else {
      final availableBTC = amount / 100000000;
      return availableBTC * current;
    }
  }

  double getFiatInBtcFromAmount(int amount) {
    final current = btcInFiat[state.activeCurrency];
    if (current == null || current == 0) {
      return -1;
    } else {
      final availableBTC = amount * 100000000;
      return availableBTC / current;
    }
  }

  Future<void> getSatsToFiat() async {
    final current = btcInFiat[state.activeCurrency];
    if (current == null || current == 0) {
      _updateFiatBalance(-1);
    } else {
      final availableBTC = state.balance / 100000000;
      _updateFiatBalance(availableBTC * current);
    }
  }

  // =============================================================================
  // TRANSACTIONS
  // =============================================================================

  Future<void> getTransactions({bool isAdding = false}) async {
    if (state.selectedWalletId.isEmpty) {
      return;
    }

    _setTransactionLoadingState(isAdding);

    final selectedWallet = state.wallets[state.selectedWalletId];

    if (selectedWallet is NostrWalletConnectModel) {
      await _getNwcTransactions(selectedWallet, isAdding);
    } else if (selectedWallet is AlbyConnectModel) {
      await _getAlbyTransactions(selectedWallet, isAdding);
    } else {
      _handleTransactionError();
    }
  }

  void _setTransactionLoadingState(bool isAdding) {
    if (!isClosed) {
      emit(
        state.copyWith(
          transactionsState:
              isAdding ? UpdatingState.progress : UpdatingState.success,
          isLoadingTransactions: !isAdding,
          transactions: isAdding ? null : <WalletTransactionModel>[],
        ),
      );
    }
  }

  Future<void> _getNwcTransactions(
      NostrWalletConnectModel wallet, bool isAdding) async {
    int? last;

    if (isAdding) {
      last = state.transactions.isNotEmpty
          ? state.transactions.last.createdAt.toSecondsSinceEpoch() - 1
          : null;
    }

    final data = await performNwcAction(
      jsonEncode({
        'method': NWC_TRANSACTIONS_LIST,
        'params': {
          'limit': 10,
          if (last != null) 'until': last,
        }
      }),
      wallet,
    );

    if (data['result'] != null &&
        ((data['result']['transactions'] as List?)?.isNotEmpty ?? false) &&
        data['result_type'] == NWC_TRANSACTIONS_LIST) {
      final transactions = getNwcWalletTransactions(
        data['result']['transactions'],
      );

      _updateTransactionsState(transactions, isAdding);
    } else {
      _updateTransactionsState([], isAdding);
    }
  }

  Future<void> _getAlbyTransactions(
      AlbyConnectModel wallet, bool isAdding) async {
    final token = await checkAlbyWalletBeforeRequest(albyConnectModel: wallet);

    if (token != null) {
      int? page;

      if (isAdding) {
        page = state.transactions.isNotEmpty
            ? (state.transactions.length / 10).ceil()
            : null;
      }

      final transactions = await HttpFunctionsRepository.getAlbyTransactions(
        token: token,
        page: page,
      );

      _updateTransactionsState(transactions, isAdding);
    } else {
      _updateTransactionsState([], isAdding);
    }
  }

  void _updateTransactionsState(
    List<WalletTransactionModel> transactions,
    bool isAdding,
  ) {
    List<WalletTransactionModel> tList = [];

    if (isAdding) {
      final previousTransactions = List<WalletTransactionModel>.from(
        state.transactions,
      );

      tList = [...previousTransactions, ...transactions];
    } else {
      tList = transactions;
    }

    if (!isClosed) {
      emit(state.copyWith(
        transactions: tList,
        isLoadingTransactions: false,
        transactionsState:
            transactions.isEmpty ? UpdatingState.idle : UpdatingState.success,
      ));
    }
  }

  void _handleTransactionError() {
    BotToastUtils.showError(mainContext.t.errorUsingWallet.capitalizeFirst());
    if (!isClosed) {
      emit(
        state.copyWith(
          transactionsState: UpdatingState.idle,
          isLoadingTransactions: false,
          transactions: [],
        ),
      );
    }
  }

  List<WalletTransactionModel> getNwcWalletTransactions(List transactionsData) {
    // Implementation depends on your WalletTransactionModel structure
    // This is a placeholder that should be implemented based on your model
    return transactionsData
        .map((data) => WalletTransactionModel.fromNwcMap(data))
        .toList();
  }

  // =============================================================================
  // PAYMENTS & ZAPS
  // =============================================================================

  Future<void> sendUsingLightningAddress({
    required String lightningAddress,
    required int sats,
    required String message,
    required Function() onSuccess,
    Function(String)? onFailure,
    String? eventId,
    String? aTag,
    Metadata? user,
    bool? removeSuccess,
  }) async {
    if (sats == 0 ||
        (!lightningAddress.contains('@') &&
            !lightningAddress.startsWith('lnurl'))) {
      BotToastUtils.showError(mainContext.t.submitValidData.capitalizeFirst());
      return;
    }

    final destination = await wnc.db.loadUserRelayList(user?.pubkey ?? '');
    final relays = <String>[
      ...(destination?.reads ?? <String>[]),
      ...currentUserRelayList.reads
    ];

    if (!isClosed) {
      emit(state.copyWith(isLoading: true));
    }

    final invoice = await ZapAction.genInvoiceCode(
      sats,
      user != null
          ? user.copyWith(
              lud16: lightningAddress,
              lud06: lightningAddress,
            )
          : Metadata.empty().copyWith(
              lud16: lightningAddress,
              lud06: lightningAddress,
            ),
      currentSigner!,
      relays,
      comment: message.isEmpty ? null : message,
      removeNostrEvent: user == null,
      aTag: aTag,
      eventId: eventId,
    );

    if (invoice == null) {
      BotToastUtils.showError(
        mainContext.t.errorGeneratingInvoice.capitalizeFirst(),
      );

      if (!isClosed) {
        emit(state.copyWith(isLoading: false));
      }
    } else {
      sendUsingInvoice(
        invoice: invoice,
        onSuccess: onSuccess,
        removeSuccess: removeSuccess,
        user: user,
        onFailure: onFailure,
      );
    }
  }

  Future<void> sendUsingInvoice({
    required MapEntry<String, Event?> invoice,
    required Function() onSuccess,
    Metadata? user,
    bool? removeSuccess,
    Function(String)? onFailure,
    Function(bool)? onFinished,
    bool useDefaultWallet = false,
  }) async {
    if (invoice.key.isEmpty || !invoice.key.toLowerCase().startsWith('lnbc')) {
      final message = mainContext.t.submitValidInvoice.capitalizeFirst();
      _handlePaymentFailure(onFailure, message);
      return;
    }

    if (state.selectedWalletId.isEmpty) {
      return;
    }

    _setPaymentLoadingState();

    if (useDefaultWallet) {
      final isSuccess = await ZapAction.forwardInvoice(
        invoice: invoice.key,
        specifiedWallet: wallets[state.defaultExternalWallet]!['deeplink']!,
      );

      if (!isSuccess) {
        onFailure?.call(
          mainContext.t.unreachableExternalWallet.capitalizeFirst(),
        );
      } else {
        onFinished?.call(isSuccess);
      }
    } else {
      final selectedWallet = state.wallets[state.selectedWalletId];

      if (selectedWallet is NostrWalletConnectModel) {
        await _processNwcPayment(
          selectedWallet,
          invoice,
          onSuccess,
          onFailure,
          removeSuccess,
        );
      } else if (selectedWallet is AlbyConnectModel) {
        await _processAlbyPayment(
          selectedWallet,
          invoice,
          onSuccess,
          onFailure,
        );
      } else {
        final message = mainContext.t.errorUsingWallet.capitalizeFirst();
        _handlePaymentFailure(onFailure, message);
      }
    }

    _setPaymentLoadingState(false);
  }

  void _setPaymentLoadingState([bool loading = true]) {
    if (!isClosed) {
      emit(state.copyWith(isLoading: loading));
    }
  }

  Future<void> _processNwcPayment(
    NostrWalletConnectModel wallet,
    MapEntry<String, Event?> invoice,
    Function() onSuccess,
    Function(String)? onFailure,
    bool? removeSuccess,
  ) async {
    final ev = invoice.value;
    final data = await performNwcAction(
      jsonEncode({
        'method': NWC_PAY_INVOICE,
        'params': {
          'invoice': invoice.key,
          if (ev != null)
            'metadata': {
              'comment': ev.content,
              'zap_request': ev.toJson(),
            },
        },
      }),
      wallet,
    );

    if (data['result'] != null &&
        data['result']['preimage'] != null &&
        (data['result']['preimage'] as String).isNotEmpty) {
      if (removeSuccess == null) {
        BotToastUtils.showSuccess(
            mainContext.t.paymentSucceeded.capitalizeFirst());
      }
      onSuccess.call();
      requestBalance();
    } else {
      final message = mainContext.t.paymentFailedInvoice.capitalizeFirst();
      _handlePaymentFailure(onFailure, message);
    }
  }

  Future<void> _processAlbyPayment(
    AlbyConnectModel wallet,
    MapEntry<String, Event?> invoice,
    Function() onSuccess,
    Function(String)? onFailure,
  ) async {
    final token = await checkAlbyWalletBeforeRequest(albyConnectModel: wallet);
    if (token != null) {
      final data = await HttpFunctionsRepository.sendAlbyPayment(
        token: token,
        invoice: invoice.key,
      );

      if (data.isNotEmpty) {
        requestBalance();
        onSuccess.call();
      } else {
        final message = mainContext.t.paymentFailedInvoice.capitalizeFirst();
        _handlePaymentFailure(onFailure, message);
      }
    } else {
      final message = mainContext.t.errorUsingWallet.capitalizeFirst();
      _handlePaymentFailure(onFailure, message);
    }
  }

  void _handlePaymentFailure(Function(String)? onFailure, String message) {
    if (onFailure != null) {
      onFailure.call(message);
    } else {
      BotToastUtils.showError(message);
    }
  }

  // =============================================================================
  // ZAP SPLITS & INVOICE GENERATION
  // =============================================================================

  void resetInvoice() {
    _appLifeCycle?.cancel();
    _appLifeCycle = null;
    index = -1;
    zapsToPoints.clear();

    if (!isClosed) {
      emit(
        state.copyWith(
          lnurl: '',
          isLnurlAvailable: false,
          areInvoicesAvailable: false,
          selectedIndex: -1,
          confirmPayment: false,
          invoices: <String, String?>{},
          isLoading: false,
        ),
      );
    }
  }

  Future<void> getInvoices({
    required num currentZapValue,
    required List<ZapSplit> zapSplits,
    required String comment,
    String? eventId,
    String? aTag,
    Function(String)? onFailure,
  }) async {
    try {
      _setInvoiceLoadingState();
      zapsToPoints.clear();

      final futures = zapSplits.map((ZapSplit e) async {
        final num satsAmount = getSpecificZapValue(
          currentZapValue: currentZapValue,
          zaps: zapSplits,
          currentZap: e,
        );

        final metadata = await metadataCubit.getCachedMetadata(e.pubkey) ??
            Metadata.empty().copyWith(pubkey: e.pubkey);

        zapsToPoints.add(ZapsToPoints(
          pubkey: metadata.pubkey,
          actionTimeStamp: currentUnixTimestampSeconds(),
          sats: satsAmount,
          eventId: eventId,
        ));

        final destination = await wnc.db.loadUserRelayList(metadata.pubkey);
        final List<String> relays = <String>[
          ...(destination?.reads ?? <String>[]),
          ...currentUserRelayList.reads
        ];

        return ZapAction.genInvoiceCode(
          satsAmount,
          metadata,
          currentSigner!,
          relays,
          eventId: eventId,
          aTag: aTag,
          comment: comment.isEmpty ? null : comment,
        );
      }).toList();

      final res = await Future.wait(futures);

      final Map<String, String?> invoices = <String, String?>{};

      for (int i = 0; i < zapSplits.length; i++) {
        invoices[zapSplits[i].pubkey] = res[i]?.key;
      }

      _updateInvoicesState(invoices, currentZapValue, onFailure);
    } catch (e) {
      onFailure?.call(
        mainContext.t.errorGeneratingInvoice.capitalizeFirst(),
      );
    }
  }

  void _setInvoiceLoadingState() {
    if (!isClosed) {
      emit(state.copyWith(isLoading: true));
    }
  }

  void _updateInvoicesState(
    Map<String, String?> invoices,
    num currentZapValue,
    Function(String)? onFailure,
  ) {
    final areInvoicesAvailable = invoices.values.any(
      (invoice) => invoice != null,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          isLoading: false,
          areInvoicesAvailable: areInvoicesAvailable,
          invoices: areInvoicesAvailable ? invoices : null,
          toBeZappedValue: currentZapValue,
        ),
      );
    }

    if (!areInvoicesAvailable) {
      onFailure?.call(
        mainContext.t.errorGeneratingInvoice.capitalizeFirst(),
      );
    }
  }

  num getSpecificZapValue({
    required num currentZapValue,
    required List<ZapSplit> zaps,
    required ZapSplit currentZap,
  }) {
    if (zaps.isEmpty) {
      return 0;
    }

    num total = 0;
    for (final zap in zaps) {
      total += zap.percentage;
    }

    if (total == 0) {
      return 0;
    } else {
      return ((currentZap.percentage * 100 / total).round()) *
          currentZapValue /
          100;
    }
  }

  void handleWalletZapSplit({
    required Function() onFinished,
    Function(String)? onSuccess,
    Function(String)? onFailure,
    bool useDefaultWallet = false,
  }) {
    if (state.selectedWalletId.isNotEmpty && !useDefaultWallet) {
      final selectedWallet = state.wallets[state.selectedWalletId];

      if (selectedWallet != null) {
        if (!_validateZapAmount()) {
          return;
        }

        handleInternalWalletZapSplit(
          onFailure: onFailure,
          onSuccess: onSuccess,
          walletModel: selectedWallet,
        );
      } else {
        onFailure?.call(
          mainContext.t.errorUsingWallet.capitalizeFirst(),
        );
      }
    } else {
      index = 0;
      handleExternalWalletZapSplit(
        onFinished: onFinished,
        onFailure: onFailure,
      );
    }
  }

  bool _validateZapAmount() {
    if (state.balance > 0 && state.toBeZappedValue > (state.balance)) {
      BotToastUtils.showError(mainContext.t.notEnoughBalance.capitalizeFirst());
      return false;
    }

    if (state.maxAmount > 0 && state.toBeZappedValue > state.maxAmount) {
      BotToastUtils.showError(
          mainContext.t.paymentSurpassMax.capitalizeFirst());
      return false;
    }

    return true;
  }

  Future<void> handleInternalWalletZapSplit({
    Function(String)? onSuccess,
    Function(String)? onFailure,
    required WalletModel walletModel,
  }) async {
    _setZapSplitLoadingState();

    final invoices = state.invoices.values.toList();
    final invoicesList = <Map<String, dynamic>>[];

    if (walletModel is NostrWalletConnectModel) {
      await _processNwcZapSplit(invoices, walletModel, invoicesList);
    } else {
      await _processAlbyZapSplit(
        invoices,
        walletModel as AlbyConnectModel,
        invoicesList,
      );
    }

    _handleZapSplitResults(
      invoicesList,
      invoices,
      walletModel,
      onSuccess: onSuccess,
      onFailure: onFailure,
    );

    _setZapSplitLoadingState(false);
  }

  void _setZapSplitLoadingState([bool loading = true]) {
    if (!isClosed) {
      emit(state.copyWith(isLoading: loading));
    }
  }

  Future<void> _processNwcZapSplit(
    List<String?> invoices,
    NostrWalletConnectModel walletModel,
    List<Map<String, dynamic>> invoicesList,
  ) async {
    for (int i = 0; i < invoices.length; i++) {
      final String? invoice = invoices[i];

      if (!StringUtil.isBlank(invoice)) {
        final data = await performNwcAction(
          jsonEncode({
            'method': NWC_PAY_INVOICE,
            'params': {'invoice': invoice},
          }),
          walletModel,
        );

        invoicesList.add(data);
      }
    }
  }

  Future<void> _processAlbyZapSplit(
    List<String?> invoices,
    AlbyConnectModel walletModel,
    List<Map<String, dynamic>> invoicesList,
  ) async {
    final String? token = await checkAlbyWalletBeforeRequest(
      albyConnectModel: walletModel,
    );

    if (token != null) {
      for (int i = 0; i < invoices.length; i++) {
        final String? invoice = invoices[i];
        if (!StringUtil.isBlank(invoice)) {
          final Map<String, dynamic> data =
              await HttpFunctionsRepository.sendAlbyPayment(
            token: token,
            invoice: invoice!,
          );

          if (data.isNotEmpty) {
            invoicesList.add(data);
          }
        }
      }
    }
  }

  void _handleZapSplitResults(
    List<Map<String, dynamic>> invoicesList,
    List<String?> invoices,
    WalletModel walletModel, {
    Function(String)? onSuccess,
    Function(String)? onFailure,
  }) {
    bool partiallyBeenZapped = false;
    int paidInvoices = 0;

    if (invoicesList.isNotEmpty) {
      for (final Map<String, dynamic> resp in invoicesList) {
        if (walletModel is NostrWalletConnectModel) {
          if (resp.isNotEmpty &&
              resp['result'] != null &&
              resp['result']['preimage'] != null) {
            partiallyBeenZapped = true;
            paidInvoices++;
          }
        } else {
          if (resp.isNotEmpty &&
              resp['payment_preimage'] != null &&
              (resp['payment_preimage'] as String).isNotEmpty) {
            partiallyBeenZapped = true;
            paidInvoices++;
          }
        }
      }

      _showZapSplitResult(
        paidInvoices,
        invoices.length,
        partiallyBeenZapped,
        onSuccess: onSuccess,
        onFailure: onFailure,
      );
    } else {
      onFailure?.call(
        mainContext.t.errorZappingUsers.capitalizeFirst(),
      );
    }
  }

  void _showZapSplitResult(
    int paidInvoices,
    int totalInvoices,
    bool partiallyBeenZapped, {
    Function(String)? onSuccess,
    Function(String)? onFailure,
  }) {
    if (paidInvoices == totalInvoices) {
      onSuccess?.call(mainContext.t.allUsersZapped.capitalizeFirst());
      pointsManagementCubit.checkZapsToPoints(zapsToPoints: zapsToPoints);
    } else if (partiallyBeenZapped) {
      onSuccess?.call(mainContext.t.partialUsersZapped.capitalizeFirst());
      pointsManagementCubit.checkZapsToPoints(zapsToPoints: zapsToPoints);
    } else {
      onFailure?.call(mainContext.t.noUserZapped.capitalizeFirst());
    }
  }

  void handleExternalWalletZapSplit({
    required Function() onFinished,
    Function(String)? onFailure,
  }) {
    _setZapSplitLoadingState();

    final List<String?> invoices = state.invoices.values.toList();
    for (int i = 0; i < invoices.length; i++) {
      if (!StringUtil.isBlank(invoices[i])) {
        index = i;
        break;
      }
    }

    if (index == -1) {
      onFailure?.call(
        mainContext.t.noInvoiceAvailable.capitalizeFirst(),
      );

      _setZapSplitLoadingState(false);
      return;
    }

    pointsManagementCubit.checkZapsToPoints(zapsToPoints: zapsToPoints);

    ZapAction.handleExternalZap(
      invoices[index],
      specifiedWallet: wallets[state.defaultExternalWallet]!['deeplink'],
    );

    _setupExternalZapSplitLifecycleListener(invoices, onFinished);
  }

  void _setupExternalZapSplitLifecycleListener(
    List<String?> invoices,
    Function() onFinished,
  ) {
    _appLifeCycle = _appLifecycleNotifier.lifecycleStream.listen(
      (AppLifecycleState appState) {
        if (appState == AppLifecycleState.resumed) {
          if (index == (invoices.length - 1)) {
            _cleanupExternalZap();
            BotToastUtils.showSuccess(
              mainContext.t.processCompleted.capitalizeFirst(),
            );
            onFinished.call();
            return;
          } else {
            _processNextExternalZap(invoices);
          }
        }
      },
    );
  }

  void _cleanupExternalZap() {
    index = -1;
    _appLifeCycle?.cancel();
    _appLifeCycle = null;
    _setZapSplitLoadingState(false);
  }

  void _processNextExternalZap(List<String?> invoices) {
    for (int i = index + 1; i < invoices.length; i++) {
      index = i;
      if (!StringUtil.isBlank(invoices[i])) {
        ZapAction.handleExternalZap(
          invoices[index],
          specifiedWallet: wallets[state.defaultExternalWallet]!['deeplink'],
        );
        return;
      }
    }
  }

  // =============================================================================
  // INDIVIDUAL ZAP HANDLING
  // =============================================================================

  Future<void> handleWalletZapWithExternalInvoice({
    required String invoice,
    Function()? onSuccess,
  }) async {
    if (state.selectedWalletId.isNotEmpty) {
      final WalletModel? selectedWallet = state.wallets[state.selectedWalletId];

      if (selectedWallet != null) {
        await _processExternalInvoicePayment(
          selectedWallet,
          invoice,
          onSuccess,
        );
      } else {
        BotToastUtils.showError(
          mainContext.t.errorUsingWallet.capitalizeFirst(),
        );
      }
    } else {
      await _handleExternalWalletInvoicePayment(invoice);
    }
  }

  Future<void> _processExternalInvoicePayment(
    WalletModel selectedWallet,
    String invoice,
    Function()? onSuccess,
  ) async {
    final cancel = BotToastUtils.showLoading();

    try {
      if (selectedWallet is NostrWalletConnectModel) {
        await _processNwcExternalInvoice(selectedWallet, invoice, onSuccess);
      } else {
        await _processAlbyExternalInvoice(
          selectedWallet as AlbyConnectModel,
          invoice,
          onSuccess,
        );
      }
    } finally {
      cancel.call();
    }
  }

  Future<void> _processNwcExternalInvoice(
    NostrWalletConnectModel wallet,
    String invoice,
    Function()? onSuccess,
  ) async {
    final Map<String, dynamic> data = await performNwcAction(
      jsonEncode({
        'method': NWC_PAY_INVOICE,
        'params': {'invoice': invoice}
      }),
      wallet,
    );

    if (data.isNotEmpty &&
        data['result'] != null &&
        data['result']['preimage'] != null) {
      onSuccess?.call();
      BotToastUtils.showSuccess(mainContext.t.invoicePaid.capitalizeFirst());
    } else {
      BotToastUtils.showError(
          mainContext.t.errorPayingInvoice.capitalizeFirst());
    }
  }

  Future<void> _processAlbyExternalInvoice(
    AlbyConnectModel wallet,
    String invoice,
    Function()? onSuccess,
  ) async {
    final token = await checkAlbyWalletBeforeRequest(albyConnectModel: wallet);

    if (token != null) {
      final data = await HttpFunctionsRepository.sendAlbyPayment(
        token: token,
        invoice: invoice,
      );

      if (data.isNotEmpty) {
        onSuccess?.call();
        BotToastUtils.showSuccess(mainContext.t.invoicePaid.capitalizeFirst());
      } else {
        BotToastUtils.showError(
            mainContext.t.errorPayingInvoice.capitalizeFirst());
      }
    }
  }

  Future<void> _handleExternalWalletInvoicePayment(String invoice) async {
    try {
      await ZapAction.handleExternalZap(
        invoice,
        specifiedWallet: wallets[state.defaultExternalWallet]!['deeplink'],
      );
    } catch (_) {
      BotToastUtils.showError(
          mainContext.t.errorUsingExternalWallet.capitalizeFirst());
    }
  }

  void handleWalletZap({
    required num sats,
    required Metadata user,
    required String comment,
    required Function(String) onFailure,
    required Function(String) onSuccess,
    required Function(bool) onFinished,
    String? eventId,
    String? aTag,
    String? pollOption,
    String? invoice,
    bool useExternalWallet = false,
  }) {
    if (state.selectedWalletId.isNotEmpty && !useExternalWallet) {
      final selectedWallet = state.wallets[state.selectedWalletId];
      if (selectedWallet != null) {
        if (!_validateSingleZapAmount(sats, onFailure)) {
          return;
        }

        handleInternalWalletZap(
          sats: sats,
          user: user,
          comment: comment,
          eventId: eventId,
          aTag: aTag,
          onFailure: onFailure,
          onSuccess: onSuccess,
          walletModel: selectedWallet,
          pollOption: pollOption,
        );
      } else {
        onFailure.call(mainContext.t.errorUsingWallet.capitalizeFirst());
      }
    } else {
      handleExternalWalletZap(
        sats: sats,
        user: user,
        comment: comment,
        eventId: eventId,
        aTag: aTag,
        onFailure: onFailure,
        onFinished: onFinished,
        pollOption: pollOption,
      );
    }
  }

  bool _validateSingleZapAmount(num sats, Function(String) onFailure) {
    if (sats > (state.balance)) {
      onFailure.call(mainContext.t.notEnoughBalance.capitalizeFirst());
      return false;
    }

    if (state.maxAmount != 0 && sats > state.maxAmount) {
      onFailure.call(mainContext.t.paymentSurpassMax.capitalizeFirst());
      return false;
    }

    return true;
  }

  Future<void> handleInternalWalletZap({
    required num sats,
    required Metadata user,
    required String comment,
    required WalletModel walletModel,
    required Function(String) onFailure,
    required Function(String) onSuccess,
    String? eventId,
    String? aTag,
    String? pollOption,
    String? externalInvoice,
  }) async {
    _setZapLoadingState();

    final destination = await wnc.db.loadUserRelayList(user.pubkey);
    final relays = <String>[
      ...(destination?.reads ?? <String>[]),
      ...currentUserRelayList.urls
    ];

    final invoice =
        (externalInvoice != null ? MapEntry(externalInvoice, null) : null) ??
            await ZapAction.genInvoiceCode(
              sats,
              user,
              currentSigner!,
              relays,
              comment: comment.isEmpty ? null : comment,
              eventId: eventId,
              aTag: aTag,
              pollOption: pollOption,
            );

    if (invoice != null) {
      if (walletModel is NostrWalletConnectModel) {
        await _processNwcZap(
          walletModel,
          invoice,
          sats,
          onSuccess,
          onFailure,
        );
      } else {
        await _processAlbyZap(
          walletModel as AlbyConnectModel,
          invoice,
          sats,
          onSuccess,
          onFailure,
        );
      }
    } else {
      onFailure.call(mainContext.t.errorGeneratingInvoice.capitalizeFirst());
    }

    _setZapLoadingState(false);
  }

  void _setZapLoadingState([bool loading = true]) {
    if (!isClosed) {
      emit(state.copyWith(isLoading: loading));
    }
  }

  Future<void> _processNwcZap(
    NostrWalletConnectModel walletModel,
    MapEntry<String, Event?> invoice,
    num sats,
    Function(String) onSuccess,
    Function(String) onFailure,
  ) async {
    final data = await performNwcAction(
      jsonEncode({
        'method': NWC_PAY_INVOICE,
        'params': {'invoice': invoice.key}
      }),
      walletModel,
    );

    if (data.isNotEmpty &&
        data['result'] != null &&
        data['result']['preimage'] != null) {
      pointsManagementCubit.sendZapsPoints(sats);
      requestBalance();
      onSuccess.call(invoice.key.toLowerCase());
    } else {
      final errorMessage = data.isNotEmpty && data['error'] != null
          ? (data['error']?['message'] ??
              mainContext.t.errorSendingSats.capitalizeFirst())
          : mainContext.t.errorSendingSats.capitalizeFirst();

      onFailure.call(errorMessage);
    }
  }

  Future<void> _processAlbyZap(
    AlbyConnectModel walletModel,
    MapEntry<String, Event?> invoice,
    num sats,
    Function(String) onSuccess,
    Function(String) onFailure,
  ) async {
    final token =
        await checkAlbyWalletBeforeRequest(albyConnectModel: walletModel);

    if (token != null) {
      final data = await HttpFunctionsRepository.sendAlbyPayment(
        token: token,
        invoice: invoice.key,
      );

      if (data.isNotEmpty) {
        pointsManagementCubit.sendZapsPoints(sats);
        onSuccess.call(data['payment_preimage']);
      } else {
        onFailure.call(mainContext.t.errorSendingSats.capitalizeFirst());
      }
    }
  }

  Future<void> handleExternalWalletZap({
    required num sats,
    required Metadata user,
    required String comment,
    required Function(String) onFailure,
    required Function(bool) onFinished,
    String? eventId,
    String? aTag,
    String? pollOption,
    String? externalInvoice,
  }) async {
    if (state.defaultExternalWallet.isEmpty) {
      onFailure.call(mainContext.t.selectDefaultWallet.capitalizeFirst());
      return;
    }

    _setZapLoadingState();

    await ZapAction.handleZap(
      sats,
      user,
      comment: comment.isEmpty ? null : comment,
      eventId: eventId,
      aTag: aTag,
      pollOption: pollOption,
      currentSigner!,
      currentUserRelayList.reads,
      specifiedWallet: wallets[state.defaultExternalWallet]!['deeplink'],
      onZapped: (invoice, isSuccessful) {
        _setZapLoadingState(false);

        if (!isSuccessful) {
          onFailure.call(
            mainContext.t.unreachableExternalWallet.capitalizeFirst(),
          );

          return;
        }

        if (invoice.isEmpty) {
          onFailure.call(
            mainContext.t.errorGeneratingInvoice.capitalizeFirst(),
          );

          return;
        }

        if (!isClosed) {
          emit(state.copyWith(confirmPayment: true));
        }

        final invoiceRecord = LightningInvoice(
          id: uuid.v4(),
          invoice: invoice,
          paymentHash: invoice.hashCode.toString(),
          amountSats: sats.toInt(),
          recipientPubkey: user.pubkey,
          eventId: eventId,
          aTag: aTag,
          comment: comment.isEmpty ? null : comment,
          createdAt: DateTime.now(),
          currentPubkey: currentSigner?.getPublicKey() ?? '',
        );

        unprocessedInvoices.add(invoiceRecord);
        onFinished.call(true);
      },
    );
  }

  Future<void> processUnprocessedInvoices() async {
    await Future.delayed(const Duration(seconds: 2));
    if (unprocessedInvoices.isNotEmpty) {
      final invoicesToProcess = List<LightningInvoice>.from(
        unprocessedInvoices,
      );

      for (final invoice in invoicesToProcess) {
        _processUnprocessedInvoice(invoice);
      }
    }
  }

  Future<void> _processUnprocessedInvoice(LightningInvoice invoice) async {
    final id = invoice.eventId ?? invoice.aTag ?? '';

    final ev = await fetchZapReceiptInBackground(
      eventId: id,
      receiverPubkey: invoice.recipientPubkey,
      isIdentifier: invoice.aTag != null,
    );

    if (ev != null) {
      final zap = invoice.toSubmitZap();

      if (zap != null) {
        notesEventsCubit.addEventRelatedData(
          event: ev,
          replyNoteId: zap.key,
        );
      }

      pointsManagementCubit.checkZapsToPoints(
        zapsToPoints: <ZapsToPoints>[
          ZapsToPoints(
            pubkey: invoice.currentPubkey,
            actionTimeStamp: currentUnixTimestampSeconds(),
            sats: invoice.amountSats,
            eventId: invoice.eventId ?? invoice.aTag,
          ),
        ],
      );
    }

    unprocessedInvoices.remove(invoice);
  }

  Future<Event?> fetchZapReceiptInBackground({
    required String eventId,
    required String receiverPubkey,
    required bool isIdentifier,
  }) async {
    const maxAttempts = 2;
    const delays = [2000, 10000];

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(Duration(milliseconds: delays[attempt]));

      final event = await NostrFunctionsRepository.getZapEvent(
        eventId: eventId,
        pTag: receiverPubkey,
        isIdentifier: isIdentifier,
      );

      if (event != null) {
        return event;
      }
    }

    return null;
  }

  Future<void> generateZapInvoice({
    required int sats,
    required Metadata user,
    required String comment,
    required Function(String) onFailure,
    Function(String)? onSuccess,
    String? eventId,
    bool? removeNostrEvent,
  }) async {
    if (sats == 0) {
      BotToastUtils.showError(
        mainContext.t.setSatsMoreThanZero.capitalizeFirst(),
      );

      return;
    }

    _setInvoiceGenerationLoadingState();

    final destination = await wnc.db.loadUserRelayList(user.pubkey);
    final List<String> relays = <String>[
      ...(destination?.reads ?? <String>[]),
      ...currentUserRelayList.reads
    ];

    final code = await ZapAction.genInvoiceCode(
      sats,
      user,
      currentSigner!,
      eventId: eventId,
      comment: comment.isEmpty ? null : comment,
      relays,
      removeNostrEvent: removeNostrEvent,
    );

    _setInvoiceGenerationLoadingState(false);

    if (code == null) {
      onFailure.call(mainContext.t.errorGeneratingInvoice.capitalizeFirst());
      return;
    }

    _updateInvoiceGenerationState(code.key);

    pointsManagementCubit.checkZapsToPoints(
      zapsToPoints: <ZapsToPoints>[
        ZapsToPoints(
          pubkey: user.pubkey,
          actionTimeStamp: currentUnixTimestampSeconds(),
          sats: sats,
          eventId: eventId,
        ),
      ],
    );

    onSuccess?.call(code.key);
  }

  void _setInvoiceGenerationLoadingState([bool loading = true]) {
    if (!isClosed) {
      emit(state.copyWith(isLoading: loading));
    }
  }

  void _updateInvoiceGenerationState(String lnurl) {
    if (!isClosed) {
      emit(state.copyWith(
        lnurl: lnurl,
        isLnurlAvailable: true,
        confirmPayment: true,
      ));
    }
  }

  void selectZapContainer(int index) {
    final newIndex = state.selectedIndex == index ? -1 : index;
    if (!isClosed) {
      emit(state.copyWith(selectedIndex: newIndex));
    }
  }

  // =============================================================================
  // NWC OPERATIONS
  // =============================================================================

  Future<Map<String, dynamic>> performNwcAction(
    String request,
    NostrWalletConnectModel nostrWalletConnectModel,
  ) async {
    if (StringUtil.isNotBlank(nostrWalletConnectModel.walletPubkey) &&
        StringUtil.isNotBlank(nostrWalletConnectModel.relay) &&
        StringUtil.isNotBlank(nostrWalletConnectModel.secret)) {
      final r = nostrWalletConnectModel.relay;
      await wnc.closeConnect([r]);
      await wnc.connect(r);

      final signer = Bip340EventSigner(
        nostrWalletConnectModel.secret,
        Keychain.getPublicKey(nostrWalletConnectModel.secret),
      );

      final encrypted = (await signer.encrypt04(
        request,
        nostrWalletConnectModel.walletPubkey,
      ))!;

      final tags = <List<String>>[
        <String>['p', nostrWalletConnectModel.walletPubkey],
      ];

      final event = (await Event.genEvent(
        kind: EventKind.NWC_REQUEST,
        tags: tags,
        content: encrypted,
        signer: signer,
      ))!;

      return getNWCData(event, nostrWalletConnectModel);
    } else {
      return <String, dynamic>{};
    }
  }

  Future<Map<String, dynamic>> getNWCData(
    Event toBeSentEvent,
    NostrWalletConnectModel nostrWalletConnectModel,
  ) async {
    final completer = Completer<Map<String, dynamic>>();

    final filter = Filter(
      kinds: <int>[EventKind.NWC_RESPONSE],
      authors: <String>[nostrWalletConnectModel.walletPubkey],
      p: <String>[Keychain.getPublicKey(nostrWalletConnectModel.secret)],
      e: <String>[toBeSentEvent.id],
    );

    Map<String, dynamic> data = <String, dynamic>{
      'error': {'message': mainContext.t.errorSendingSats.capitalizeFirst()}
    };

    final requestId = wnc.addSubscription(
      <Filter>[filter],
      <String>[nostrWalletConnectModel.relay],
      eventCallBack: (Event event, String relay) async {
        if (event.kind == EventKind.NWC_RESPONSE) {
          final signer = Bip340EventSigner(
            nostrWalletConnectModel.secret,
            Keychain.getPublicKey(nostrWalletConnectModel.secret),
          );

          final encryptedData = (await signer.decrypt04(
            event.content,
            event.pubkey,
          ))!;

          data = jsonDecode(encryptedData);

          if (!completer.isCompleted) {
            completer.complete(data);
          }
        }
      },
    );

    wnc.sendEvent(
      toBeSentEvent,
      <String>[nostrWalletConnectModel.relay],
      sendCallBack: (
        OKEvent ok,
        String relay,
        List<String> unCompletedRelays,
      ) {},
    );

    Timer.periodic(const Duration(milliseconds: 200), (Timer timer) {
      if (timer.tick >= timerTicks * 10 || completer.isCompleted) {
        timer.cancel();

        closeConnections(
          requestId: requestId,
          relay: nostrWalletConnectModel.relay,
        );

        if (!completer.isCompleted) {
          completer.complete(data);
        }
      }
    });

    return completer.future;
  }

  void closeConnections({String? requestId, required String relay}) {
    if (requestId != null) {
      wnc.closeRequests(<String>[requestId]);
    }
    wnc.closeConnect(<String>[relay]);
  }

  // =============================================================================
  // UI STATE MANAGEMENT
  // =============================================================================

  Future<Map<String, dynamic>> redeemCode(String code) async {
    try {
      final lightningAddress = getCurrentWalletLightningAddress();

      final res = await HttpFunctionsRepository.redeemCode(
        code: code,
        pubkey: currentSigner?.getPublicKey() ?? '',
        lightningAddress: lightningAddress ?? '',
      );

      if (res['status']) {
        requestBalance();
      }

      return res;
    } catch (_) {
      return {
        'status': false,
        'resultCode': 'paymentFailed',
      };
    }
  }
  // =============================================================================
  // UI STATE MANAGEMENT
  // =============================================================================

  void toggleWallet() {
    if (!isClosed) {
      emit(state.copyWith(isWalletHidden: !state.isWalletHidden));
    }
  }

  void _resetWalletState() {
    if (!isClosed) {
      emit(state.copyWith(
        wallets: <String, WalletModel>{},
        selectedWalletId: '',
        balance: -1,
        balanceInFiat: -1,
        transactions: <WalletTransactionModel>[],
        transactionsState: UpdatingState.success,
      ));
    }
  }

  void _updateWalletsState(Map<String, WalletModel> wallets,
      [String? selectedWalletId]) {
    if (!isClosed) {
      emit(state.copyWith(
        wallets: wallets,
        selectedWalletId: selectedWalletId ?? state.selectedWalletId,
      ));
    }
  }

  // =============================================================================
  // STORAGE & PERSISTENCE
  // =============================================================================

  void saveWalletsToSecureStorage() {
    try {
      final updateGlobal = _convertGlobalWalletsToMap();
      localDatabaseRepository.setUserWallets(jsonEncode(updateGlobal));
      localDatabaseRepository.setSelectedWalletId(state.selectedWalletId);
    } catch (e) {
      _logError('Failed to save wallets', e);
    }
  }

  Map<String, List<dynamic>> _convertGlobalWalletsToMap() {
    final updateGlobal = <String, List<dynamic>>{};

    for (final item in globalWallets.entries) {
      updateGlobal[item.key] = item.value
          .map((wallet) {
            if (wallet is AlbyConnectModel) {
              return wallet.toMap();
            } else if (wallet is NostrWalletConnectModel) {
              return wallet.toMap();
            }
            return null;
          })
          .where((item) => item != null)
          .toList();
    }

    return updateGlobal;
  }

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================

  void _emitRefresh() {
    emit(state.copyWith(refresh: !state.refresh));
  }

  void _logError(String message, dynamic error) {
    lg.i('$message: $error');
  }

  // =============================================================================
  // CLEANUP
  // =============================================================================

  @override
  Future<void> close() {
    _sub.cancel();
    _userStatusStream.cancel();
    _appLifeCycle?.cancel();
    return super.close();
  }
}

// =============================================================================
// HELPER CLASSES
// =============================================================================

class _LoadedData {
  _LoadedData({
    required this.wallets,
    required this.defaultWallet,
    required this.selectedWalletId,
    required this.useDefaultWallet,
  });

  final String wallets;
  final String defaultWallet;
  final String selectedWalletId;
  final bool useDefaultWallet;
}
