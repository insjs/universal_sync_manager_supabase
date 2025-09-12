import 'package:flutter/material.dart';

/// Widget that displays connection and authentication status
class StatusDisplay extends StatelessWidget {
  final String status;
  final bool isConnected;
  final bool isAuthenticated;

  const StatusDisplay({
    super.key,
    required this.status,
    required this.isConnected,
    required this.isAuthenticated,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _StatusItem(
              icon: Icons.cable,
              label: 'Connection',
              value: isConnected ? 'Connected' : 'Disconnected',
              isSuccess: isConnected,
            ),
            _StatusItem(
              icon: Icons.lock,
              label: 'Authentication',
              value: isAuthenticated ? 'Authenticated' : 'Not authenticated',
              isSuccess: isAuthenticated,
            ),
            _StatusItem(
              icon: Icons.info,
              label: 'Current Status',
              value: status,
              isSuccess: null, // Neutral status
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool? isSuccess;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {
    Color? iconColor;
    if (isSuccess != null) {
      iconColor = isSuccess! ? Colors.green : Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor ?? Theme.of(context).iconTheme.color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
