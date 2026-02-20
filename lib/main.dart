import 'package:bonding_app/BondingScreens/BlockedUsers/ViewModel/blocked_users_list_vm.dart';
import 'package:bonding_app/BondingScreens/BlockedUsers/ViewModel/unblock_user_vm.dart';
import 'package:bonding_app/BondingScreens/Chat/ViewModel/user_chat_list_vm.dart';
import 'package:bonding_app/BondingScreens/DeleteAccountScreeen/ViewModel/delete_account_reasons_vm.dart';
import 'package:bonding_app/BondingScreens/DeleteAccountScreeen/ViewModel/delete_account_vm.dart';
import 'package:bonding_app/BondingScreens/HistoryCard/ViewModel/user_call_history_vm.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/Repo/call_controller.dart';
import 'package:bonding_app/StaffScreenScreens/staffChat/Repository/staff_repository.dart';
import 'package:bonding_app/StaffScreenScreens/staffChat/ViewModel/StaffChatListVm.dart';
import 'package:bonding_app/StaffScreenScreens/staffChat/ViewModel/block_user_vm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bonding_app/APIService/Remote/network/NetworkApiService.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/Repo/UserDataRepo.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';

import 'package:bonding_app/BondingScreens/LoginScreens/Repository/LoginRepo.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/ViewModel/LoginVM.dart';

import 'package:bonding_app/BondingScreens/PrivacyPolicy/Repository/settings_repository.dart';
import 'package:bonding_app/BondingScreens/Splash/SplashScreen.dart';

import 'package:bonding_app/BondingScreens/SupportScreen/ViewModel/support_ticket_list_vm.dart';
import 'package:bonding_app/BondingScreens/SupportScreen/ViewModel/support_ticket_vm.dart';
import 'package:bonding_app/BondingScreens/SupportScreen/ViewModel/ticket_history_vm.dart';
import 'package:bonding_app/BondingScreens/SupportScreen/ViewModel/ticket_message_vm.dart';

import 'package:bonding_app/BondingScreens/PrivacyPolicy/ViewModel/privacy_policyVM.dart';

import 'package:bonding_app/BondingScreens/Transactions/TransactionScreen.dart';
import 'package:bonding_app/BondingScreens/Transactions/ViewModel/TransactionHistoryVM.dart';

import 'package:bonding_app/BondingScreens/WalletScreen/razorPayFlow/Repository/PaymentRepo.dart';
import 'package:bonding_app/BondingScreens/WalletScreen/razorPayFlow/ViewModel/PaymentVM.dart';
import 'BondingScreens/Chat/Repository/chat_repository.dart';

import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/Repo/StaffRegisterRepo.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';

// ✅ IMPORTANT: keep ONLY ONE import (lowercase folder)

import 'package:provider/single_child_widget.dart';

import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:zego_zimkit/zego_zimkit.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);

  ZegoUIKit().initLog();

  // ZIMKit().init(
  //   appID: 467997506,
  //   appSign: "ccc20b79b4824f0b6bff31c38a5cbd512cc98fb41bf4cca25d5c9df21bf0c252",
  // );
  ZIMKit().init(
    appID: 1327852448,
    appSign: "0879d8b8ca962db7ba26447774981478100de323dc760dfdf755dd2b0d0607e3",
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: getAllProviders(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const Splashscreen(),
      ),
    );
  }
}

List<SingleChildWidget> getAllProviders() {
  return [
    // ---------------- User Login ----------------
    Provider<AuthRepository>(create: (_) => AuthRepository()),
    ChangeNotifierProvider<LoginViewModel>(
      create: (context) => LoginViewModel(context.read<AuthRepository>()),
    ),

    // ---------------- Wallet / Transactions ----------------
    ChangeNotifierProvider(create: (_) => WalletViewModel(WalletRepository())),
    ChangeNotifierProvider(
      create: (_) => DepositHistoryViewModel(WalletRepository()),
    ),
    // ⚠️ Remove "child: TransactionsScreen" from provider list (wrong place)
    // Screens must be in Navigator routes, NOT inside Provider list.

    // ---------------- Settings ----------------
    ChangeNotifierProvider(
      create: (_) => PrivacyPolicyVM(SettingsRepository()),
    ),

    // ---------------- Support Ticket ----------------
    ChangeNotifierProvider(
      create: (_) => SupportTicketVM(SettingsRepository()),
    ),
    ChangeNotifierProvider(
      create: (_) => SupportTicketListVM(SettingsRepository()),
    ),
    ChangeNotifierProvider(
      create: (_) => TicketHistoryVM(SettingsRepository()),
    ),
    ChangeNotifierProvider(
      create: (_) => BlockUserVM(repo: ChatRepository(NetworkApiService())),
    ),
    ChangeNotifierProvider(
      create: (_) => DeleteAccountReasonsVM(repo: ChatRepository(NetworkApiService())),
    ),  ChangeNotifierProvider(
      create: (_) => DeleteAccountVM(repo: ChatRepository(NetworkApiService())),
    ),
    ChangeNotifierProvider(
      create: (_) => TicketMessageVM(SettingsRepository()),
    ),

    Provider<ChatRepository>(
      create: (context) => ChatRepository(context.read<NetworkApiService>()),
    ),

    // ---------------- Staff Chat List (Socket) ----------------
    ChangeNotifierProvider(
      create: (_) =>
          StaffChatListVm(repo: StaffChatRepository(NetworkApiService())),
    ),
    ChangeNotifierProvider(
      create: (_) => UserChatListVm(repo: ChatRepository(NetworkApiService())),
    ),
    ChangeNotifierProvider(
      create: (_) =>
          BlockedUsersListVm(repo: ChatRepository(NetworkApiService())),
    ),
    ChangeNotifierProvider(
      create: (_) => UnblockUserVM(repo: ChatRepository(NetworkApiService())),
    ),

    // ---------------- User Home ----------------
    Provider<UserRepository>(
      create: (_) => UserRepository(NetworkApiService()),
    ),

    ChangeNotifierProvider<CallController>(
      create: (_) => CallController(),
    ),
    ChangeNotifierProvider<UserViewModel>(
      create: (context) => UserViewModel(context.read<UserRepository>()),
      lazy: true,
    ),
    ChangeNotifierProvider<UserCallHistoryVm>(
      create: (context) => UserCallHistoryVm(context.read<UserRepository>()),
      lazy: true,
    ),
    // ---------------- Staff Flow ----------------
    Provider<StaffRepository>(
      create: (_) => StaffRepository(NetworkApiService()),
    ),
    ChangeNotifierProvider<StaffViewModel>(
      create: (context) => StaffViewModel(context.read<StaffRepository>()),
    ),
  ];
}

// import 'package:bonding_app/APIService/Remote/network/NetworkApiService.dart';
// import 'package:bonding_app/BondingScreens/HomeScreen/Repo/UserDataRepo.dart';
// import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
// import 'package:bonding_app/BondingScreens/LoginScreens/Repository/LoginRepo.dart';
// import 'package:bonding_app/BondingScreens/LoginScreens/ViewModel/LoginVM.dart';
// import 'package:bonding_app/BondingScreens/PrivacyPolicy/Model/privacy_policy_response.dart';
// import 'package:bonding_app/BondingScreens/PrivacyPolicy/Repository/settings_repository.dart';
// import 'package:bonding_app/BondingScreens/Splash/SplashScreen.dart';
// import 'package:bonding_app/BondingScreens/SupportScreen/ViewModel/support_ticket_list_vm.dart';
// import 'package:bonding_app/BondingScreens/Transactions/TransactionScreen.dart';
// import 'package:bonding_app/Socket/socket_service.dart' hide SocketService;
// import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/Repo/StaffRegisterRepo.dart';
// import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
// import 'package:bonding_app/firebase_options.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:zego_plugin_adapter/zego_plugin_adapter.dart';
// import 'package:zego_uikit/zego_uikit.dart';
// import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
// import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
// import 'package:zego_zimkit/zego_zimkit.dart';
//
// import 'BondingScreens/PrivacyPolicy/ViewModel/privacy_policyVM.dart';
// import 'BondingScreens/SupportScreen/ViewModel/support_ticket_vm.dart';
// import 'BondingScreens/SupportScreen/ViewModel/ticket_history_vm.dart';
// import 'BondingScreens/SupportScreen/ViewModel/ticket_message_vm.dart';
// import 'BondingScreens/Transactions/ViewModel/TransactionHistoryVM.dart';
// import 'BondingScreens/WalletScreen/razorPayFlow/Repository/PaymentRepo.dart';
// import 'BondingScreens/WalletScreen/razorPayFlow/ViewModel/PaymentVM.dart';
// import 'StaffScreenScreens/staffChat/ViewModel/staff_chat_list_vm.dart';
// import 'StaffScreenScreens/staffChat/viewmodel/staff_chat_list_vm.dart'; // Add this import
//
// final navigatorKey = GlobalKey<NavigatorState>();
// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   // Critical: Set navigator key BEFORE init()
//   ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);
//
//   // Optional: init logs for debugging
//   ZegoUIKit().initLog();
//   ZIMKit().init(
//     appID: 467997506, // ← your real AppID
//     appSign:
//         "ccc20b79b4824f0b6bff31c38a5cbd512cc98fb41bf4cca25d5c9df21bf0c252", // ← your real AppSign
//   );
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ...getAllProviders(), // Your custom provider list
//       ],
//       child: MaterialApp(
//         navigatorKey: navigatorKey,
//         title: 'Flutter Demo',
//         debugShowCheckedModeBanner: false,
//         theme: ThemeData(
//           colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         ),
//         home: const Splashscreen(),
//       ),
//     );
//   }
// }
//
// getAllProviders() {
//   return [
//     Provider<AuthRepository>(
//       create: (_) => AuthRepository(
//         // ApiService() or Dio() or whatever you pass here
//         // No context.read() needed
//       ),
//     ),
//     ChangeNotifierProvider<LoginViewModel>(
//       create: (context) => LoginViewModel(context.read<AuthRepository>()),
//     ),
//     ChangeNotifierProvider(create: (_) => WalletViewModel(WalletRepository())),
//     ChangeNotifierProvider(
//       create: (_) => DepositHistoryViewModel(WalletRepository()),
//       child: TransactionsScreen(backPage: true),
//     ),
//     ChangeNotifierProvider(
//       create: (_) => PrivacyPolicyVM(SettingsRepository()),
//     ),
//     ChangeNotifierProvider(
//       create: (_) => SupportTicketVM(SettingsRepository()),
//     ),
//     ChangeNotifierProvider(create: (_) => SupportTicketListVM(SettingsRepository())),
//     ChangeNotifierProvider(
//       create: (_) => TicketHistoryVM(SettingsRepository()),
//     ),
//     ChangeNotifierProvider(create: (_) => TicketMessageVM(SettingsRepository())),
//     Provider<SocketService>(create: (_) => SocketService()),
//
//     ChangeNotifierProvider<StaffChatListVM>(
//       create: (context) => StaffChatListVM(),
//     ),
//
//     Provider<UserRepository>(
//       create: (context) => UserRepository(
//         NetworkApiService(), // or however you create it
//       ),
//     ),
//
//     // 2. Then provide the ViewModel and inject repository using context.read
//     ChangeNotifierProvider<UserViewModel>(
//       create: (context) => UserViewModel(context.read<UserRepository>()),
//       lazy: true, // recommended
//     ),
//
//     //////Staff Flow////////
//     Provider<StaffRepository>(
//       create: (context) => StaffRepository(NetworkApiService()),
//     ),
//
//     ChangeNotifierProvider<StaffViewModel>(
//       create: (context) => StaffViewModel(context.read<StaffRepository>()),
//     ),
//   ];
// }
