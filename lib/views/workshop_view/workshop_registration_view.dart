import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../repositories/http_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import '../widgets/common_thumbnail.dart';
import '../widgets/dotted_container.dart';
import '../widgets/modal_sheet_container.dart';

/// Bottom sheet opened from `yakihonne.com/workshop/registration?wid=<id>`.
/// ponytail: raw map instead of a model — one screen, one consumer.
class WorkshopRegistrationView extends HookWidget {
  const WorkshopRegistrationView({super.key, required this.workshopId});

  final String workshopId;

  @override
  Widget build(BuildContext context) {
    final workshop = useState<Map<String, dynamic>?>(null);
    final isLoading = useState(true);
    final isRegistering = useState(false);
    final isRegistered = useState(false);
    final isEligible = useState(false);

    final load = useCallback(
      () async {
        isLoading.value = true;
        final res = await HttpFunctionsRepository.getWorkshop(workshopId);

        if (!context.mounted) {
          return;
        }

        workshop.value = res?['workshop'] as Map<String, dynamic>?;
        isRegistered.value =
            res != null && (res['registration_state'] ?? 'none') != 'none';
        isEligible.value = res?['eligible'] == true;
        isLoading.value = false;
      },
      [workshopId],
    );

    useEffect(
      () {
        load();
        return null;
      },
      [workshopId],
    );

    return ModalSheetContainer(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2)
          .copyWith(bottom: kDefaultPadding),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ModalBottomSheetHandle(),
            if (isLoading.value)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: kDefaultPadding * 2,
                ),
                child: SpinKitCircle(
                  color: Theme.of(context).primaryColorDark,
                  size: 30,
                ),
              )
            else if (workshop.value == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
                child: Text(
                  context.t.errorLoadingWorkshop,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
              )
            else if (isRegistered.value)
              _Registered(link: workshop.value!['link'] as String? ?? '')
            else
              _Details(
                workshop: workshop.value!,
                isEligible: isEligible.value,
                isRegistering: isRegistering.value,
                onRegister: () async {
                  isRegistering.value = true;
                  final ok = await HttpFunctionsRepository.registerToWorkshop(
                    workshopId,
                  );

                  if (!context.mounted) {
                    return;
                  }

                  isRegistering.value = false;

                  if (ok) {
                    isRegistered.value = true;
                  } else {
                    BotToastUtils.showError(t.errorRegisteringWorkshop);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.workshop,
    required this.isEligible,
    required this.isRegistering,
    required this.onRegister,
  });

  final Map<String, dynamic> workshop;
  final bool isEligible;
  final bool isRegistering;
  final Function() onRegister;

  @override
  Widget build(BuildContext context) {
    final isOpen = workshop['registration_open'] == true && isEligible;
    final status = workshop['status'] as String? ?? '';
    final count = workshop['registrations_count'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: kDefaultPadding / 2,
      children: [
        CommonThumbnail(
          image: workshop['cover_image'] as String? ?? '',
          width: double.infinity,
          height: 20.h,
          isRound: true,
          radius: kDefaultPadding / 2,
          fit: BoxFit.cover,
        ),
        Row(
          spacing: kDefaultPadding / 2,
          children: [
            if (status.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                  vertical: kDefaultPadding / 6,
                ),
                decoration: BoxDecoration(
                  color: kMainColor,
                  borderRadius: BorderRadius.circular(kDefaultPadding),
                ),
                child: Text(
                  status.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: Colors.white,
                      ),
                ),
              ),
            Text(
              context.t.nRegistered(number: count.toString()),
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
            ),
          ],
        ),
        Text(
          workshop['title'] as String? ?? '',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          workshop['description'] as String? ?? '',
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: !isOpen || isRegistering ? null : onRegister,
            child: isRegistering
                ? const SpinKitCircle(color: Colors.white, size: 20)
                : Text(
                    isOpen
                        ? context.t.register
                        : context.t.registrationClosed,
                  ),
          ),
        ),
      ],
    );
  }
}

class _Registered extends StatelessWidget {
  const _Registered({required this.link});

  final String link;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: kDefaultPadding / 2,
        children: [
          Container(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            decoration: const BoxDecoration(
              color: kGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.check,
              color: Colors.white,
              size: 30,
            ),
          ),
          Text(
            context.t.youAreRegistered,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            context.t.youAreRegisteredDesc,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          if (link.isNotEmpty)
            TextButton(
              onPressed: () => launchInstantUrl(link),
              child: Text(context.t.openWorkshopLink),
            ),
        ],
      ),
    );
  }
}
