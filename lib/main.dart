import 'package:bonding_app/APIService/Remote/network/NetworkApiService.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/Repo/UserDataRepo.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/Repository/LoginRepo.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:bonding_app/BondingScreens/Splash/SplashScreen.dart';
import 'package:bonding_app/BondingScreens/Transactions/TransactionScreen.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/Repo/StaffRegisterRepo.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:bonding_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zego_plugin_adapter/zego_plugin_adapter.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:zego_zimkit/zego_zimkit.dart';

import 'BondingScreens/Transactions/ViewModel/TransactionHistoryVM.dart';
import 'BondingScreens/WalletScreen/razorPayFlow/Repository/PaymentRepo.dart';
import 'BondingScreens/WalletScreen/razorPayFlow/ViewModel/PaymentVM.dart'; // Add this import
final navigatorKey = GlobalKey<NavigatorState>();
void main() {
  WidgetsFlutterBinding.ensureInitialized();


// Critical: Set navigator key BEFORE init()
  ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);

  // Optional: init logs for debugging
  ZegoUIKit().initLog();
  ZIMKit().init(
    appID: 467997506,                  // ← your real AppID
    appSign: "ccc20b79b4824f0b6bff31c38a5cbd512cc98fb41bf4cca25d5c9df21bf0c252",  // ← your real AppSign
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ...getAllProviders(), // Your custom provider list

      ],
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


getAllProviders() {
  return [
    Provider<AuthRepository>(
      create: (_) => AuthRepository(
        // ApiService() or Dio() or whatever you pass here
        // No context.read() needed
      ),
    ),
    ChangeNotifierProvider<LoginViewModel>(
      create: (context) => LoginViewModel(
        context.read<AuthRepository>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (_) => WalletViewModel(WalletRepository()),
    ),
    ChangeNotifierProvider(
      create: (_) => DepositHistoryViewModel(WalletRepository()),
      child: TransactionsScreen(backPage: true,),
    ),
    Provider<UserRepository>(
      create: (context) => UserRepository(
        NetworkApiService(),           // or however you create it
      ),
    ),

    // 2. Then provide the ViewModel and inject repository using context.read
    ChangeNotifierProvider<UserViewModel>(
      create: (context) => UserViewModel(
        context.read<UserRepository>(),
      ),
      lazy: true, // recommended
    ),





    //////Staff Flow////////

    Provider<StaffRepository>(
      create: (context) => StaffRepository(NetworkApiService()),
    ),

    ChangeNotifierProvider<StaffViewModel>(
      create: (context) => StaffViewModel(context.read<StaffRepository>()),
    ),

  ];
}