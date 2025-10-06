import 'package:flutter/cupertino.dart';

/// iOS Router Style
class SlideLeftToRightRoute<T> extends PageRoute<T>
    with CupertinoRouteTransitionMixin {
  SlideLeftToRightRoute({
    required this.builder,
    required this.settings,
    required super.fullscreenDialog,
  }) : super(
          settings: settings,
        );

  final Widget Function(BuildContext? context) builder;

  @override
  final RouteSettings settings;

  @override
  Widget buildContent(BuildContext context) => builder(context);

  @override
  String? get title => '';

  @override
  bool get maintainState => true;
}

class TransparentPageRoute<T> extends PageRouteBuilder<T> {
  TransparentPageRoute({
    required WidgetBuilder builder,
    required this.settings,
  }) : super(
          opaque: false,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.fastOutSlowIn,
                ),
              ),
              child: child,
            );
          },
        );
  @override
  final RouteSettings settings;
}

class OpacityAnimationPageRoute<T> extends PageRouteBuilder<T> {
  OpacityAnimationPageRoute({
    required WidgetBuilder builder,
    required this.settings,
  }) : super(
          opaque: false,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.fastOutSlowIn,
                ),
              ),
              child: child,
            );
          },
        );
  @override
  final RouteSettings settings;
}

class SlideupPageRoute<T> extends PageRouteBuilder<T> {
  SlideupPageRoute({
    required WidgetBuilder builder,
    required this.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.ease;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            final offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        );

  @override
  final RouteSettings settings;
}

class NoAnimationPageRoute<T> extends PageRouteBuilder<T> {
  NoAnimationPageRoute({
    required WidgetBuilder builder,
    required this.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        );
  @override
  final RouteSettings settings;
}
