import 'package:bonding_app/BondingScreens/SupportScreen/ViewModel/support_ticket_list_vm.dart';
import 'package:bonding_app/BondingScreens/SupportScreen/create_support_screen.dart';
import 'package:bonding_app/BondingScreens/SupportScreen/support_chat_screen.dart';
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:bonding_app/Bonding_Utils/ColorHandlers/Apptheme.dart';

import 'package:flutter/material.dart';
import 'package:bonding_app/Reusable_Widgets/Loading/app_loading_indicator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import '../../Reusable_Widgets/BondingNavigator.dart';
import '../../Reusable_Widgets/Common_AppBar/common_app_bar.dart';

class SupportScreens extends StatefulWidget {
  final bool isStaff;
  const SupportScreens({super.key, required this.isStaff});

  @override
  State<SupportScreens> createState() => _SupportScreensState();
}

class _SupportScreensState extends State<SupportScreens> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.log.w(widget.isStaff);
      context.read<SupportTicketListVM>().fetchTickets(isStaff: widget.isStaff);
    });
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return "-";
    return DateFormat("dd MMM, yyyy • hh:mm a").format(dt.toLocal());
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "open":
      case "opened":
        return const Color(0xff3F5FF2);
      case "solved":
      case "closed":
        return const Color(0xff3ECD8B);
      case "pending":
        return const Color(0xFFFFC107);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const CommonAppBar(
        title: 'Support',
        usePaddedLeading: true,
        bg: Colors.transparent,
      ),
      body: SafeArea(
        child: Consumer<SupportTicketListVM>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(
                child: const AppLoadingIndicator(color: Colors.white),
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
                        "Failed to load tickets",
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        vm.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          vm.fetchTickets(isStaff: widget.isStaff); // or false
                        },
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (vm.tickets.isEmpty) {
              return Center(
                child: Text(
                  "No tickets found",
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
              );
            }

            return RefreshIndicator(
              color: Colors.white,
              backgroundColor: Apptheme.surface,
              onRefresh: vm.refresh,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 20,
                ),
                itemCount: vm.tickets.length,
                itemBuilder: (context, index) {
                  final ticket = vm.tickets[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: GestureDetector(
                      onTap: () {
                        bondNavigator.newPage(
                          context,
                          page: SupportChatScreen(
                            ticketId: ticket.id,
                            subjects: ticket.title,
                            isStaff: widget.isStaff,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(0xff3F5FF2).withOpacity(0.08),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Status box
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: _statusColor(
                                  ticket.status,
                                ).withOpacity(0.12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.support_agent,
                                    color: _statusColor(ticket.status),
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    ticket.status,
                                    style: TextStyle(
                                      color: _statusColor(ticket.status),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Ticket info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    ticket.title,
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 6),
                                  AppText(
                                    ticket.description,
                                    color: const Color(0XFFc7c7cc),
                                    fontSize: 14,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatDate(ticket.createdAt),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.55),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: GestureDetector(
        onTap: () {
          bondNavigator.newPage(
            context,
            page: CreateSupportScreen(isStaff: widget.isStaff),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Color(0xFF7A5CFF), Color(0xFFFF5CA8)],
              ),
            ),
            child: const Center(
              child: Text(
                "Raise Tickets",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// import 'package:bonding_app/Bonding_Utils/AppImage/app_images.dart';
// import 'package:bonding_app/Reusable_Widgets/ReuseElevateButton/ReuseElevateButton.dart';
// import 'package:bonding_app/StaffScreenScreens/SupportScreen/create_support_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
//
// import '../../Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
// import '../../Reusable_Widgets/BondingNavigator.dart';
// import '../../Reusable_Widgets/Common_AppBar/common_app_bar.dart';
//
// class SupportScreens extends StatefulWidget {
//   const SupportScreens({super.key});
//
//   @override
//   State<SupportScreens> createState() => _SupportScreensState();
// }
//
// class _SupportScreensState extends State<SupportScreens> {
//   void apiCall() async {
//
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     apiCall();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF100a0a),
//       appBar: CommonAppBar(
//         title: 'Support',
//         usePaddedLeading: true,
//         bg: const Color(0xFF100a0a),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           physics: const BouncingScrollPhysics(),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 20),
//             child: Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 25,
//                     vertical: 10,
//                   ),
//                   child: Column(
//                     spacing: 15,
//                     children: [
//                       ListView.builder(
//                         physics: NeverScrollableScrollPhysics(),
//                         shrinkWrap: true,
//
//                         itemCount: 15,
//                         itemBuilder: (context, index) {
//                           return Padding(
//                             padding: const EdgeInsets.only(bottom: 20.0),
//                             child: Container(
//                               padding: EdgeInsets.symmetric(
//                                 horizontal: 10,
//                                 vertical: 10,
//                               ),
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(10),
//                                 color: Color(0xf3F5FF2).withOpacity(0.1),
//                               ),
//                               child: Row(
//                                 children: [
//                                   // Profile Picture
//                                   // CircleAvatar(
//                                   //   radius: 28,
//                                   //   backgroundImage: AssetImage(user['image']),
//                                   // ),
//                                   Container(
//                                     padding: EdgeInsets.symmetric(
//                                       horizontal: 10,
//                                       vertical: 10,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       borderRadius: BorderRadius.circular(10),
//                                       color: Color(0xf3F5FF2).withOpacity(0.11),
//                                     ),
//
//                                     child: Column(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.center,
//                                       children: [
//                                         Image.asset(
//                                           AppImage.tick,
//                                           height: 40,
//                                           fit: BoxFit.cover,
//                                         ),
//                                         const SizedBox(height: 5),
//                                         Text(
//                                           'solved',
//                                           style: TextStyle(
//                                             color: Color(0xff3F5FF2),
//                                             // ticket.status.toLowerCase() ==
//                                             //     "pending"
//                                             // ? Color(0xff3F5FF2)
//                                             // : ticket.status.toLowerCase() ==
//                                             //       "solved"
//                                             // ? Color(0xff3ECD8B)
//                                             // : 'opened' ==
//                                             //       "opened"
//                                             // ? Color(0xff3F5FF2)
//                                             // : Colors.grey,
//                                             fontSize: 11,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   const SizedBox(width: 20),
//
//                                   // User Info
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         AppText(
//                                           'username',
//
//                                           color: Colors.white,
//                                           fontSize: 17,
//                                           fontWeight: FontWeight.w600,
//                                         ),
//                                         const SizedBox(height: 4),
//                                         AppText(
//                                           "Blocked: {user['blockedDate']}",
//
//                                           color: Color(0XFFc7c7cc),
//                                           fontSize: 15,
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//       bottomNavigationBar: GestureDetector(
//         onTap: () {
//           bondNavigator.newPage(context, page: const CreateSupportScreen());
//         },
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
//           child: Container(
//             height: 60,
//             width: double.infinity,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8),
//               gradient: const LinearGradient(
//                 colors: [Color(0xFF7A5CFF), Color(0xFFFF5CA8)],
//               ),
//             ),
//             child: Center(
//               child: const Text(
//                 "Raise Tickets",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
