import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Reusable_Widgets/Common_AppBar/common_app_bar.dart';
import '../../ui/app_loader.dart';
import '../../ui/app_scaffold.dart';
import 'ViewModel/privacy_policyVM.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrivacyPolicyVM>().fetchPrivacyPolicy();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppScaffold(
      appBar: const CommonAppBar(
        title: 'Privacy Policy',
        usePaddedLeading: true,
        bg: Colors.transparent,
      ),

      body: Consumer<PrivacyPolicyVM>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const AppLoader.center();
          }

          if (vm.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Failed to load Privacy Policy",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: cs.onSurface,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      vm.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: vm.fetchPrivacyPolicy,
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            );
          }

          if (vm.content.trim().isEmpty) {
            return Center(
              child: Text(
                "No Privacy Policy found.",
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            );
          }

          return RefreshIndicator(
            color: cs.primary,
            backgroundColor: cs.surfaceContainerHighest,
            onRefresh: vm.refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  vm.content,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.9,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

