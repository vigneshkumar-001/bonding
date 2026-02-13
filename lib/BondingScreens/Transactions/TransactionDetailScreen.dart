import 'dart:ui';
import 'package:bonding_app/BondingScreens/Transactions/Model/TransactionHistoryModel.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // for nice date formatting

class TransactionDetailsScreen extends StatelessWidget {
  final DepositHistoryItem transaction;

  const TransactionDetailsScreen({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = transaction.paymentStatus.toLowerCase() == 'paid';
    final isPending = transaction.paymentStatus.toLowerCase() == 'created';
    final formattedDate = DateFormat('dd MMM yyyy, h:mm a').format(transaction.createdAt);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF100a0a),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(

                    children: [
                      GestureDetector(
                        onTap: () => bondNavigator.backPage(context),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      ),
                      SizedBox(width: 100,),
                      AppText(
                        "Transaction Details",
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),

                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // User Profile Section (dynamic)
                Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: transaction.image != null && transaction.image!.isNotEmpty
                          ? NetworkImage(transaction.image!)
                          : const AssetImage("assets/Images/pooja.png") as ImageProvider,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      transaction.userName.isNotEmpty ? transaction.userName : "User",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "ID: ${transaction.razorpayOrderId.substring(0, 10)}...",
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Amount (dynamic)
                Text(
                  "₹${transaction.totalAmount}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                // Status (dynamic)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: transaction.statusColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : isPending ? Icons.hourglass_empty : Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppText(
                      transaction.statusText,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: transaction.statusColor,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Date & Time (dynamic)
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 40),

                // Transaction Details Card (dynamic)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF35272d).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Payment Gateway / Bank Info
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(Icons.payment, color: Colors.black, size: 32), // Razorpay icon or bank
                              ),
                            ),
                            const SizedBox(width: 12),
                            AppText(
                              "Razorpay Payment",
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Colors.grey, thickness: 0.2),
                        ),

                        // Dynamic Details
                        _buildDetailRow("Transaction ID:", transaction.razorpayOrderId),
                        const SizedBox(height: 16),
                        _buildDetailRow("Payment ID:", transaction.razorpayPaymentId ?? "N/A"),
                        const SizedBox(height: 16),
                        _buildDetailRow("Amount:", "₹${transaction.totalAmount} ${transaction.currency}"),
                        const SizedBox(height: 16),
                        _buildDetailRow("User:", "${transaction.userName} (${transaction.userPhone})"),
                        if (transaction.razorpaySignature != null) ...[
                          const SizedBox(height: 16),
                          _buildDetailRow("Signature:", transaction.razorpaySignature!.substring(0, 20) + "..."),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}