import 'dart:ui';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';

import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/RecentCallScreen/Model/recentCallModel.dart';
import 'package:bonding_app/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
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
        return Scaffold(
          backgroundColor: const Color(0xFF120810),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFF5A1F3F),
                  Color(0xFF3A152A),
                  Color(0xFF140810),
                  Color(0xFF140810),
                ],
              ),
            ),
            child: SafeArea(
              child: vm.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : vm.errorMessage != null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(vm.errorMessage!, style: const TextStyle(color: Colors.redAccent)),
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
            ),
          ),
        );
      },
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
         widget.backPage? GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF35272d),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
              ),
            ),
          ):GestureDetector(
           onTap: () => bondNavigator.newPageRemoveUntil(context, page: StaffBottomBar(index: 0,)),
           child: Container(
             decoration: BoxDecoration(
               color: const Color(0xFF35272d),
               borderRadius: BorderRadius.circular(40),
             ),
             child: const Padding(
               padding: EdgeInsets.all(8.0),
               child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
             ),
           ),
         ),
          if (isSearchVisible) ...[
            const SizedBox(width: 12),
            const Text(
              "Recent Calls",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
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
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3c2733), Color(0xFF3c1b2e)],
                        ),
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.8),
                      ),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search by “name, status”',
                          hintStyle: const TextStyle(color: Color(0xFFc7c7cc), fontSize: 16),
                          prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 22),
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
            child: Image.asset('assets/Images/search.png', color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _filterChips() {
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
                gradient: isSelected
                    ? const LinearGradient(colors: [Color(0xFFB35CF6), Color(0xFFFF6F61)])
                    : const LinearGradient(colors: [Color(0xFF3c2733), Color(0xFF3c1b2e)]),
                border: isSelected ? null : Border.all(color: Colors.white24),
              ),
              child: Text(
                filter,
                style: TextStyle(color: isSelected ? Colors.white : Colors.white70),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _callList(StaffViewModel vm) {
    if (vm.callHistory.isEmpty) {
      return const Center(
        child: Text("No call history yet", style: TextStyle(color: Colors.white70, fontSize: 18)),
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