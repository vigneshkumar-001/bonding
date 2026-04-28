import 'package:bonding_app/BondingScreens/AccountSettingScreen/AccountSetting.dart';
import 'package:bonding_app/BondingScreens/AuthService.dart';
import 'package:bonding_app/BondingScreens/BottomNavBar/BottomNavBar.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:bonding_app/BondingScreens/ProfileScreen/EditProfile/EditProfileScreen.dart';
import 'package:bonding_app/BondingScreens/Splash/SplashScreen2.dart';
import 'package:bonding_app/BondingScreens/SupportScreen/support_screen.dart';
import 'package:bonding_app/BondingScreens/Transactions/TransactionScreen.dart';
import 'package:bonding_app/BondingScreens/WalletScreen/WalletScreen.dart';
import 'package:bonding_app/Bonding_Utils/App_Theme/App_Theme.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/theme/brand_theme.dart';
import 'package:bonding_app/ui/app_loader.dart';
import 'package:bonding_app/ui/app_scaffold.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../Reusable_Widgets/under_development_widgets.dart';

class ProfileScreen extends StatefulWidget {
  final bool backPage;
  const ProfileScreen({super.key, required this.backPage});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    // Listen to UserViewModel for real-time user data
    return Consumer<UserViewModel>(
      builder: (context, userVM, child) {
        final user = userVM.currentUser;
        final userDetails = userVM.userDetailsResponse;

        // If still loading or no user, show loading or fallback
        if (userVM.isLoading) {
          return const AppScaffold(
            body: AppLoader.center(),
          );
        }

        if (user == null) {
          final cs = Theme.of(context).colorScheme;
          return AppScaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "No user data available",
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: userVM.fetchUserDetails,
                    child: const Text("Retry"),
                  ),
                ],
              ),
            ),
          );
        }

        final cs = Theme.of(context).colorScheme;
        final brand = BrandTheme.of(context);
        return AppScaffold(
          safeArea: true,
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
                                        padding: const EdgeInsets.all(8.0),
                                        child: Icon(Icons.arrow_back, color: cs.onSurface),
                                      ),
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: () => bondNavigator.newPageRemoveUntil(
                                      context,
                                      page: MainBottomBar(index: 0),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: cs.surfaceContainerHighest
                                            .withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Icon(Icons.arrow_back, color: cs.onSurface),
                                      ),
                                    ),
                                  ),
                          AppText(
                            "Profile",
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                          GestureDetector(
                            onTap: () {
                              bondNavigator.newPage(
                                context,
                                page: const EditProfileScreen(),
                              );
                            },
                            child: Icon(Icons.edit, color: cs.onSurface),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Profile Picture (dynamic from API)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.primary,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: user.image != null && user.image!.isNotEmpty
                            ? Image.network(
                                user.image!,
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

                    // Username (dynamic)
                    Text(
                      user.name ?? "User",
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // User ID (dynamic)
                    Text(
                      "ID: ${user.memberID}",
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Menu Items Container
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
                        child: Column(
                          children: [
                            _buildMenuRow(
                              svg: "assets/Images/walleticon.svg",
                              title: "Wallet",
                              onTap: () {
                                bondNavigator.newPage(
                                  context,
                                  page: const WalletScreen(),
                                );
                              },
                            ),
                            _buildMenuRow(
                              svg: "assets/Images/helpicon.svg",
                              title: "Help & support",
                              onTap: () {
                                bondNavigator.newPage(
                                  context,
                                  page: const SupportScreens(isStaff: false),
                                );
                                // TODO: Navigate to help screen
                              },
                            ),
                            _buildMenuRow(
                              svg: "assets/Images/supporticon.svg",
                              title: "Transactions",
                              onTap: () {
                                bondNavigator.newPage(
                                  context,
                                  page: const TransactionsScreen(
                                    backPage: true,
                                  ),
                                );
                              },
                            ),
                            _buildMenuRow(
                              svg: "assets/Images/accounticon.svg",
                              title: "Account settings",
                              onTap: () {
                                bondNavigator.newPage(
                                  context,
                                  page: AccountSettingsScreen(
                                    userId: user.id,
                                    isStaff: false,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

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

                    // Logout Container
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    //   child: Container(
                    //     decoration: BoxDecoration(
                    //       color: const Color(0xFF231d1d),
                    //       borderRadius: BorderRadius.circular(16),
                    //     ),
                    //     child: _buildMenuRow(
                    //       svg: "assets/Images/logouticon.svg",
                    //       title: "Logout",
                    //       titleColor: const Color(0xFFFF083D),
                    //       onTap: () async {
                    //         Navigator.pushReplacement(
                    //           context,
                    //           MaterialPageRoute(builder: (_) => const SplashScreen2()),
                    //         );
                    //         await AuthService.logout();
                    //         // TODO: Handle logout (clear token, navigate to login)
                    //         Utils.snackBar("Logged out successfully");
                    //       },
                    //     ),
                    //   ),
                    // ),
                    const SizedBox(height: 20),

                    // Support Text
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
                                TextSpan(text: "Need Help? please contact "),
                                TextSpan(
                                  text: userDetails?.supportEmail,
                                  style: TextStyle(
                                    color: brand.primaryGradient.colors.first,
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
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SvgPicture.asset(
              svg,
              colorFilter: ColorFilter.mode(
                titleColor ?? cs.onSurface,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: titleColor ?? cs.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: cs.onSurfaceVariant,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
