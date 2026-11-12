import 'dart:io' show HandshakeException, Platform, SocketException;

import 'package:app_links/app_links.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:cupertino_ui/cupertino_ui.dart' as cupertino_ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart' as material_ui;
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'initializers.dart';
import 'logic/localization_cubit/localization_cubit.dart';
import 'logic/main_cubit/deep_link_listener.dart';
import 'logic/main_cubit/desktop_link_channel.dart';
import 'logic/relays_progress_cubit/relays_progress_cubit.dart';
import 'logic/theme_cubit/theme_cubit.dart';
import 'routes/app_router.dart';
import 'utils/global_keys.dart';
import 'utils/theme/custom/buttons_theme.dart';
import 'utils/utils.dart';
import 'views/main_view/widgets/detail_pane.dart';
import 'views/widgets/relay_progress_bar.dart';

class AppConstants {
  // Pre-defined breakpoints to avoid recreation
  static const List<Breakpoint> responsiveBreakpoints = [
    Breakpoint(start: 0, end: 719, name: MOBILE),
    Breakpoint(start: 720, end: 1023, name: TABLET),
    Breakpoint(start: 1024, end: 1439, name: DESKTOP),
    Breakpoint(start: 1440, end: 1919, name: 'DESKTOP_LARGE'),
    Breakpoint(start: 1920, end: double.infinity, name: '4K'),
  ];

  // Pre-defined localization delegates to avoid recreation
  static const List<LocalizationsDelegate> localizationDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    FlutterQuillLocalizations.delegate,
    material_ui.GlobalMaterialLocalizations.delegate,
    cupertino_ui.GlobalCupertinoLocalizations.delegate,
  ];

  // Navigator observers list
  static final List<NavigatorObserver> navigatorObservers = [
    BotToastNavigatorObserver(),
    routeObserver,
    DetailPaneRouteTracker(),
  ];
}

void main(List<String> arguments) async {
  SentryWidgetsFlutterBinding.ensureInitialized();
  final initialLink = Platform.isLinux && arguments.length == 1
      ? Uri.tryParse(arguments.single)
      : null;
  final DesktopLinkChannel? linkChannel =
      (Platform.isWindows || Platform.isLinux) ? DesktopLinkChannel() : null;
  // Linux remote links are buffered by the runner until `ready` is sent, so a
  // link that arrives before the Dart listener still reaches the inbox.
  final Stream<Uri> linkStream = Platform.isLinux && linkChannel != null
      ? linkChannel.links
      : AppLinks().uriLinkStream;
  deepLinkInbox = DeepLinkInbox(
    linkStream,
    initialLink:
        initialLink?.scheme.toLowerCase() == 'nostr' ? initialLink : null,
    onError: (_) {},
  );
  // Signal readiness only after the inbox has subscribed, so the native side
  // never forwards a link that has nowhere to go.
  await linkChannel?.ready();
  await AppInitializer.initApp();

  await LiquidGlassWidgets.initialize();

  FocusManager.instance.highlightStrategy = isDesktopPlatform
      ? FocusHighlightStrategy.automatic
      : FocusHighlightStrategy.alwaysTouch;

  if (nostrRepository.isCrashlyticsEnabled) {
    await SentryFlutter.init(
      (options) => options
        ..dsn = dotenv.env['GLITCH_TIP_DSN']
        ..tracesSampleRate = 0.01
        ..enableAppHangTracking = false
        ..enableAutoSessionTracking = false
        ..beforeSend = (event, hint) {
          final ex = event.throwable;
          if (ex is SocketException || ex is HandshakeException) {
            return null;
          }
          if (ex is StateError &&
              (ex.message.contains('NetworkImage is an empty file') ||
                  ex.message.contains('Failed to load'))) {
            return null;
          }
          return event;
        },
      appRunner: () async {
        runnerApp();
      },
    );
  } else {
    runnerApp();
  }
}

void runnerApp() {
  runApp(
    BlocBuilder<ThemeCubit, ThemeState>(
      bloc: themeCubit,
      buildWhen: (p, c) => p.glassQuality != c.glassQuality,
      builder: (context, state) => LiquidGlassWidgets.wrap(
        respectSystemAccessibility: false,
        theme: GlassThemeData.simple(
          blur: 10,
          thickness: 30,
          quality: state.glassQuality,
        ),
        child: TranslationProvider(
          child: const MyApp(),
        ),
      ),
    ),
  );
}

class MyApp extends HookWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use hooks for better performance and state management
    useEffect(() {
      gc = context;
      walletManagerCubit.mainContext = context;

      return null;
    }, []);

    // Memoize expensive objects to prevent recreation
    final repositoryProviders = useMemoized(
      () => [
        RepositoryProvider.value(value: connectivityService),
        RepositoryProvider.value(value: localDatabaseRepository),
        RepositoryProvider.value(value: nostrRepository),
      ],
      [],
    );

    final blocProviders = useMemoized(
      () => [
        BlocProvider.value(value: themeCubit),
        BlocProvider.value(value: settingsCubit),
        BlocProvider.value(value: pointsManagementCubit),
        BlocProvider.value(value: subscriptionCubit),
        BlocProvider.value(value: subscriptionBadgeCubit),
        BlocProvider.value(value: routingCubit),
        BlocProvider.value(value: walletManagerCubit),
        BlocProvider.value(value: cashuWalletManagerCubit),
        BlocProvider.value(value: localizationCubit),
        BlocProvider.value(value: metadataCubit),
        BlocProvider.value(value: notificationsCubit),
        BlocProvider.value(value: suggestionsBoxCubit),
        BlocProvider.value(value: singleEventCubit),
        BlocProvider.value(value: notesEventsCubit),
        BlocProvider.value(value: dmsCubit),
        BlocProvider.value(value: relaysProgressCubit),
        BlocProvider.value(value: appSettingsManagerCubit),
        BlocProvider.value(value: relayInfoCubit),
        BlocProvider.value(value: mediaServersCubit),
        BlocProvider.value(value: crashlyticsCubit),
        BlocProvider.value(value: leadingCubit),
        BlocProvider.value(value: discoverCubit),
        BlocProvider.value(value: mediaCubit),
        BlocProvider.value(value: unsentEventsCubit),
        BlocProvider.value(value: videoControllerManagerCubit),
        BlocProvider.value(value: botUtilsLoadingProgressCubit),
        BlocProvider.value(value: packsSettingsCubit),
      ],
      [],
    );

    void onGlobalTap(BuildContext context) {
      FocusManager.instance.primaryFocus?.unfocus();

      if (relaysProgressCubit.state.isRelaysVisible) {
        relaysProgressCubit.setRelaysListVisibility(false);
      } else {
        context.read<RelaysProgressCubit>().dismissProgressBar();
      }
    }

    // Built as a closure, not a hoisted variable: returning the *same* widget
    // instance from a LayoutBuilder short-circuits `Element.updateChild`, so the
    // subtree would never rebuild and every `.w`/`.h`/`.sp` would freeze at its
    // first-frame value.
    Widget shell(BuildContext context) => MultiRepositoryProvider(
          providers: repositoryProviders,
          child: MultiBlocProvider(
            providers: blocProviders,
            child: BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, state) {
                return GestureDetector(
                  onTap: () => onGlobalTap(context),
                  child: BlocBuilder<LocalizationCubit, LocalizationState>(
                    builder: (context, localizationState) {
                      return RefreshConfiguration(
                        springDescription: const SpringDescription(
                          mass: 1,
                          stiffness: 364.718677686,
                          damping: 35.2,
                        ),
                        child: MaterialApp(
                          debugShowCheckedModeBanner: false,
                          theme: isDesktopPlatform
                              ? withoutHoverHighlights(state.theme.copyWith(
                                  textButtonTheme: state.isFluid
                                      ? TbuttonsTheme
                                          .desktopFluidTextButtonTheme(
                                          state.theme.textButtonTheme,
                                        )
                                      : state.theme.textButtonTheme,
                                  elevatedButtonTheme: state.isFluid
                                      ? TbuttonsTheme
                                          .desktopFluidElevatedButtonTheme(
                                          state.theme.elevatedButtonTheme,
                                        )
                                      : state.theme.elevatedButtonTheme,
                                  outlinedButtonTheme: state.isFluid
                                      ? TbuttonsTheme
                                          .desktopFluidOutlinedButtonTheme(
                                          state.theme.outlinedButtonTheme,
                                        )
                                      : state.theme.outlinedButtonTheme,
                                ))
                              : state.theme,
                          onGenerateRoute: (settings) =>
                              onGenerateRoute(settings),
                          navigatorObservers: AppConstants.navigatorObservers,
                          localizationsDelegates:
                              AppConstants.localizationDelegates,
                          locale: TranslationProvider.of(context)
                              .locale
                              .flutterLocale,
                          supportedLocales: AppLocaleUtils.supportedLocales,
                          navigatorKey: GlobalKeys.navigatorKey,
                          builder: EasyLoading.init(
                            builder: (context, child) {
                              child = botToastBuilder(context, child);

                              return Stack(
                                children: [
                                  MediaQuery(
                                    data: MediaQuery.of(context).copyWith(
                                      textScaler: TextScaler.linear(
                                        state.textScaleFactor,
                                      ),
                                      // Reserve the macOS titlebar strip once,
                                      // here, so every SafeArea and appbar in
                                      // every route clears the traffic lights.
                                      // Added, not assigned, so a phone's real
                                      // status-bar inset survives (+0 there).
                                      padding: MediaQuery.of(context)
                                          .padding
                                          .copyWith(
                                            top: MediaQuery.of(context)
                                                    .padding
                                                    .top +
                                                kMacTitlebarInset,
                                          ),
                                      viewPadding: MediaQuery.of(context)
                                          .viewPadding
                                          .copyWith(
                                            top: MediaQuery.of(context)
                                                    .viewPadding
                                                    .top +
                                                kMacTitlebarInset,
                                          ),
                                    ),
                                    child: ResponsiveBreakpoints.builder(
                                      child: child,
                                      breakpoints:
                                          AppConstants.responsiveBreakpoints,
                                    ),
                                  ),
                                  const RelaysProgressBar(),
                                ],
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );

    // ponytail: sizer's `setScreenSize` swaps width and height whenever the
    // orientation is landscape (sizer/util.dart) — which is every normal desktop
    // window. That made all 209 `.w`/`.h`/`.sp` sites measure the wrong axis, and
    // invert the moment a window was dragged across square. Forcing portrait on
    // desktop makes them measure the real axes. Mobile keeps the untouched
    // `Sizer` path; landscape phones are out of scope here.
    return isDesktopPlatform
        ? LayoutBuilder(
            builder: (context, constraints) {
              SizerUtil.setScreenSize(constraints, Orientation.portrait);

              return shell(context);
            },
          )
        : Sizer(builder: (context, _, __) => shell(context));
  }
}
