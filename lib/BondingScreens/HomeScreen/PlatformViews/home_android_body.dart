import 'package:bonding_app/BondingScreens/HomeScreen/Model/StaffDataModel.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:bonding_app/BondingScreens/ProfileScreen/ProfileScreen.dart';
import 'package:bonding_app/BondingScreens/WalletScreen/WalletScreen.dart';
import 'package:bonding_app/Bonding_Utils/ColorHandlers/Apptheme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/Reusable_Widgets/Loading/app_loading_indicator.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeAndroidBody extends StatelessWidget {
  final UserViewModel userVM;
  final StaffViewModel staffVM;
  final bool ready;
  final bool zegoInitializing;
  final Widget Function(BuildContext context, StaffDataProfile staff) buildCard;

  const HomeAndroidBody({
    super.key,
    required this.userVM,
    required this.staffVM,
    required this.ready,
    required this.zegoInitializing,
    required this.buildCard,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = userVM.currentUser;
    return Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Image(
                image: AssetImage("assets/Images/appLogo.png"),
                height: 32,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    bondNavigator.newPage(context, page: const WalletScreen()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: Apptheme.buttonGradient,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset("assets/Images/goldcoin1.png", height: 20),
                      const SizedBox(width: 6),
                      Text(
                        "${currentUser?.coinBalance ?? 0}.00",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => bondNavigator.newPage(
                  context,
                  page: const ProfileScreen(backPage: true),
                ),
                child: _Avatar(
                  radius: 18,
                  name: currentUser?.name ?? "User",
                  imageUrl: currentUser?.image,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(
                ready ? Icons.check_circle : Icons.info,
                color: ready ? Colors.green : Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ready
                      ? "Call service ready"
                      : (zegoInitializing
                            ? "Connecting call service..."
                            : "Call service not ready"),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _StaffList(
            staffVM: staffVM,
            userVM: userVM,
            buildCard: buildCard,
          ),
        ),
      ],
    );
  }
}

class _StaffList extends StatelessWidget {
  final StaffViewModel staffVM;
  final UserViewModel userVM;
  final Widget Function(BuildContext, StaffDataProfile) buildCard;

  const _StaffList({
    required this.staffVM,
    required this.userVM,
    required this.buildCard,
  });

  @override
  Widget build(BuildContext context) {
    if (staffVM.isFetchingStaff) {
      return const Center(child: AppLoadingIndicator(color: Colors.white));
    }
    if (staffVM.staffFetchError != null) {
      return Center(
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
      );
    }
    if (staffVM.staffList.isEmpty) {
      return const Center(
        child: Text(
          "No women available",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return RefreshIndicator(
      color: Colors.white,
      onRefresh: () async {
        await Future.wait([
          staffVM.fetchStaffDetails(),
          userVM.fetchUserDetails(),
        ]);
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: staffVM.staffList.length,
        itemBuilder: (context, index) =>
            buildCard(context, staffVM.staffList[index]),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final double radius;
  final String name;
  final String? imageUrl;

  const _Avatar({
    required this.radius,
    required this.name,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final first = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "?";
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white.withOpacity(0.10),
      child: Text(
        first,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
