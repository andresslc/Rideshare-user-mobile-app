import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';

/// Cross-platform route transitions for GoRouter.
///
/// Transitions are chosen by route path so every screen in a flow feels
/// consistent on both iOS and Android.
enum AppPageTransition {
  /// Splash and cold-start handoffs.
  fade,

  /// Standard stack push (settings, profile, history, chat, auth steps).
  slideForward,

  /// Sheet-style flows (pickers, forms opened from map/home).
  slideUp,

  /// Root replacements and milestone screens (home, success, ride complete).
  fadeThrough,
}

abstract final class AppPages {
  static const Duration _fadeDuration = Duration(milliseconds: 260);
  static const Duration _slideDuration = Duration(milliseconds: 200);
  static const Duration _modalDuration = Duration(milliseconds: 340);
  static const Duration _fadeThroughDuration = Duration(milliseconds: 320);

  static Page<T> forRoute<T>({
    required GoRouterState state,
    required Widget child,
    AppPageTransition? transition,
  }) {
    return build<T>(
      key: state.pageKey,
      child: child,
      transition: transition ?? _transitionForPath(state.uri.path),
    );
  }

  static Page<T> build<T>({
    required LocalKey key,
    required Widget child,
    AppPageTransition transition = AppPageTransition.slideForward,
  }) {
    final durations = switch (transition) {
      AppPageTransition.fade => (
        forward: _fadeDuration,
        reverse: _fadeDuration,
      ),
      AppPageTransition.slideForward => (
        forward: _slideDuration,
        reverse: _slideDuration,
      ),
      AppPageTransition.slideUp => (
        forward: _modalDuration,
        reverse: _modalDuration,
      ),
      AppPageTransition.fadeThrough => (
        forward: _fadeThroughDuration,
        reverse: _fadeThroughDuration,
      ),
    };

    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: durations.forward,
      reverseTransitionDuration: durations.reverse,
      transitionsBuilder: (context, animation, secondaryAnimation, page) {
        return switch (transition) {
          AppPageTransition.fade => _fade(page, animation),
          AppPageTransition.slideForward => _slideForward(
            page,
            animation,
            secondaryAnimation,
          ),
          AppPageTransition.slideUp => _slideUp(
            page,
            animation,
            secondaryAnimation,
          ),
          AppPageTransition.fadeThrough => _fadeThrough(page, animation),
        };
      },
    );
  }

  static AppPageTransition _transitionForPath(String path) {
    if (path == Routes.root.path) {
      return AppPageTransition.fade;
    }

    if (path == Routes.home.path ||
        path == Routes.success.path ||
        path == Routes.ridecomplete.path ||
        path == Routes.carpoolRideComplete.path) {
      return AppPageTransition.fadeThrough;
    }

    if (path == Routes.placePicker.path ||
        path == Routes.ridePlacePicker.path ||
        path == Routes.enterRoute.path ||
        path == Routes.addCard.path ||
        path == Routes.feedback.path) {
      return AppPageTransition.slideUp;
    }

    return AppPageTransition.slideForward;
  }

  static Widget _fade(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(opacity: curved, child: child);
  }

  static Widget _fadeThrough(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
    );
    final scale = Tween<double>(begin: 0.98, end: 1).animate(curved);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(scale: scale, child: child),
    );
  }

  static Widget _slideForward(
    Widget child,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.6, 0),
        end: Offset.zero,
      ).animate(curved),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.94, end: 1).animate(curved),
        child: child,
      ),
    );
  }

  static Widget _slideUp(
    Widget child,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.14),
        end: Offset.zero,
      ).animate(curved),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.98, end: 1).animate(curved),
        child: child,
      ),
    );
  }
}
