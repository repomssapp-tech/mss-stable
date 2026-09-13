import 'package:flutter/material.dart';

/// Owns the pulse/wave animation controllers used to indicate active
/// listening on the Saarthi companion screen, extracted from
/// `SaarthiHomeScreen` so the coordinator only calls `start()`/`stop()`.
class SaarthiVoiceAnimations {
  SaarthiVoiceAnimations(TickerProvider vsync)
    : pulseController = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 800),
        lowerBound: 0.82,
        upperBound: 1.0,
        value: 1.0,
      ),
      waveController = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 900),
      );

  final AnimationController pulseController;
  final AnimationController waveController;

  /// Starts or stops the listening animations, respecting reduced-motion.
  void setListening(bool listening, {required bool reduceMotion}) {
    if (reduceMotion) {
      stop();
      return;
    }
    if (listening) {
      if (!pulseController.isAnimating) pulseController.repeat(reverse: true);
      if (!waveController.isAnimating) waveController.repeat();
    } else {
      stop();
    }
  }

  void stop() {
    pulseController.stop();
    pulseController.value = 1.0;
    waveController.stop();
    waveController.value = 0.0;
  }

  void dispose() {
    pulseController.dispose();
    waveController.dispose();
  }
}
