import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';

class CustomRefreshIndicatorBuilder {
  static Widget build(IndicatorController controller) {
    final progress = controller.value.clamp(0.0, 1.0);
    final isRefreshing = controller.state == IndicatorState.loading;

    return Container(
      height: 80,
      padding: const EdgeInsets.only(top: 20),
      child: Center(
        child: Transform.scale(
          scale: 0.8 + (progress * 0.4), // Scale from 0.8 to 1.2 based on progress
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color.fromARGB(255, 29, 30, 126), Color.fromARGB(255, 107, 92, 255)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 107, 92, 255).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle with progress
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    value: isRefreshing ? null : progress,
                    strokeWidth: 3,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                // Icon in center with rotation animation
                Transform.rotate(
                  angle: isRefreshing ? progress * 6.28 : 0, // Full rotation when refreshing
                  child: Icon(
                    isRefreshing ? Icons.refresh : Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
