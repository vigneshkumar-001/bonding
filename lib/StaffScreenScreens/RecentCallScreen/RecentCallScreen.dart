import 'dart:ui';

import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/RecentCallScreen/Model/recentCallModel.dart';
import 'package:bonding_app/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:bonding_app/theme/brand_theme.dart';
import 'package:bonding_app/ui/app_loader.dart';
import 'package:bonding_app/ui/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RecentCallsPage extends StatefulWidget {
  final bool backPage;
  const RecentCallsPage({super.key, required this.backPage});

  @override
  State<RecentCallsPage> createState() => _RecentCallsPageState();
}

class _RecentCallsPageState extends State<RecentCallsPage> {
  String selectedFilter = "all calls";
  bool isSearchVisible = true; // for search toggle

  @override
  void initState() {
    super.initState();
    // Fetch data when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffViewModel>().fetchCallHistory();
    });
  }

  List<CallHistoryItem> get filteredCalls {
    final vm = context.watch<StaffViewModel>();
    final calls = vm.callHistory;

    switch (selectedFilter) {
      case "video calls":
        return calls.where((c) => c.callType == "video").toList();
      case "audio calls":
        return calls.where((c) => c.callType == "audio").toList();
      // case "Missed calls":
      //   return calls.where((c) => c.callDuration == "-1").toList();
      default:
        return calls;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffViewModel>(
      builder: (context, vm, child) {
        final cs = Theme.of(context).colorScheme;
        return AppScaffold(
          body: vm.isLoading
              ? const AppLoader.center()
              : vm.errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            vm.errorMessage!,
                            style: TextStyle(color: cs.error),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: vm.refresh,
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        _topBar(context),
                        const SizedBox(height: 12),
                        _filterChips(),
                        const SizedBox(height: 12),
                        Expanded(child: _callList(vm)),
                      ],
                    ),
        );
      },
    );
  }

  Widget _topBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
         widget.backPage? GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.arrow_back, color: cs.onSurface, size: 28),
              ),
            ),
          ):GestureDetector(
           onTap: () => bondNavigator.newPageRemoveUntil(context, page: StaffBottomBar(index: 0,)),
           child: Container(
             decoration: BoxDecoration(
               color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
               borderRadius: BorderRadius.circular(14),
             ),
             child: Padding(
               padding: EdgeInsets.all(8.0),
               child: Icon(Icons.arrow_back, color: cs.onSurface, size: 28),
             ),
           ),
         ),
          if (isSearchVisible) ...[
            const SizedBox(width: 12),
            Text(
              "Recent Calls",
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const Spacer(),
          if (!isSearchVisible)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.45),
                          width: 0.8,
                        ),
                      ),
                      child: TextField(
                        style: TextStyle(color: cs.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Search by \u201Cname, status\u201D',
                          hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
                          prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant, size: 22),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          GestureDetector(
            onTap: () => setState(() => isSearchVisible = !isSearchVisible),
            child: Image.asset('assets/Images/search.png', color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _filterChips() {
    final cs = Theme.of(context).colorScheme;
    final brand = BrandTheme.of(context);
    final filters = ["all calls", "video calls", "audio calls"];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => selectedFilter = filter),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: isSelected ? brand.primaryGradient : null,
                color: isSelected
                    ? null
                    : cs.surfaceContainerHighest.withValues(alpha: 0.55),
                border: isSelected
                    ? null
                    : Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.45),
                      ),
              ),
              child: Text(
                filter,
                style: TextStyle(color: isSelected ? cs.onPrimary : cs.onSurface),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _callList(StaffViewModel vm) {
    final cs = Theme.of(context).colorScheme;
    if (vm.callHistory.isEmpty) {
      return Center(
        child: Text(
          "No call history yet",
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredCalls.length,
      itemBuilder: (context, index) {
        final call = filteredCalls[index];
        final isMissed = call.status == CallStatus.missed;
        final isVideo = call.callType == "video";

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundImage: AssetImage("assets/Images/profile.png"),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      call.staffName,
                      style: TextStyle(
                        color: isMissed ? Colors.redAccent : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isMissed ? Icons.call_received : Icons.call_made,
                          color: isMissed ? Colors.redAccent : Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        AppText(
                          call.createdAt.toString().substring(0, 16), // e.g. "2026-01-26 11:31"
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Column(
                children: [
                  Icon(
                    isVideo ? Icons.videocam : Icons.call,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    call.callDuration == "-1" ? "Missed" : "${call.callDuration}s",
                    style: TextStyle(
                      color: isMissed ? Colors.redAccent : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
