import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_enhanced/nostr/event.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/logic/main_cubit/main_cubit.dart';
import 'package:yakihonne/models/app_models/app_customization.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/views/media_view/media_view.dart';
import 'package:yakihonne/views/profile_view/widgets/profile_media.dart';

class _MainState extends Fake implements MainState {}

class _MainCubit extends Cubit<MainState> implements MainCubit {
  _MainCubit() : super(_MainState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repository extends Fake implements NostrDataRepository {
  _Repository(this.main);
  final MainCubit main;
  @override
  MainCubit get mainCubit => main;
  @override
  AppCustomization? get currentAppCustomization => null;
}

void main() {
  testWidgets('feed media quilt follows local pane width', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final main = _MainCubit();
    nostrRepository = _Repository(main);
    addTearDown(main.close);
    final width = ValueNotifier(400.0);
    addTearDown(width.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
      child: ValueListenableBuilder<double>(
        valueListenable: width,
        builder: (context, value, child) =>
            SizedBox(width: value, height: 500, child: child),
        child: const CustomScrollView(
            slivers: [MediaGrid(content: [], loadVideos: false)]),
      ),
    ))));
    await tester.pump();
    expect(tester.takeException(), isNull);
    SliverQuiltedGridDelegate delegate() =>
        tester.widget<SliverGrid>(find.byType(SliverGrid, skipOffstage: false)).gridDelegate
            as SliverQuiltedGridDelegate;
    expect(delegate().crossAxisCount, 2);
    width.value = 950;
    await tester.pump();
    expect(delegate().crossAxisCount, 4);
    expect(tester.takeException(), isNull);
  });
  testWidgets('profile media quilt follows local pane width', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final width = ValueNotifier(400.0);
    addTearDown(width.dispose);
    final events = List.generate(
        8,
        (index) => Event.partial(
              id: 'fixture-$index',
              pubkey: 'fixture',
              kind: EventKind.PICTURE,
            ));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
      child: ValueListenableBuilder<double>(
        valueListenable: width,
        builder: (context, value, child) =>
            SizedBox(width: value, height: 500, child: child),
        child: CustomScrollView(slivers: [ProfileMediaGrid(content: events)]),
      ),
    ))));
    await tester.pump();
    SliverQuiltedGridDelegate delegate() =>
        tester.widget<SliverGrid>(find.byType(SliverGrid, skipOffstage: false)).gridDelegate
            as SliverQuiltedGridDelegate;
    expect(delegate().crossAxisCount, 2);
    width.value = 600;
    await tester.pump();
    expect(delegate().crossAxisCount, 3);
    expect(tester.takeException(), isNull);
  });
}
