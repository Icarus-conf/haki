import 'package:flutter/material.dart';

import 'loading_indicator.dart';

class FullPageLoading extends StatelessWidget {
  final String? message;
  const FullPageLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.fromARGB(255, 29, 30, 126), Color.fromARGB(255, 107, 92, 255)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // const Text(
            //   'Haki',
            //   style: TextStyle(
            //     fontSize: 48,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.white,
            //     letterSpacing: 2.0,
            //   ),
            // ),
            const SizedBox(height: 20),
            const LoadingIndicator(size: 200),
            if (message != null) ...[
              const SizedBox(height: 24),
              Text(
                message!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
