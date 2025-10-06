import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import 'custom_icon_buttons.dart';
import 'dotted_container.dart';

void showCupertinoAccountDeletedDialogue({
  required BuildContext context,
  required Function() onClicked,
}) {
  showCupertinoDialog(
    context: context,
    builder: (alertContext) => CupertinoAlertDialog(
      title: Text(
        context.t.warning.capitalizeFirst(),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.t.accountDeleted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onClicked,
          style: TextButton.styleFrom(
            backgroundColor: kTransparent,
          ),
          child: Text(
            context.t.ok,
            style: const TextStyle(
              color: kRed,
            ),
          ),
        ),
      ],
    ),
  );
}

void showCupertinoDeletionDialogue({
  required BuildContext context,
  required String title,
  required String description,
  required String buttonText,
  required Function() onDelete,
  bool? setMaxLine,
  String? toBeCopied,
}) {
  showCupertinoDialog(
    context: context,
    builder: (alertContext) => CupertinoAlertDialog(
      title: Text(
        title,
        textAlign: TextAlign.center,
        maxLines: setMaxLine != null ? 3 : null,
        overflow: TextOverflow.ellipsis,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            description,
            textAlign: TextAlign.center,
          ),
          if (toBeCopied != null) ...[
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            _dotterContainer(context, toBeCopied),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            Text(
              context.t.deleteWalletConfirmation.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: kMainColor,
                  ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: onDelete,
          style: TextButton.styleFrom(
            backgroundColor: kTransparent,
          ),
          child: Text(
            buttonText,
            style: const TextStyle(
              color: kRed,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            backgroundColor: kTransparent,
          ),
          child: Text(
            context.t.cancel.capitalizeFirst(),
            style: TextStyle(
              color: Theme.of(context).primaryColorDark,
            ),
          ),
        ),
      ],
    ),
  );
}

DottedBorder _dotterContainer(BuildContext context, String toBeCopied) {
  return DottedBorder(
    color: Theme.of(context).primaryColorDark,
    strokeCap: StrokeCap.round,
    borderType: BorderType.rRect,
    radius: const Radius.circular(kDefaultPadding / 2),
    padding: const EdgeInsets.only(left: kDefaultPadding / 4),
    dashPattern: const [4],
    child: Row(
      children: [
        Expanded(
          child: Text(
            toBeCopied,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        CustomIconButton(
          onClicked: () {
            Clipboard.setData(
              ClipboardData(text: toBeCopied),
            );

            BotToastUtils.showSuccess(
              context.t.nwcCopied.capitalize(),
            );
          },
          icon: FeatureIcons.copy,
          size: 15,
          backgroundColor: kTransparent,
        ),
      ],
    ),
  );
}

Future<void> showCupertinoCustomDialogue({
  required BuildContext context,
  required String title,
  required String description,
  required String buttonText,
  required Color buttonTextColor,
  required Function() onClicked,
  bool? setTitleMaxLine,
  bool? setDescriptionMaxLine,
}) async {
  return showCupertinoDialog(
    context: context,
    builder: (alertContext) => CupertinoAlertDialog(
      title: Text(
        title,
        textAlign: TextAlign.center,
        maxLines: setTitleMaxLine != null ? 3 : null,
        overflow: TextOverflow.ellipsis,
      ),
      content: Text(
        description,
        textAlign: TextAlign.center,
        maxLines: setDescriptionMaxLine != null ? 5 : null,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        TextButton(
          onPressed: onClicked,
          style: TextButton.styleFrom(
            backgroundColor: kTransparent,
          ),
          child: Text(
            buttonText,
            style: TextStyle(
              color: buttonTextColor,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            backgroundColor: kTransparent,
          ),
          child: Text(
            context.t.cancel.capitalizeFirst(),
            style: TextStyle(
              color: Theme.of(context).primaryColorDark,
            ),
          ),
        ),
      ],
    ),
  );
}

void showAccountDeletionDialogue({
  required BuildContext context,
  required Function() onDelete,
}) {
  final confirm = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showCupertinoDialog(
    context: context,
    builder: (alertContext) {
      return CupertinoAlertDialog(
        title: Text(
          context.t.deleteAccount.capitalizeFirst(),
          textAlign: TextAlign.center,
        ),
        content: _deleteColumn(context, formKey, confirm),
        actions: [
          _deleteButton(formKey, onDelete, context),
          _cancelButton(context),
        ],
      );
    },
  );
}

TextButton _cancelButton(BuildContext context) {
  return TextButton(
    onPressed: () {
      Navigator.pop(context);
    },
    style: TextButton.styleFrom(
      backgroundColor: kTransparent,
    ),
    child: Text(
      context.t.cancel.capitalizeFirst(),
    ),
  );
}

TextButton _deleteButton(
    GlobalKey<FormState> formKey, Function() onDelete, BuildContext context) {
  return TextButton(
    onPressed: () {
      if (formKey.currentState!.validate()) {
        onDelete.call();
      }
    },
    style: TextButton.styleFrom(
      backgroundColor: kTransparent,
    ),
    child: Text(
      context.t.delete.capitalizeFirst(),
      style: const TextStyle(
        color: kRed,
      ),
    ),
  );
}

Column _deleteColumn(BuildContext context, GlobalKey<FormState> formKey,
    TextEditingController confirm) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        context.t.deleteAccountDesc.capitalizeFirst(),
        textAlign: TextAlign.center,
      ),
      const SizedBox(
        height: kDefaultPadding,
      ),
      Form(
        key: formKey,
        child: TextFormField(
          controller: confirm,
          decoration: const InputDecoration(
            hintText: 'Type DELETE',
          ),
          validator: (value) {
            if (value == null || value.isEmpty || value != 'DELETE') {
              return 'invalid input';
            }

            return null;
          },
        ),
      ),
    ],
  );
}

void showDeletedAccountDialogue({
  required BuildContext context,
}) {
  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: Text(
          context.t.deleteAccount.capitalizeFirst(),
          textAlign: TextAlign.center,
        ),
        titleTextStyle: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.w800,
            ),
        content: Text(
          context.t.deleteAccountMessage.capitalizeFirst(),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              backgroundColor: kTransparent,
              side: BorderSide(
                color: Theme.of(context).primaryColorDark,
              ),
            ),
            child: Text(
              context.t.exit.capitalizeFirst(),
              style: TextStyle(
                color: Theme.of(context).primaryColorDark,
              ),
            ),
          ),
        ],
      );
    },
  );
}
