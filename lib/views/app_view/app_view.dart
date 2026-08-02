// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../common/animations/heartbeat_fade.dart';
import '../../logic/smart_widget_app_cubit/smart_widget_app_cubit.dart';
import '../../models/smart_widgets_components.dart';
import '../../utils/utils.dart';
import '../widgets/app_icon.dart';
import '../widgets/buttons_containers_widgets.dart';
import '../widgets/modal_sheet_container.dart';
import '../widgets/note_container.dart';
import 'widgets/signer_view.dart';

class SmartWidgetAppView extends StatelessWidget {
  const SmartWidgetAppView({
    super.key,
    required this.url,
    this.onCustomDataAdded,
    this.smartWidget,
    this.app,
    this.title,
  });

  final String url;
  final SmartWidget? smartWidget;
  final Function(String)? onCustomDataAdded;
  final AppSmartWidget? app;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.parse(url.trim());

    return BlocProvider(
      create: (context) => SmartWidgetAppCubit(
        onCustomDataAdded: onCustomDataAdded,
        onSignEvent: (isSignPublish, content) async {
          bool onSign = false;

          await showModalBottomSheet(
            context: context,
            elevation: 0,
            builder: (_) {
              return SignerView(
                isSignPublish: isSignPublish,
                content: content,
                onSign: () {
                  onSign = true;
                  Navigator.pop(context);
                },
                onCancel: () {
                  onSign = false;
                  Navigator.pop(context);
                },
              );
            },
            isScrollControlled: true,
            useRootNavigator: true,
            useSafeArea: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          );

          return onSign;
        },
      ),
      child: ModalSheetContainer(
        child: Column(
          children: [
            _contentContainer(context, uri),
            _webViewContent(),
            if (app != null) _infoRow(context, uri)
          ],
        ),
      ),
    );
  }

  Container _infoRow(BuildContext context, Uri uri) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      height:
          kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: Row(
        spacing: kDefaultPadding / 2,
        children: [
          Expanded(
            child: ProfileInfoHeader(
              pubkey: app!.pubkey,
              createdAt: DateTime.now(),
              isMinimised: true,
            ),
          ),
          Text(
            uri.host,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).highlightColor,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Expanded _webViewContent() {
    return Expanded(
      child: BlocBuilder<SmartWidgetAppCubit, SmartWidgetAppState>(
        builder: (context, state) {
          return Stack(
            children: [
              WebViewPage(url: url),
              if (!state.isReady)
                Positioned.fill(
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    alignment: Alignment.center,
                    child: SafeArea(
                      child: HeartbeatFade(
                        child: SvgPicture.asset(
                          LogosIcons.logoMark,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).primaryColorDark,
                            BlendMode.srcIn,
                          ),
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Container _contentContainer(BuildContext context, Uri uri) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        color: Theme.of(context).cardColor,
      ),
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        child: Row(
          spacing: kDefaultPadding / 2,
          children: [
            AppIconButton(
              onClicked: () {
                Navigator.pop(context);
              },
              icon: FeatureIcons.closeRaw,
              size: 30,
              iconSize: 20,
              enableFluid: false,
              buttonRadius: 300,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            _hostInfoRow(uri),
            _pulldownButton(context),
          ],
        ),
      ),
    );
  }

  PullDownButton _pulldownButton(BuildContext context) {
    return PullDownButton(
      animationBuilder: (context, state, child) {
        return child;
      },
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).cardColor,
      ),
      itemBuilder: (context) {
        final textStyle = Theme.of(context).textTheme.labelMedium;

        return [
          PullDownMenuItem(
            title: context.t.copy.capitalize(),
            onTap: () {
              Clipboard.setData(
                ClipboardData(text: url),
              );
            },
            itemTheme: PullDownMenuItemTheme(
              textStyle: textStyle,
            ),
            iconWidget: AppIcon(
              FeatureIcons.copy,
              size: 20,
              color: Theme.of(context).primaryColorDark,
            ),
          ),
          PullDownMenuItem(
            title: context.t.refresh.capitalize(),
            onTap: () {
              context.read<SmartWidgetAppCubit>().controller.reload();
            },
            itemTheme: PullDownMenuItemTheme(
              textStyle: textStyle,
            ),
            iconWidget: AppIcon(
              FeatureIcons.refresh,
              size: 20,
              color: Theme.of(context).primaryColorDark,
            ),
          ),
        ];
      },
      buttonBuilder: (context, showMenu) => AppIconButton(
        onClicked: () => showMenu,
        icon: FeatureIcons.more,
        iconSize: 20,
        size: 30,
        enableFluid: false,
        buttonRadius: 300,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
    );
  }

  Expanded _hostInfoRow(Uri uri) {
    return Expanded(
      child: Builder(builder: (context) {
        return Column(
          children: [
            Text(
              title ?? uri.host,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (title == null)
              Text(
                url,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).highlightColor,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        );
      }),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({
    super.key,
    required this.url,
  });

  final String url;

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late WebViewController controller;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) async {
            String system = '';

            if (Platform.isAndroid) {
              system = 'android';
            } else if (Platform.isIOS) {
              system = 'ios';
            }

            if (system.isNotEmpty) {
              await controller.runJavaScript(
                '''
                  window.originSystem = {
                  name: "$system",
                  version: "1.0.0",
                  }
                ''',
              );
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        'parent',
        onMessageReceived:
            context.read<SmartWidgetAppCubit>().handleFrameMessage,
      );

    context.read<SmartWidgetAppCubit>().setController(controller);
    controller.loadRequest(
      Uri.parse(widget.url),
    );
  }

  @override
  void dispose() {
    controller.clearCache();
    controller.clearLocalStorage();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: controller);
  }
}
