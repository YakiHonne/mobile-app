import 'dart:async';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:nostr_core_enhanced/cashu/api/cashu_api.dart';
import 'package:nostr_core_enhanced/cashu/business/wallet/cashu_manager.dart';
import 'package:nostr_core_enhanced/cashu/models/cashu_encoded_token.dart';
import 'package:nostr_core_enhanced/cashu/models/cashu_spending_data.dart';
import 'package:nostr_core_enhanced/cashu/models/mint_info.dart';
import 'package:nostr_core_enhanced/cashu/models/mint_model.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:nostr_core_enhanced/nostr/zaps/zap_action.dart';
import 'package:nostr_core_enhanced/utils/enums.dart';
import 'package:nostr_core_enhanced/utils/spider_util.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';

import '../../common/common_regex.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../models/cashu/nutzap.dart';
import '../../repositories/http_functions_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'cashu_wallet_manager_state.dart';

class CashuWalletManagerCubit extends Cubit<CashuWalletManagerState> {
  CashuWalletManagerCubit()
      : super(const CashuWalletManagerState(
          activeMint: '',
          balance: 0,
          activeMintBalance: 0,
          mints: {},
          recommendedMints: [],
          walletMints: [],
        )) {
    loadRecommendedMints();
  }

  final cm = CashuManager.shared;
  final cashuApi = CashuAPI();

  Future<void> init() async {
    _emit(state.copyWith(isInitializing: true));
    clear();

    if (canSign()) {
      await cm.init(nc, currentSigner!.getPublicKey());

      final mints = cm.mints;

      final walletMints = cm.wallet?.mints ?? [];
      final savedActiveMint =
          localDatabaseRepository.getUserActiveMint(cm.pubkey);
      String activeMint = '';

      if (savedActiveMint.isNotEmpty && walletMints.contains(savedActiveMint)) {
        activeMint = savedActiveMint;
      } else {
        activeMint = walletMints.isNotEmpty ? walletMints.first : '';
      }

      _emit(
        state.copyWith(
          mints: cm.mints,
          balance: cashuApi.totalBalance(),
          activeMintBalance: mints[activeMint]?.balance ?? 0,
          activeMint: activeMint,
          walletMints: cm.wallet?.mints ?? [],
          isInitializing: false,
        ),
      );
    } else {
      _emit(state.copyWith(isInitializing: false));
    }
  }

  Future<List<NutZap>> getReceivedNutzaps() async {
    try {
      final events = await NostrFunctionsRepository.getEventsAsync(
        kinds: [EventKind.CASHU_NUTZAP],
        pTags: [cm.pubkey],
        // pubkeys: [currentSigner!.getPublicKey()],
      );

      //  await NostrFunctionsRepository.deleteEvents(
      //     eventIds: events.map((e) => e.id).toList());

      final history = await cashuApi.getHistory();
      final redeemedEventIds = <String>{};

      for (final entry in history) {
        for (final tag in entry.tags) {
          if (tag[0] == 'e' && tag.length >= 4 && tag[3] == 'redeemed') {
            redeemedEventIds.add(tag[1]);
          }
        }
      }

      return events.map((e) {
        final nutzap = NutZap.fromEvent(e);
        return nutzap.copyWith(isClaimed: redeemedEventIds.contains(e.id));
      }).toList();
    } catch (e) {
      logger.e('Failed to fetch received NutZaps: $e');
      return [];
    }
  }

  Future<bool> claimNutzap(NutZap nutzap) async {
    final cancel = BotToastUtils.showLoading();
    try {
      final response = await cashuApi.redeemNutzap(
        nutzapEvent: nutzap.event,
        onStatusUpdate: (status) {
          botUtilsLoadingProgressCubit.emitStatus(actionsStatus(status));
        },
      );

      if (response.isSuccess) {
        final walletMints = cm.wallet!.mints;

        _emit(
          state.copyWith(
            mints: cm.mints,
            balance: cashuApi.totalBalance(),
            walletMints: walletMints,
            activeMintBalance: cm.mints[walletMints.first]?.balance ?? 0,
            activeMint: walletMints.isNotEmpty ? walletMints.first : '',
          ),
        );

        if (walletMints.isNotEmpty) {
          localDatabaseRepository.setUserActiveMint(
            cm.pubkey,
            walletMints.first,
          );
        }
        cancel();
        return true;
      } else {
        cancel();
        BotToastUtils.showError(response.errorMsg);
        return false;
      }
    } catch (e) {
      cancel();
      EasyLoading.showError('Error claiming NutZap: $e');
      return false;
    }
  }

  Future<void> loadRecommendedMints() async {
    final recommendedMints =
        await HttpFunctionsRepository.getRecommendedMints();

    _emit(state.copyWith(
      recommendedMints: recommendedMints,
    ));
  }

  void setActiveMint(String mintUrl) {
    _emit(
      state.copyWith(
        activeMint: mintUrl,
        activeMintBalance: cm.mints[mintUrl]?.balance ?? 0,
      ),
    );

    localDatabaseRepository.setUserActiveMint(cm.pubkey, mintUrl);
  }

  void _emit(CashuWalletManagerState state) {
    if (!isClosed) {
      emit(state);
    }
  }

  Future<bool> createWallet(List<String> mints) async {
    if (mints.isEmpty) {
      BotToastUtils.showError(t.errorCreatingWallet);
      return false;
    }

    final cancel = BotToastUtils.showLoading();

    final isSuccess = await cashuApi.createWallet(mints);

    cancel();

    final walletMints = cm.wallet!.mints;

    if (isSuccess) {
      _emit(
        state.copyWith(
          mints: cm.mints,
          balance: cashuApi.totalBalance(),
          walletMints: walletMints,
          activeMintBalance: cm.mints[walletMints.first]?.balance ?? 0,
          activeMint: walletMints.isNotEmpty ? walletMints.first : '',
        ),
      );

      if (walletMints.isNotEmpty) {
        localDatabaseRepository.setUserActiveMint(
          cm.pubkey,
          walletMints.first,
        );
      }

      return true;
    } else {
      BotToastUtils.showError(t.errorCreatingWallet);
      return false;
    }
  }

  Future<MintInfo?> getMintInfo(String mintUrl) async {
    final cancel = BotToastUtils.showLoading();

    try {
      if (!urlRegExp.hasMatch(mintUrl)) {
        cancel();
        BotToastUtils.showError(t.invalidUrl);
        return null;
      }

      final mintInfo = await cashuApi.getRawMintInfo(mintUrl);
      lg.i(mintInfo);
      cancel();

      return mintInfo;
    } catch (e) {
      lg.i(e);
      cancel();
      BotToastUtils.showError(t.errorUpdatingMint);
      return null;
    }
  }

  Future<bool> updateMintList(
    String mintUrl, {
    bool checkBeforeUpdate = false,
  }) async {
    final cancel = BotToastUtils.showLoading();

    if (checkBeforeUpdate) {
      if (!urlRegExp.hasMatch(mintUrl)) {
        cancel();
        BotToastUtils.showError(t.invalidUrl);
        return false;
      }

      final isMint = await cashuApi.isMintInfoAvailable(mintUrl);

      if (!isMint) {
        cancel();
        BotToastUtils.showError(t.mintUnavailable);
        return false;
      }
    }

    final isSuccess = await cashuApi.updateWalletMints(mintUrl);

    cancel();

    if (isSuccess) {
      final walletMints = cm.wallet!.mints;

      final activeMint = walletMints.contains(state.activeMint)
          ? state.activeMint
          : walletMints.first;

      _emit(
        state.copyWith(
          mints: cm.mints,
          balance: cashuApi.totalBalance(),
          walletMints: walletMints,
          activeMintBalance: cm.mints[activeMint]?.balance ?? 0,
          activeMint: activeMint,
        ),
      );

      localDatabaseRepository.setUserActiveMint(cm.pubkey, activeMint);

      return true;
    } else {
      BotToastUtils.showError(t.errorUpdatingMint);
      return false;
    }
  }

  void clear() {
    _emit(
      state.copyWith(
        mints: {},
        balance: 0,
        activeMintBalance: 0,
        activeMint: '',
        walletMints: [],
      ),
    );
  }

  Future<void> removeMint(String mintUrl) async {
    final cancel = BotToastUtils.showLoading();

    await cashuApi.deleteMint(mintUrl);
    String activeMint = state.activeMint;

    if (state.activeMint == mintUrl) {
      activeMint = cm.mints.isNotEmpty ? cm.mints.keys.first : '';
    }

    cancel();

    _emit(
      state.copyWith(
        mints: cm.mints,
        balance: cashuApi.totalBalance(),
        activeMintBalance: cm.mints[activeMint]?.balance ?? 0,
        activeMint: activeMint,
      ),
    );

    localDatabaseRepository.setUserActiveMint(cm.pubkey, activeMint);
  }

  Future<int> restoreProofs({
    required String mintUrl,
    required String mnemonic,
  }) async {
    try {
      final cancel = BotToastUtils.showLoading();

      final amount = await cashuApi.restoreProofs(mintUrl, mnemonic);

      cancel();

      if (amount > 0) {
        _emit(
          state.copyWith(
            mints: cm.mints,
            balance: cashuApi.totalBalance(),
            activeMintBalance: cm.mints[state.activeMint]?.balance ?? 0,
            activeMint: state.activeMint,
          ),
        );
        BotToastUtils.showSuccess(t.proofsRestored);
        return amount;
      } else {
        BotToastUtils.showWarning(t.noProofsFound);
        return 0;
      }
    } catch (_) {
      BotToastUtils.showError(t.errorRestoringProofs);
      return -1;
    }
  }

  Future<bool> swapTokens({
    required String fromMintUrl,
    required String toMintUrl,
    required int amount,
  }) async {
    final cancel = BotToastUtils.showLoading();

    final response = await cashuApi.swapMintFunds(
      fromMintURL: fromMintUrl,
      toMintURL: toMintUrl,
      amount: amount,
      onStatusUpdate: (status) {
        botUtilsLoadingProgressCubit.emitStatus(actionsStatus(status));
      },
    );

    cancel();

    if (!response.isSuccess) {
      lg.i(response.errorMsg);
      BotToastUtils.showError(response.errorMsg);
      return false;
    }

    _emit(
      state.copyWith(
        mints: cm.mints,
        balance: cashuApi.totalBalance(),
        activeMintBalance: cm.mints[state.activeMint]?.balance ?? 0,
        activeMint: state.activeMint,
      ),
    );

    return true;
  }

  Future<List<CashuSpendingData>> getHistory() async {
    return cashuApi.getHistory();
  }

  Map<String, dynamic>? decodeToken(String token) {
    try {
      // Decode the Cashu token using CashuAPI
      final tokenData = cashuApi.decodeCashuToken(token);

      if (tokenData == null || tokenData.entries.isEmpty) {
        return null;
      }

      // Extract mint URL from the first token entry
      final mintUrl = tokenData.entries.first.mint;

      // Calculate total amount and count proofs
      double totalAmount = 0;
      int proofsCount = 0;

      for (final entry in tokenData.entries) {
        for (final proof in entry.proofs) {
          totalAmount += proof.amountNum;
          proofsCount++;
        }
      }

      return {
        'mint': mintUrl,
        'amount': totalAmount.toInt(),
        'memo': tokenData.memo,
        'proofs': proofsCount,
        'tokenData': tokenData,
      };
    } catch (e) {
      lg.e('Error decoding token: $e');
      return null;
    }
  }

  Future<bool> redeemToken(String token, {String? targetMintUrl}) async {
    try {
      final cancel = BotToastUtils.showLoading();

      // Decode token first to validate
      final decoded = decodeToken(token);
      if (decoded == null) {
        cancel();
        BotToastUtils.showError(t.invalidToken);
        return false;
      }

      // Redeem the token using cashuApi
      final mintUrl = targetMintUrl ?? decoded['mint'];
      final response = await cashuApi.depositWithToken(
        targetMintURL: mintUrl,
        ecashString: token,
        onStatusUpdate: (status) {
          botUtilsLoadingProgressCubit.emitStatus(actionsStatus(status));
        },
      );

      cancel();

      if (response.isSuccess) {
        // Update state with new balance
        _emit(
          state.copyWith(
            mints: cm.mints,
            balance: cashuApi.totalBalance(),
            activeMintBalance: cm.mints[state.activeMint]?.balance ?? 0,
          ),
        );
        BotToastUtils.showSuccess(t.tokenRedeemed);
        return true;
      } else {
        BotToastUtils.showError(response.errorMsg);
        return false;
      }
    } catch (e) {
      lg.e('Error redeeming token: $e');
      BotToastUtils.showError(e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>?> createDepositQuote(int amount) async {
    final cancel = BotToastUtils.showLoading();

    try {
      final mintUrl = state.activeMint;
      if (mintUrl.isEmpty) {
        cancel();
        BotToastUtils.showError(t.noMintsAvailable);
        return null;
      }

      final response = await cashuApi.createDepositInvoice(
        mintURL: mintUrl,
        amount: amount,
        onStatusUpdate: (status) {
          botUtilsLoadingProgressCubit.emitStatus(actionsStatus(status));
        },
      );

      cancel();

      if (response.isSuccess) {
        return {
          'invoice': response.data.request,
          'quote': response.data.paymentKey,
        };
      } else {
        BotToastUtils.showError(t.errorGeneratingInvoice);
        return null;
      }
    } catch (e) {
      cancel();
      lg.e('Error creating deposit quote: $e');
      BotToastUtils.showError(t.errorGeneratingInvoice);
      return null;
    }
  }

  // WebSocket listener for quote status
  Future<bool> checkDepositQuoteStatus(
    String quoteId,
    int amount, {
    VoidCallback? onPaid,
  }) async {
    final cancel = BotToastUtils.showLoading();
    try {
      final mintUrl = state.activeMint;

      if (mintUrl.isEmpty) {
        cancel();
        BotToastUtils.showError(t.noMintsAvailable);
        return false;
      }

      final response = await cashuApi.completeDeposit(
        mintURL: mintUrl,
        quoteID: quoteId,
        amount: amount,
        onStatusUpdate: (status) {
          botUtilsLoadingProgressCubit.emitStatus(actionsStatus(status));
        },
      );

      if (response.isSuccess) {
        _emit(
          state.copyWith(
            mints: cm.mints,
            balance: cashuApi.totalBalance(),
            activeMintBalance: cm.mints[mintUrl]?.balance ?? 0,
            activeMint: mintUrl,
          ),
        );

        localDatabaseRepository.setUserActiveMint(cm.pubkey, mintUrl);

        onPaid?.call();
        cancel();
        return true;
      }

      cancel();
      return false;
    } catch (e) {
      lg.e('Error checking quote status: $e');
      cancel();
      return false;
    }
  }

  Future<StreamSubscription?> listenToQuoteStatus(
    String quoteId,
    int amount, {
    VoidCallback? onPaid,
  }) async {
    try {
      final mintUrl = state.activeMint;
      if (mintUrl.isEmpty) {
        BotToastUtils.showError(t.noMintsAvailable);
        return null;
      }

      final stream = await cashuApi.subscribeToMintQuote(
        mintURL: mintUrl,
        quoteID: quoteId,
      );

      return stream.listen((status) async {
        lg.i(status);
        if (status.$3) {
          await checkDepositQuoteStatus(quoteId, amount, onPaid: onPaid);
        }
      });
    } catch (e) {
      lg.e('Error listening to quote status: $e');
      return null;
    }
  }

  // I will do this in two steps. First update the method signature, then the call site.
  // Actually, I can't do that easily without breaking code.
  // Let me look at `CashuDepositView` again to see where `checkQuoteStatus` is called.

  Future<bool> payMintQuoteWithNwc(
    String invoice,
    String quoteId,
    String walletId,
  ) async {
    final cancel = BotToastUtils.showLoading();

    try {
      final walletsManagerState = walletManagerCubit.state;
      final wallet = walletsManagerState.wallets[walletId];

      if (wallet == null) {
        cancel();
        BotToastUtils.showError('Invalid wallet');
        return false;
      }

      bool isSuccessful = false;

      botUtilsLoadingProgressCubit.emitStatus(t.payingInvoice);
      await walletManagerCubit.sendUsingInvoice(
        invoice: MapEntry(invoice, null),
        onSuccess: () {
          isSuccessful = true;
        },
      );

      if (isSuccessful) {
        // Payment successful
        BotToastUtils.showSuccess(t.paymentSucceeded);

        // Get amount from invoice to complete deposit
        final amount = cashuApi.amountOfLightningInvoice(invoice);

        if (amount != null) {
          await cashuApi.completeDeposit(
            mintURL: state.activeMint,
            quoteID: quoteId,
            amount: amount,
            onStatusUpdate: (status) {
              botUtilsLoadingProgressCubit.emitStatus(actionsStatus(status));
            },
          );

          // Refresh state
          _emit(
            state.copyWith(
              mints: cm.mints,
              balance: cashuApi.totalBalance(),
              activeMintBalance: cm.mints[state.activeMint]?.balance ?? 0,
              activeMint: state.activeMint,
            ),
          );

          localDatabaseRepository.setUserActiveMint(
            cm.pubkey,
            state.activeMint,
          );
        }

        cancel();

        return true;
      } else {
        BotToastUtils.showError(t.paymentFailed);
        cancel();
        return false;
      }
    } catch (e) {
      cancel();
      lg.e('Error paying with NWC: $e');
      BotToastUtils.showError(e.toString());
      return false;
    }
  }

  Future<bool?> payInvoice({
    required String invoice,
    int? amount,
    String? mintUrl,
  }) async {
    final mint = mintUrl ?? state.activeMint;
    if (mint.isEmpty) {
      BotToastUtils.showError(t.selectMint);
      return false;
    }

    final cancel = BotToastUtils.showLoading();

    try {
      final response = await cashuApi.payInvoice(
        mintURL: mint,
        invoice: invoice,
        onStatusUpdate: (status) {
          botUtilsLoadingProgressCubit.emitStatus(actionsStatus(status));
        },
      );

      cancel();

      if (!response.isSuccess) {
        BotToastUtils.showError(response.errorMsg);
        return false;
      }

      _emit(
        state.copyWith(
          mints: cm.mints,
          balance: cashuApi.totalBalance(),
          activeMintBalance: cm.mints[state.activeMint]?.balance ?? 0,
          activeMint: state.activeMint,
        ),
      );

      return true;
    } catch (e) {
      cancel();
      BotToastUtils.showError(e.toString());
      return false;
    }
  }

  Future<String?> createToken({
    required String mintUrl,
    required int amount,
    String? memo,
  }) async {
    final cancel = BotToastUtils.showLoading();

    try {
      final response = await cashuApi.createCashuToken(
        mintURL: mintUrl,
        amount: amount,
        memo: memo ?? '',
        onStatusUpdate: (status) {
          botUtilsLoadingProgressCubit.emitStatus(actionsStatus(status));
        },
      );

      cancel();

      if (!response.isSuccess) {
        BotToastUtils.showError(response.errorMsg);
        return null;
      }

      _emit(
        state.copyWith(
          mints: cm.mints,
          balance: cashuApi.totalBalance(),
          activeMintBalance: cm.mints[mintUrl]?.balance ?? 0,
          activeMint: mintUrl,
        ),
      );

      localDatabaseRepository.setUserActiveMint(cm.pubkey, mintUrl);

      final tokenString = response.data;

      // Save to NostrDataRepository
      final cashuEncodedToken = CashuEncodedToken(
        encodedToken: tokenString,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        amount: amount,
        mint: mintUrl,
      );

      nostrRepository.addCashuToken(cashuEncodedToken);

      return tokenString;
    } catch (e, stacktrace) {
      cancel();
      lg.e('Error creating token: $e');
      lg.e('Stacktrace: $stacktrace');
      BotToastUtils.showError(e.toString());
      return null;
    }
  }

  List<CashuEncodedToken> getCreatedTokens() {
    return nostrRepository.cashuEncodedTokens;
  }

  Future<void> deleteCreatedToken(CashuEncodedToken token) async {
    nostrRepository.removeCashuToken(token);
  }

  Future<void> markTokenAsSpent(CashuEncodedToken token) async {
    nostrRepository.markCashuTokenAsSpent(token);
  }

  Future<bool?> checkTokenStatus(String token) async {
    final cancel = BotToastUtils.showLoading();
    try {
      final res = await cashuApi.isEcashTokenSpendableFromToken(token);

      cancel();

      return res;
    } catch (e) {
      lg.e('Error checking token status: $e');
      cancel();
      return null;
    }
  }

  Future<bool> sendNutzap({
    required String pubkey,
    required int amount,
    required String mintUrl,
    String memo = '',
    String unit = 'sat',
  }) async {
    final cancel = BotToastUtils.showLoading();

    try {
      final response = await cashuApi.sendNutzap(
        pubkey: pubkey,
        amount: amount,
        mintURL: mintUrl,
        unit: unit,
        memo: memo,
        onStatusUpdate: (status) {
          botUtilsLoadingProgressCubit.emitStatus(actionsStatus(status));
        },
      );

      cancel();

      if (response.isSuccess) {
        // Update balance
        _emit(
          state.copyWith(
            mints: cm.mints,
            balance: cashuApi.totalBalance(),
            activeMintBalance: cm.mints[state.activeMint]?.balance ?? 0,
          ),
        );
        BotToastUtils.showSuccess(t.paymentSucceeded);
        return true;
      } else {
        BotToastUtils.showError(response.errorMsg);
        return false;
      }
    } catch (e) {
      cancel();
      lg.e('Error sending NutZap: $e');
      BotToastUtils.showError(e.toString());
      return false;
    }
  }

  Future<bool> payLightningAddress({
    required String lightningAddress,
    required int amount,
    String? mintUrl,
    String? message,
  }) async {
    final mint = mintUrl ?? state.activeMint;
    if (mint.isEmpty) {
      BotToastUtils.showError(t.selectMint);
      return false;
    }

    final cancel = BotToastUtils.showLoading();

    try {
      botUtilsLoadingProgressCubit.emitStatus(t.requestingMintQuote);

      final relays = currentUserRelayList.reads;

      final result = await ZapAction.genInvoiceCode(
        amount,
        Metadata.empty().copyWith(
          lud16: lightningAddress,
          lud06: lightningAddress,
        ),
        currentSigner!,
        relays,
        comment: message?.isEmpty ?? true ? null : message,
        removeNostrEvent: true,
      );

      if (result == null || result.key.isEmpty) {
        cancel();
        BotToastUtils.showError(t.errorGeneratingInvoice);
        return false;
      }

      final invoice = result.key;

      final response = await cashuApi.payInvoice(
        mintURL: mint,
        invoice: invoice,
        onStatusUpdate: (status) {
          botUtilsLoadingProgressCubit.emitStatus(actionsStatus(status));
        },
      );

      cancel();

      if (!response.isSuccess) {
        BotToastUtils.showError(response.errorMsg);
        return false;
      }

      _emit(
        state.copyWith(
          mints: cm.mints,
          balance: cashuApi.totalBalance(),
          activeMintBalance: cm.mints[state.activeMint]?.balance ?? 0,
          activeMint: state.activeMint,
        ),
      );

      return true;
    } catch (e) {
      cancel();
      lg.e('Error paying lightning address: $e');
      BotToastUtils.showError(e.toString());
      return false;
    }
  }

  Future<void> payNutZapSplit({
    required List<ZapSplit> zapSplits,
    required int totalAmount,
    required Function(String) onSuccess,
    required Function(String) onFailure,
    required Function() onFinished,
  }) async {
    final activeMintUrl = state.activeMint;
    if (activeMintUrl.isEmpty) {
      onFailure.call('No active mint');
      onFinished();
      return;
    }

    try {
      // Calculate total percentage
      final totalPercentage =
          zapSplits.fold<int>(0, (sum, zap) => sum + zap.percentage);
      if (totalPercentage == 0) {
        onFailure.call('Invalid zap split percentages');
        onFinished();
        return;
      }

      bool allSuccess = true;
      final List<String> failedRecipients = [];

      for (final zap in zapSplits) {
        // Calculate amount for this recipient
        final zapAmount =
            ((zap.percentage / totalPercentage) * totalAmount).round();

        if (zapAmount <= 0) {
          continue;
        }

        // Get metadata for this pubkey to extract lightning address
        final metadata = await nc.db.loadMetadata(zap.pubkey);
        final lud16 = metadata?.lud16;

        if (lud16 == null || lud16.isEmpty) {
          lg.w('No lightning address for pubkey: ${zap.pubkey}');
          failedRecipients.add(zap.pubkey.substring(0, 8));
          allSuccess = false;
          continue;
        }

        // Pay this recipient
        final success = await payLightningAddress(
          lightningAddress: lud16,
          amount: zapAmount,
          mintUrl: activeMintUrl,
        );

        if (!success) {
          failedRecipients.add(zap.pubkey.substring(0, 8));
          allSuccess = false;
        }
      }

      if (allSuccess) {
        onSuccess.call('All zap splits sent successfully');
      } else {
        onFailure.call('Failed to send to: ${failedRecipients.join(", ")}');
      }
    } catch (e) {
      lg.e('Error in payNutZapSplit: $e');
      onFailure.call(e.toString());
    } finally {
      onFinished();
    }
  }

  Future<void> syncMintData(String mintUrl) async {
    final cancel = BotToastUtils.showLoading();

    await cashuApi.resyncMint(
      mintUrl,
      onStatusUpdate: (status) {
        botUtilsLoadingProgressCubit.emitStatus(actionsStatus(status));
      },
    );

    _emit(
      state.copyWith(
        mints: cm.mints,
        balance: cashuApi.totalBalance(),
        activeMintBalance: cm.mints[state.activeMint]?.balance ?? 0,
        activeMint: state.activeMint,
      ),
    );

    cancel();
  }

  String actionsStatus(CashuActionsStatus status) {
    switch (status) {
      case CashuActionsStatus.broadcastingNew:
        return t.broadcastingNew;
      case CashuActionsStatus.broadcastingSpent:
        return t.broadcastingSpent;
      case CashuActionsStatus.finalizing:
        return t.finalizing;
      case CashuActionsStatus.selectingTokens:
        return t.selectingTokens;
      case CashuActionsStatus.requestingMeltQuote:
        return t.requestingMeltQuote;
      case CashuActionsStatus.melting:
        return t.melting;
      case CashuActionsStatus.requestingMintQuote:
        return t.requestingMintQuote;
      case CashuActionsStatus.minting:
        return t.minting;
      case CashuActionsStatus.mintInfo:
        return t.gettingMintInfo;
      case CashuActionsStatus.generatingInvoice:
        return t.generatingInvoice;
      case CashuActionsStatus.checkingProofs:
        return t.checkingTokensValidity;
    }
  }
}
