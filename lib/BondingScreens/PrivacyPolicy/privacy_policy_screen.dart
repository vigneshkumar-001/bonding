import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Reusable_Widgets/Common_AppBar/common_app_bar.dart';
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
    return Scaffold(
      backgroundColor: Color(0xFF100A0A),
      appBar: CommonAppBar(
        title: 'Privacy Policy',
        usePaddedLeading: true,
        bg: Color(0xFF100A0A),
      ),

      body: Consumer<PrivacyPolicyVM>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
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
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(vm.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A1C1C),
                        foregroundColor: Colors.white,
                      ),
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
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            );
          }

          return RefreshIndicator(
            color: Colors.white, // ✅ visible on dark
            backgroundColor: const Color(0xFF1A1212),
            onRefresh: vm.refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  vm.content,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.9,
                    color: Colors.white.withOpacity(
                      0.78,
                    ), // ✅ better readability
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
