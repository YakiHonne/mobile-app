import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../logic/dms_cubit/dms_cubit.dart';
import '../../../logic/metadata_cubit/metadata_cubit.dart';
import '../../../repositories/http_functions_repository.dart';
import '../../../utils/utils.dart';
import '../../widgets/common_thumbnail.dart';

enum GiftDisplayState { sent, compactReceived, detailed }

class DMGiftWidget extends HookWidget {
  const DMGiftWidget({
    super.key,
    required this.token,
    required this.isCurrentUser,
  });

  final String token;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final giftData = useMemoized(() => decodeGiftToken(token), [token]);
    final preimage = giftData['pi'] as String?;
    final isOpened = useState(
      preimage != null &&
          localDatabaseRepository.getOpenedGifts().contains(preimage),
    );
    final isClaimed = useState(false);
    final isRefunded = useState(false);
    final isCheckingStatus = useState(true);

    useEffect(() {
      if (preimage != null) {
        isCheckingStatus.value = true;
        HttpFunctionsRepository.checkRedPacket(preimage).then((res) {
          if (res != null) {
            if (res['isRedeemed'] == true) {
              isClaimed.value = true;
            }
            if (res['isRefunded'] == true) {
              isRefunded.value = true;
            }
          }
          isCheckingStatus.value = false;
        }).catchError((_) {
          isCheckingStatus.value = false;
        });
      } else {
        isCheckingStatus.value = false;
      }
      return null;
    }, [preimage]);

    if (giftData.isEmpty) {
      return const SizedBox.shrink();
    }

    final createdAt = giftData['c_at'] as int;
    final expiresAt = createdAt + (3 * 24 * 60 * 60); // 3 days
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final isExpired = now >= expiresAt;

    if (isCurrentUser) {
      return _buildCompactSent(
          context, giftData, isExpired, isClaimed, isRefunded);
    }

    if (isOpened.value) {
      return _buildDetailedReceived(context, giftData, expiresAt, isExpired,
          isClaimed, isRefunded, isCheckingStatus);
    }

    return GestureDetector(
      onTap: () {
        isOpened.value = true;
        if (preimage != null) {
          localDatabaseRepository.addOpenedGift(preimage);
        }
      },
      child: _buildCompactReceived(
          context, giftData, expiresAt, isExpired, isClaimed, isRefunded),
    );
  }

  // --- State 1: Compact Sent ---
  Widget _buildCompactSent(
      BuildContext context,
      Map<String, dynamic> data,
      bool isExpired,
      ValueNotifier<bool> isClaimed,
      ValueNotifier<bool> isRefunded) {
    final message = data['m']?.toString();

    final displayMessage = (message != null && message.trim().isNotEmpty)
        ? message
        : 'All the best';

    return Container(
      width: 70.w,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
      ),
      child: Row(
        spacing: kDefaultPadding / 4,
        children: [
          _buildGiftPreview(data['img'] ?? ''),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayMessage,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isClaimed.value || isExpired || isRefunded.value) ...[
                  const SizedBox(height: 2),
                  Builder(
                    builder: (context) {
                      String statusText = '';
                      Color statusColor = Colors.grey;

                      if (isClaimed.value) {
                        statusText = context.t.claimed.capitalizeFirst();
                        statusColor = Colors.green;
                      } else if (isRefunded.value) {
                        statusText = context.t.refunded.capitalizeFirst();
                        statusColor = Colors.orange;
                      } else if (isExpired) {
                        statusText = context.t.expired.capitalizeFirst();
                        statusColor = Colors.red;
                      }

                      if (statusText.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Text(
                        statusText,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- State 2: Compact Received ---
  Widget _buildCompactReceived(
      BuildContext context,
      Map<String, dynamic> data,
      int expiresAt,
      bool isExpired,
      ValueNotifier<bool> isClaimed,
      ValueNotifier<bool> isRefunded) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 70.w,
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            border:
                Border.all(color: Theme.of(context).dividerColor, width: 0.5),
          ),
          child: Row(
            spacing: kDefaultPadding / 4,
            children: [
              _buildGiftPreview(data['img'] ?? ''),
              Expanded(
                child: Text(
                  data['m'] ?? context.t.youReceivedGift.capitalizeFirst(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!isClaimed.value && !isRefunded.value) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: _CountdownTimer(
              expiresAt: expiresAt,
              isCompact: true,
              isExpired: isExpired,
            ),
          ),
        ],
      ],
    );
  }

  // --- State 3: Detailed Received ---
  Widget _buildDetailedReceived(
      BuildContext context,
      Map<String, dynamic> data,
      int expiresAt,
      bool isExpired,
      ValueNotifier<bool> isClaimed,
      ValueNotifier<bool> isRefunded,
      ValueNotifier<bool> isCheckingStatus) {
    final image = data['img'] ?? '';

    return Container(
      width: 80.w,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  ClipPath(
                    clipper: _GiftCardClipper(),
                    child: image.isNotEmpty
                        ? CommonThumbnail(
                            image: image,
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                          )
                        : const SizedBox(
                            width: double.infinity,
                            height: 250,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              Text(
                '${data['a']} sats',
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (!isClaimed.value && !isRefunded.value)
                _CountdownTimer(
                  expiresAt: expiresAt,
                  isCompact: false,
                  isExpired: isExpired,
                ),
              const SizedBox(height: kDefaultPadding),
            ],
          ),
          Positioned(
            top: 200,
            right: 26.w,
            child: _buildClaimButton(context, data, isExpired, isClaimed,
                isRefunded, isCheckingStatus),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftPreview(String url) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (url.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CommonThumbnail(
              image: url,
              width: 40,
              height: 50,
              fit: BoxFit.cover,
              radius: 2,
            ),
          ),
      ],
    );
  }

  Widget _buildClaimButton(
      BuildContext context,
      Map<String, dynamic> data,
      bool isExpired,
      ValueNotifier<bool> isClaimed,
      ValueNotifier<bool> isRefunded,
      ValueNotifier<bool> isCheckingStatus) {
    String status = context.t.claim.capitalizeFirst();
    final bool shouldDisable = isExpired ||
        isClaimed.value ||
        isRefunded.value ||
        isCheckingStatus.value;

    if (isRefunded.value) {
      status = context.t.refunded.capitalizeFirst();
    } else if (isClaimed.value) {
      status = context.t.claimed.capitalizeFirst();
    } else if (isExpired) {
      status = context.t.expired.capitalizeFirst();
    }

    final isLoading = isCheckingStatus.value;

    return GestureDetector(
      onTap:
          shouldDisable ? null : () => _handleClaim(context, data, isClaimed),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: shouldDisable && !isLoading
              ? Theme.of(context).cardColor
              : Colors.amber,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  status,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).primaryColorDark,
                        fontWeight: FontWeight.bold,
                      ),
                ),
        ),
      ),
    );
  }

  void _handleClaim(BuildContext context, Map<String, dynamic> data,
      ValueNotifier<bool> isClaimed) {
    final dmsCubit = context.read<DmsCubit>();
    final mCubit = context.read<MetadataCubit>();
    final userMetadata =
        mCubit.state.metadataCache[currentSigner!.getPublicKey()];
    final existingAddress = userMetadata?.lud16 ?? userMetadata?.lud06 ?? '';

    if (existingAddress.isNotEmpty) {
      _executeClaim(context, dmsCubit, data['pi'], existingAddress, isClaimed);
    } else {
      _showAddressInputDialog(context, dmsCubit, data['pi'], isClaimed);
    }
  }

  Future<void> _executeClaim(
    BuildContext context,
    DmsCubit cubit,
    String preimage,
    String address,
    ValueNotifier<bool> isClaimed,
  ) async {
    await cubit.claimGift(
      preimage: preimage,
      receiverAddress: address,
      onSuccess: () {
        isClaimed.value = true;
      },
    );
  }

  void _showAddressInputDialog(BuildContext context, DmsCubit cubit,
      String preimage, ValueNotifier<bool> isClaimed) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t.enterLightningAddress.capitalizeFirst()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: context.t.lightningAddress.capitalizeFirst(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.t.cancel.capitalizeFirst()),
          ),
          TextButton(
            onPressed: () {
              final addr = controller.text.trim();
              if (addr.isNotEmpty) {
                Navigator.pop(context);
                _executeClaim(context, cubit, preimage, addr, isClaimed);
              }
            },
            child: Text(context.t.claim.capitalizeFirst()),
          ),
        ],
      ),
    );
  }
}

class _CountdownTimer extends HookWidget {
  const _CountdownTimer({
    required this.expiresAt,
    required this.isCompact,
    required this.isExpired,
  });

  final int expiresAt;
  final bool isCompact;
  final bool isExpired;

  @override
  Widget build(BuildContext context) {
    final remainingTime = useState(_calculateRemaining());

    useEffect(() {
      if (isExpired) {
        return null;
      }
      final timer = Timer.periodic(const Duration(seconds: 1), (t) {
        remainingTime.value = _calculateRemaining();
        if (remainingTime.value == 'Expired') {
          t.cancel();
        }
      });
      return timer.cancel;
    }, [expiresAt, isExpired]);

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t.claimBefore.capitalizeFirst(),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Text(
            isExpired
                ? context.t.expired.capitalizeFirst()
                : remainingTime.value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return Text(
      isExpired ? context.t.expired.capitalizeFirst() : remainingTime.value,
      style: Theme.of(context).textTheme.labelLarge,
    );
  }

  String _calculateRemaining() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = expiresAt - now;
    if (diff <= 0) {
      return 'Expired';
    }

    final days = diff ~/ 86400;
    final hours = (diff % 86400) ~/ 3600;
    final minutes = (diff % 3600) ~/ 60;
    final seconds = diff % 60;

    return '${days}d ${hours}h ${minutes}m ${seconds}s';
  }
}

class _GiftCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final dipHeight = size.height * 0.8;
    const dip = 40.0;

    path.lineTo(0, dipHeight);
    path.cubicTo(
      size.width * 0.2,
      dipHeight,
      size.width * 0.3,
      dipHeight + dip,
      size.width * 0.5,
      dipHeight + dip,
    );
    path.cubicTo(
      size.width * 0.7,
      dipHeight + dip,
      size.width * 0.8,
      dipHeight,
      size.width,
      dipHeight,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
