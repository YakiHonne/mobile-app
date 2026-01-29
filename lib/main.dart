import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'initializers.dart';
import 'logic/localization_cubit/localization_cubit.dart';
import 'logic/relays_progress_cubit/relays_progress_cubit.dart';
import 'logic/theme_cubit/theme_cubit.dart';
import 'routes/app_router.dart';
import 'utils/global_keys.dart';
import 'utils/utils.dart';
import 'views/widgets/relay_progress_bar.dart';

class AppConstants {
  static const String sentryDsn =
      'https://d6e3ba87d6dfb18e7dc4dc75ff028eda@o4508401650565120.ingest.de.sentry.io/4508401653317712';

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
  ];

  // Navigator observers list
  static final List<NavigatorObserver> navigatorObservers = [
    BotToastNavigatorObserver(),
    routeObserver,
  ];
}

void main() async {
  await AppInitializer.initApp();

  if (nostrRepository.isCrashlyticsEnabled) {
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConstants.sentryDsn;
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
    TranslationProvider(
      child: const MyApp(),
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

    return Sizer(
      builder: (context, orientation, deviceType) => MultiRepositoryProvider(
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
                        theme: state.theme,
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
      ),
    );
  }
}
