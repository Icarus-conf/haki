import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final String searchQuery;
  final bool isDarkMode;

  const EmptyStateWidget({super.key, required this.searchQuery, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
              ),
              const SizedBox(height: 32),
              Text(
                searchQuery.isEmpty ? 'No friends yet' : 'No results found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white70 : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                searchQuery.isEmpty
                    ? 'Start by adding your first friend'
                    : 'Try a different search term',
                style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
