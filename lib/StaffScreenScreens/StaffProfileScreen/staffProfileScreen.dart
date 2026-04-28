import 'package:bonding_app/BondingScreens/AccountSettingScreen/AccountSetting.dart';
// ← staff wallet
import 'package:bonding_app/Bonding_Utils/App_Theme/App_Theme.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:bonding_app/StaffScreenScreens/WalletFlow/WalletScreen/WalletScreen.dart';
import 'package:bonding_app/StaffScreenScreens/WithdrawScreen/WithdrawHistory.dart';
import 'package:bonding_app/theme/brand_theme.dart';
import 'package:bonding_app/ui/app_loader.dart';
import 'package:bonding_app/ui/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../BondingScreens/AuthService.dart';
import '../../BondingScreens/Splash/SplashScreen2.dart';
import '../../BondingScreens/SupportScreen/support_screen.dart';

class StaffProfileScreen extends StatefulWidget {
  final bool backPage;
  const StaffProfileScreen({super.key, required this.backPage});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<StaffViewModel>(
      builder: (context, staffVM, child) {
        final staff = staffVM.currentStaff;
        final staffData = staffVM.staffData;
        final cs = Theme.of(context).colorScheme;
        final brand = BrandTheme.of(context);

        // Loading / error states
        if (staffVM.isFetchingSingleStaff) {
          return const AppScaffold(body: AppLoader.center());
        }

        if (staff == null) {
          final cs = Theme.of(context).colorScheme;
          return AppScaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "No women profile data available",
                      style: TextStyle(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: staffVM.fetchStaffSingleData,
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return AppScaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                    // Top bar: Back + Title + Edit
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          widget.backPage
                              ? GestureDetector(
                                  onTap: () => bondNavigator.backPage(context),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHighest
                                          .withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.arrow_back,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ),
                                )
                              : GestureDetector(
                                  onTap: () => bondNavigator.newPageRemoveUntil(
                                    context,
                                    page: StaffBottomBar(index: 0),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHighest
                                          .withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.arrow_back,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                          AppText(
                            "Profile",
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                          const SizedBox(width: 20),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Profile Picture (using staff.image)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: brand.primaryGradient.colors.first,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: staff.image != null && staff.image!.isNotEmpty
                            ? Image.network(
                                staff.image?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Image.asset(
                                      "assets/Images/profileimg.png",
                                      fit: BoxFit.cover,
                                    ),
                              )
                            : Image.asset(
                                "assets/Images/profileimg.png",
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Staff Name
                    Text(
                      staff.name ?? "Women",
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Staff ID
                    Text(
                      "ID: ${staff.memberID}",
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Menu Items
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildMenuRow(
                              svg: "assets/Images/walleticon.svg",
                              title: "Wallet",
                              onTap: () {
                                bondNavigator.newPage(
                                  context,
                                  page: const StaffWalletScreen(),
                                );
                              },
                            ),
                            _buildMenuRow(
                              svg: "assets/Images/helpicon.svg",
                              title: "Help & support",
                              onTap: () {
                                bondNavigator.newPage(
                                  context,
                                  page: const SupportScreens(isStaff: true,),
                                );
                                // TODO: Navigate to staff help/support screen
                              },
                            ),
                            _buildMenuRow(
                              svg: "assets/Images/supporticon.svg",
                              title: "Withdraw History",
                              onTap: () {
                                bondNavigator.newPage(
                                  context,
                                  page: const WithdrawHistory(backPage: true),
                                ); // or staff-specific
                              },
                            ),
                            _buildMenuRow(
                              svg: "assets/Images/accounticon.svg",
                              title: "Account settings",
                              onTap: () {
                                bondNavigator.newPage(
                                  context,
                                  page:   AccountSettingsScreen(isStaff: true,userId: staff.id,),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Logout
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest
                              .withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.45),
                            width: 0.7,
                          ),
                        ),
                        child: _buildMenuRow(
                          svg: "assets/Images/logouticon.svg",
                          title: "Logout",
                          titleColor: cs.error,
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              barrierDismissible: true,
                              builder: (ctx) {
                                final cs = Theme.of(ctx).colorScheme;
                                return AlertDialog(
                                  backgroundColor: cs.surface,
                                  surfaceTintColor: Colors.transparent,
                                  elevation: 12,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    side: BorderSide(
                                      color:
                                          cs.outlineVariant.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  titlePadding: const EdgeInsets.fromLTRB(
                                    18,
                                    16,
                                    18,
                                    0,
                                  ),
                                  contentPadding: const EdgeInsets.fromLTRB(
                                    18,
                                    12,
                                    18,
                                    0,
                                  ),
                                  actionsPadding: const EdgeInsets.fromLTRB(
                                    12,
                                    12,
                                    12,
                                    12,
                                  ),
                                  title: Row(
                                    children: [
                                      Icon(
                                        Icons.logout_rounded,
                                        color: cs.error,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "Logout",
                                        style: TextStyle(
                                          color: cs.onSurface,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    "Do you want to log out?",
                                    style: TextStyle(color: cs.onSurfaceVariant),
                                  ),
                                  actions: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: cs.onSurface,
                                              side: BorderSide(
                                                color: cs.outlineVariant
                                                    .withValues(alpha: 0.7),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              minimumSize:
                                                  const Size.fromHeight(44),
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text("Cancel"),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: cs.error,
                                              foregroundColor: cs.onError,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              minimumSize:
                                                  const Size.fromHeight(44),
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text("Logout"),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirm != true) return;

                            await AuthService.logout(); // clear token/session here
                            if (!context.mounted) return;
                            context.read<ThemeController>().isDarkMode = true;

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SplashScreen2(),
                              ),
                            );

                            Utils.snackBar("Logged out successfully");
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Support text
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Row(
                        children: [
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 14,
                              ),
                              children: [
                                const TextSpan(
                                  text: "Need Help? please contact ",
                                ),
                                TextSpan(
                                  text: staffData?.supportEmail?? '',
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuRow({
    required String svg,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SvgPicture.asset(
              svg,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onSurface,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: titleColor ?? Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
