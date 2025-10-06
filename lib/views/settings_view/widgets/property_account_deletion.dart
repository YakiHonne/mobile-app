import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/properties_cubit/properties_cubit.dart';
import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../utils/utils.dart';
import '../../widgets/response_snackbar.dart';

class PropertyAccountDeletion extends StatelessWidget {
  const PropertyAccountDeletion({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertiesCubit, PropertiesState>(
      builder: (context, state) {
        return OutlinedButton(
          style: OutlinedButton.styleFrom(side: const BorderSide(color: kRed)),
          onPressed: () {
            showAccountDeletionDialogue(
              context: context,
              onDelete: () {
                context.read<PropertiesCubit>().deleteUserAccount(
                  onSuccess: () {
                    Navigator.pop(context);
                    nostrRepository.mainCubit.disconnect();
                    context
                        .read<WalletsManagerCubit>()
                        .deleteWalletConfiguration();
                  },
                );
              },
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.delete,
                color: kRed,
              ),
              const SizedBox(
                width: kDefaultPadding / 1.5,
              ),
              Text(
                context.t.deleteAccount.capitalizeFirst(),
                style: Theme.of(context)
                    .textTheme
                    .labelLarge!
                    .copyWith(color: kRed),
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
            ],
          ),
        );
      },
    );
  }
}
