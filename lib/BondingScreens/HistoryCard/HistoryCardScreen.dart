import 'dart:ui';

import 'package:bonding_app/BondingScreens/Chat/ChatDetailScreen.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/Model/StaffDataModel.dart'; // ← assuming this exists
import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:bonding_app/BondingScreens/ProfileScreen/ProfileScreen.dart';
import 'package:bonding_app/BondingScreens/WalletScreen/WalletScreen.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:bonding_app/StaffScreenScreens/staffChat/ZimkitService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zego_zimkit/zego_zimkit.dart';
import 'package:zego_zim/zego_zim.dart';  // ← ADD THIS LINE

class HistoryCard extends StatefulWidget {
  const HistoryCard({super.key});

  @override
  State<HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<HistoryCard> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<StaffViewModel,UserViewModel>(
      builder: (context, staffVM, userVM,child) {
        final currentUser = userVM.currentUser;

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF140810),
                  Color(0xFF3A152A),
                  Color(0xFF140810),
                  Color(0xFF140810),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        SvgPicture.asset("assets/Images/bonding.svg", height: 32),
                        const Spacer(),

                        // Coin balance (dynamic if you have user model)
                        Consumer<UserViewModel>(
                          builder: (context, userVM, _) {
                            final balance = userVM.currentUser?.coinBalance ?? 10.00;
                            return GestureDetector(
                              onTap: () {
                                bondNavigator.newPage(context, page: const WalletScreen());
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFcc529f), Color(0xFFf86460)],
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Image.asset("assets/Images/goldcoin1.png", height: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      "${balance.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(width: 12),

                        // Profile avatar
                        GestureDetector(
                          onTap: () => bondNavigator.newPage(context, page: const ProfileScreen(backPage: true,)),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundImage: (currentUser?.image != null && currentUser!.image!.isNotEmpty)
                                ? NetworkImage(currentUser.image!)
                                : const AssetImage("assets/Images/profile.png") as ImageProvider,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF35272d),
                                Color(0xFF3e2534),
                                Color(0xFF3c1b2f),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 0.8,
                            ),
                          ),
                          child: TextField(
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search by “name, call topics”',
                              hintStyle: const TextStyle(
                                color: Color(0xFFc7c7cc),
                                fontSize: 16,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.white70,
                                size: 22,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Staff / History List
                  Expanded(
                    child: staffVM.isFetchingStaff
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : staffVM.staffFetchError != null
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            staffVM.staffFetchError!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: staffVM.fetchStaffDetails,
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    )
                        : staffVM.staffList.isEmpty
                        ? const Center(
                      child: Text(
                        "No history or staff available",
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                        : RefreshIndicator(
                      onRefresh: staffVM.fetchStaffDetails,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: staffVM.staffList.length,
                        itemBuilder: (context, index) {
                          final staff = staffVM.staffList[index];
                          return _profileCard(context, staff);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _profileCard(BuildContext context, StaffDataProfile staff) {
    final age = _calculateAge(staff.dob ?? '');

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient:  LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white.withOpacity(0.10), Colors.white.withOpacity(0.04)],

            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 0.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        "${staff.name ?? 'Unknown'}, ${age ?? '23'}",
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: const [
                          Icon(Icons.circle, size: 8, color: Colors.green),
                          SizedBox(width: 6),
                          Text(
                            "Tamil", // ← can be dynamic from staff model later
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: (staff.image != null && staff.image!.isNotEmpty)
                        ? NetworkImage(staff.image!)
                        : const AssetImage("assets/Images/videocallprofile.png") as ImageProvider,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Tags / Interests
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: staff.areaOfInterest
                      .map((interest) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _Tag(interest.title ?? ''),
                  ))
                      .toList(),
                ),
              ),

              const SizedBox(height: 10),

              // Bio / Description
              AppText(
                  "No bio available yet...",
                color: Colors.white,
                fontSize: 15,
                maxLines: 3,
                fontWeight: FontWeight.w500,
              ),

              const SizedBox(height: 14),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _actionButton(
                      img: "assets/Images/goldcoin1.png",
                      text: "20/min",
                      icon: Icons.call,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _actionButton(
                      img: "assets/Images/goldcoin1.png",
                      text: "60/min",
                      icon: Icons.video_call,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Inside _profileCard → the Chat button GestureDetector

                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final userVM = Provider.of<UserViewModel>(context, listen: false);
                        final currentUser = userVM.currentUser;

                        if (currentUser == null) return;

                        final connected = await ZimConnectionService.ensureConnected(
                          context,
                          userId: currentUser.memberID,
                          userName: currentUser.name ?? "User",
                        );

                        if (!connected) return;

                        bondNavigator.newPage(
                          context,
                          page: ChatDetailScreen(
                            conversationID: staff.memberID,
                            conversationType: ZIMConversationType.peer,
                            name: staff.name ?? "Staff",
                            staffId: staff.id,
                          ),
                        );
                      },
                      child:  Center(
                        child: Image.asset(
                          "assets/Images/chaticon.png",

                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String img,
    required String text,
    required IconData icon,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF9251d0), Color(0xFFf56463)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(img, height: 20),
          const SizedBox(width: 4),
          AppText(
            text,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(width: 6),
          Icon(icon, color: Colors.white),
        ],
      ),
    );
  }

  int? _calculateAge(String dob) {
    if (dob.isEmpty || dob == 'null') return null;

    // Debug print to see input
    debugPrint("Calculating age for DOB: '$dob'");

    try {
      // Expected format: dd/mm/yyyy
      final parts = dob.split('/');
      if (parts.length != 3) {
        debugPrint("Invalid date format: $dob");
        return null;
      }

      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day == null || month == null || year == null) {
        debugPrint("Failed to parse numbers from: $dob");
        return null;
      }

      final birthDate = DateTime(year, month, day);
      final now = DateTime.now();

      int age = now.year - birthDate.year;

      // Adjust if birthday hasn't occurred this year
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      // Age can't be negative or unrealistic
      if (age < 0 || age > 120) {
        debugPrint("Calculated age invalid: $age");
        return null;
      }

      debugPrint("Calculated age: $age");
      return age;
    } catch (e) {
      debugPrint("Error calculating age: $e");
      return null;
    }}
}

class _Tag extends StatelessWidget {
  final String text;

  const _Tag(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(colors: [
          Color(0xFF45333c),
          Color(0xFF4a263c),
        ]),
        border: Border.all(color: const Color(0xFF5a3c4e)),
      ),
      child: AppText(
        text,
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}