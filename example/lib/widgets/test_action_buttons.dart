import 'package:flutter/material.dart';

/// Widget that provides all test action buttons
class TestActionButtons extends StatelessWidget {
  final VoidCallback? onTestConnection;
  final VoidCallback? onTestPreAuth;
  final VoidCallback? onTestAuthentication;
  final VoidCallback? onSignOut;
  final VoidCallback? onTestSyncManager;
  final VoidCallback? onTestCrud;
  final VoidCallback? onTestBatchOperations;
  final VoidCallback? onCreateSampleData;
  final VoidCallback? onCreateLocalData;
  final VoidCallback? onCreateRemoteData;
  final VoidCallback? onTestLocalToRemote;
  final VoidCallback? onTestRemoteToLocal;
  final VoidCallback? onTestBidirectionalSync;
  final VoidCallback? onTestEventSystem;
  final VoidCallback? onTestFullEventIntegration;
  final VoidCallback? onTestConflictResolution;
  final VoidCallback? onTestTableConflicts;
  final VoidCallback? onTestQueueOperations;
  final VoidCallback? onTestAuthLifecycle;
  final VoidCallback? onTestStateManagement;
  final VoidCallback? onTestTokenManagement;
  final VoidCallback? onTestNetworkConnection;
  final VoidCallback? onTestDataIntegrity;
  final VoidCallback? onTestPerformance;
  final VoidCallback? onClearResults;

  const TestActionButtons({
    super.key,
    this.onTestConnection,
    this.onTestPreAuth,
    this.onTestAuthentication,
    this.onSignOut,
    this.onTestSyncManager,
    this.onTestCrud,
    this.onTestBatchOperations,
    this.onCreateSampleData,
    this.onCreateLocalData,
    this.onCreateRemoteData,
    this.onTestLocalToRemote,
    this.onTestRemoteToLocal,
    this.onTestBidirectionalSync,
    this.onTestEventSystem,
    this.onTestFullEventIntegration,
    this.onTestConflictResolution,
    this.onTestTableConflicts,
    this.onTestQueueOperations,
    this.onTestAuthLifecycle,
    this.onTestStateManagement,
    this.onTestTokenManagement,
    this.onTestNetworkConnection,
    this.onTestDataIntegrity,
    this.onTestPerformance,
    this.onClearResults,
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
              'Test Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Connection & Authentication',
              [
                _ActionButton(
                  label: 'Test Connection',
                  onPressed: onTestConnection,
                  backgroundColor: Colors.blue,
                ),
                _ActionButton(
                  label: 'Pre-Auth Operations',
                  onPressed: onTestPreAuth,
                  backgroundColor: Colors.orange,
                ),
                _ActionButton(
                  label: 'Test Authentication',
                  onPressed: onTestAuthentication,
                  backgroundColor: Colors.green,
                ),
                _ActionButton(
                  label: 'Sign Out',
                  onPressed: onSignOut,
                  backgroundColor: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Core Operations',
              [
                _ActionButton(
                  label: 'Test Sync Manager',
                  onPressed: onTestSyncManager,
                  backgroundColor: Colors.purple,
                ),
                _ActionButton(
                  label: 'Test CRUD',
                  onPressed: onTestCrud,
                  backgroundColor: Colors.indigo,
                ),
                _ActionButton(
                  label: 'Test Batch Operations',
                  onPressed: onTestBatchOperations,
                  backgroundColor: Colors.deepPurple,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Sample Data',
              [
                _ActionButton(
                  label: 'Create All Sample Data',
                  onPressed: onCreateSampleData,
                  backgroundColor: Colors.teal,
                ),
                _ActionButton(
                  label: 'Local Sample Data',
                  onPressed: onCreateLocalData,
                  backgroundColor: Colors.cyan,
                ),
                _ActionButton(
                  label: 'Remote Sample Data',
                  onPressed: onCreateRemoteData,
                  backgroundColor: Colors.lightBlue,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Sync Operations',
              [
                _ActionButton(
                  label: 'Local → Remote',
                  onPressed: onTestLocalToRemote,
                  backgroundColor: Colors.green,
                ),
                _ActionButton(
                  label: 'Remote → Local',
                  onPressed: onTestRemoteToLocal,
                  backgroundColor: Colors.teal,
                ),
                _ActionButton(
                  label: '🔄 Bidirectional',
                  onPressed: onTestBidirectionalSync,
                  backgroundColor: Colors.purple,
                ),
                _ActionButton(
                  label: '📡 Event System',
                  onPressed: onTestEventSystem,
                  backgroundColor: Colors.teal,
                ),
                _ActionButton(
                  label: '🧪 Full Integration',
                  onPressed: onTestFullEventIntegration,
                  backgroundColor: Colors.deepPurple,
                ),
                _ActionButton(
                  label: '⚔️ Conflict Resolution',
                  onPressed: onTestConflictResolution,
                  backgroundColor: Colors.red[700],
                ),
                _ActionButton(
                  label: '📋 Table Conflicts',
                  onPressed: onTestTableConflicts,
                  backgroundColor: Colors.orange[700],
                ),
                _ActionButton(
                  label: '🔄 Queue & Scheduling',
                  onPressed: onTestQueueOperations,
                  backgroundColor: Colors.teal[700],
                ),
                _ActionButton(
                  label: '🔐 Auth Lifecycle',
                  onPressed: onTestAuthLifecycle,
                  backgroundColor: Colors.indigo[700],
                ),
                _ActionButton(
                  label: '🔄 State Management',
                  onPressed: onTestStateManagement,
                  backgroundColor: Colors.purple[700],
                ),
                _ActionButton(
                  label: '🔐 Token Management',
                  onPressed: onTestTokenManagement,
                  backgroundColor: Colors.green[700],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Phase 5: Edge Cases & Performance',
              [
                _ActionButton(
                  label: '🌐 Network Connection',
                  onPressed: onTestNetworkConnection,
                  backgroundColor: Colors.deepOrange[600],
                ),
                _ActionButton(
                  label: '🔍 Data Integrity',
                  onPressed: onTestDataIntegrity,
                  backgroundColor: Colors.deepPurple[600],
                ),
                _ActionButton(
                  label: '⚡ Performance Testing',
                  onPressed: onTestPerformance,
                  backgroundColor: Colors.amber[700],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ActionButton(
              label: 'Clear Results',
              onPressed: onClearResults,
              backgroundColor: Colors.grey[600],
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> buttons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: buttons,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final bool fullWidth;

  const _ActionButton({
    required this.label,
    this.onPressed,
    this.backgroundColor,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label),
    );

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}
