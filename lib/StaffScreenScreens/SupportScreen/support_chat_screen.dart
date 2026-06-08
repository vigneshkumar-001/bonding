// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
//
// import '../../Reusable_Widgets/Common_AppBar/common_app_bar.dart';
//
// /// Simple message model (replace with your API model if you have one)
// class SupportChatMessage {
//   final String? message;
//   final String? files; // can be http url OR local file path
//   final DateTime time;
//   final bool myMessage;
//
//   SupportChatMessage({
//     this.message,
//     this.files,
//     required this.time,
//     required this.myMessage,
//   });
// }
//
// class SupportChatScreen extends StatefulWidget {
//   final String? ticketId;
//   final String? subjects;
//   final String? date;
//
//   const SupportChatScreen({super.key, this.ticketId, this.subjects, this.date});
//
//   @override
//   State<SupportChatScreen> createState() => _SupportChatScreenState();
// }
//
// class _SupportChatScreenState extends State<SupportChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final ImagePicker _picker = ImagePicker();
//
//   bool _isLoading = false;
//   File? _selectedImage;
//
//   final List<SupportChatMessage> _messages = [];
//
//   // ✅ Color Combination (Option 1: matches your app)
//   static const Color _bg = Color(0xFF100A0A); // scaffold background
//   static const Color _panel = Color(0xFF1A1214); // header + composer panel
//   static const Color _incoming = Color(0xFF23171B); // support bubble
//   static const Color _outgoing = Color(0xFF2A1F2E); // your bubble (purple tint)
//   static const Color _hint = Color(0xFF919199);
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) => _fetchChatMessages());
//   }
//
//   @override
//   void dispose() {
//     _messageController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _pickImage() async {
//     final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//     if (!mounted) return;
//
//     if (image != null) {
//       final path = image.path.toLowerCase();
//       final ok =
//           path.endsWith('.png') ||
//           path.endsWith('.jpg') ||
//           path.endsWith('.jpeg');
//
//       if (!ok) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Only PNG, JPG, JPEG formats are supported'),
//           ),
//         );
//         return;
//       }
//
//       setState(() {
//         _selectedImage = File(image.path);
//       });
//     }
//   }
//
//   Future<void> _fetchChatMessages() async {
//     setState(() => _isLoading = true);
//
//     try {
//       // TODO: call your API here using widget.ticketId
//       // Demo messages
//       _messages
//         ..clear()
//         ..addAll([
//           SupportChatMessage(
//             message: "Hi, how can we help you?",
//             time: DateTime.now().subtract(const Duration(minutes: 10)),
//             myMessage: false,
//           ),
//           SupportChatMessage(
//             message: "My issue is...",
//             time: DateTime.now().subtract(const Duration(minutes: 8)),
//             myMessage: true,
//           ),
//         ]);
//     } catch (_) {
//       // optional snackbar
//     } finally {
//       if (!mounted) return;
//       setState(() => _isLoading = false);
//     }
//   }
//
//   Future<void> _sendMessage() async {
//     final text = _messageController.text.trim();
//     final img = _selectedImage;
//
//     if (text.isEmpty && img == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Type a message or upload an image")),
//       );
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     try {
//       // TODO: Call your send-message API with widget.ticketId, text, img (multipart)
//       // After success:
//       setState(() {
//         _messages.insert(
//           0,
//           SupportChatMessage(
//             message: text.isEmpty ? null : text,
//             files: img?.path,
//             time: DateTime.now(),
//             myMessage: true,
//           ),
//         );
//         _messageController.clear();
//         _selectedImage = null;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Failed to send message: $e")));
//     } finally {
//       if (!mounted) return;
//       setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: _bg,
//       appBar: CommonAppBar(
//         title: 'Chat With Support',
//         usePaddedLeading: true,
//         bg: _bg,
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Ticket header
//             Padding(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 20.0,
//                 vertical: 15,
//               ),
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: _panel,
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(color: Colors.white.withOpacity(0.06)),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.only(
//                     right: 15,
//                     top: 15,
//                     bottom: 15,
//                     left: 15,
//                   ),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               widget.subjects ?? "",
//                               style: const TextStyle(
//                                 fontFamily: 'Mulish',
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.white,
//                               ),
//                             ),
//                             const SizedBox(height: 10),
//                             Text(
//                               "Created on ${widget.date ?? ""}",
//                               style: const TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.white54,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(width: 15),
//                       InkWell(
//                         onTap: () {
//                           // TODO: close ticket API
//                         },
//                         borderRadius: BorderRadius.circular(12),
//                         child: Container(
//                           height: 75,
//                           width: 58,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(12),
//                             color: Colors.red.withOpacity(0.12),
//                             border: Border.all(
//                               color: Colors.red.withOpacity(0.25),
//                             ),
//                           ),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 Icons.close_rounded,
//                                 color: Colors.red.withOpacity(0.75),
//                               ),
//                               const SizedBox(height: 5),
//                               Text(
//                                 "Close\nTicket",
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   fontSize: 10,
//                                   color: Colors.red.withOpacity(0.75),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//
//             // Messages
//             Expanded(
//               child: _isLoading && _messages.isEmpty
//                   ? const Center(child: CircularProgressIndicator())
//                   : ListView.builder(
//                       reverse: true,
//                       padding: const EdgeInsets.only(bottom: 6),
//                       itemCount: _messages.length,
//                       itemBuilder: (context, index) {
//                         final message = _messages[index];
//                         final isUser = message.myMessage;
//
//                         final bubbleColor = isUser ? _outgoing : _incoming;
//
//                         return Align(
//                           alignment: isUser
//                               ? Alignment.centerRight
//                               : Alignment.centerLeft,
//                           child: Container(
//                             padding: const EdgeInsets.all(12),
//                             margin: const EdgeInsets.symmetric(
//                               vertical: 4,
//                               horizontal: 12,
//                             ),
//                             constraints: BoxConstraints(
//                               maxWidth:
//                                   MediaQuery.of(context).size.width * 0.78,
//                             ),
//                             decoration: BoxDecoration(
//                               color: bubbleColor,
//                               borderRadius: BorderRadius.only(
//                                 topLeft: const Radius.circular(15),
//                                 topRight: const Radius.circular(15),
//                                 bottomLeft: isUser
//                                     ? const Radius.circular(15)
//                                     : Radius.zero,
//                                 bottomRight: isUser
//                                     ? Radius.zero
//                                     : const Radius.circular(15),
//                               ),
//                               border: Border.all(
//                                 color: Colors.white.withOpacity(0.06),
//                               ),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 if (message.message != null &&
//                                     message.message!.isNotEmpty)
//                                   Text(
//                                     message.message!,
//                                     style: const TextStyle(
//                                       fontSize: 15,
//                                       color: Colors.white,
//                                       height: 1.25,
//                                     ),
//                                   ),
//
//                                 if (message.files != null &&
//                                     message.files!.isNotEmpty) ...[
//                                   const SizedBox(height: 8),
//                                   _buildImage(message.files!),
//                                 ],
//
//                                 const SizedBox(height: 6),
//                                 Text(
//                                   DateFormat('hh:mm a').format(message.time),
//                                   style: const TextStyle(
//                                     fontSize: 11,
//                                     color: Colors.white54,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//             ),
//
//             // Composer
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 10,
//                 ),
//                 decoration: BoxDecoration(
//                   color: _panel,
//                   borderRadius: BorderRadius.circular(24),
//                   border: Border.all(color: Colors.white.withOpacity(0.06)),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     if (_selectedImage != null)
//                       Padding(
//                         padding: const EdgeInsets.only(bottom: 10),
//                         child: Stack(
//                           children: [
//                             ClipRRect(
//                               borderRadius: BorderRadius.circular(10),
//                               child: Image.file(
//                                 _selectedImage!,
//                                 height: 110,
//                                 width: 110,
//                                 fit: BoxFit.cover,
//                               ),
//                             ),
//                             Positioned(
//                               top: 6,
//                               right: 6,
//                               child: InkWell(
//                                 onTap: () =>
//                                     setState(() => _selectedImage = null),
//                                 child: Container(
//                                   padding: const EdgeInsets.all(4),
//                                   decoration: BoxDecoration(
//                                     color: Colors.black.withOpacity(0.55),
//                                     shape: BoxShape.circle,
//                                   ),
//                                   child: const Icon(
//                                     Icons.close,
//                                     color: Colors.white,
//                                     size: 16,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextField(
//                             maxLines: null,
//                             controller: _messageController,
//                             style: const TextStyle(color: Colors.white),
//                             cursorColor: Colors.white,
//                             decoration: const InputDecoration(
//                               border: InputBorder.none,
//                               contentPadding: EdgeInsets.symmetric(
//                                 horizontal: 14,
//                               ),
//                               hintText: 'Say hii!',
//                               hintStyle: TextStyle(color: _hint),
//                             ),
//                           ),
//                         ),
//                         IconButton(
//                           onPressed: _pickImage,
//                           icon: Icon(
//                             Icons.cloud_upload,
//                             size: 26,
//                             color: Colors.white.withOpacity(0.75),
//                           ),
//                         ),
//                         const SizedBox(width: 4),
//                         Container(
//                           height: 42,
//                           width: 42,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(30),
//                             gradient: const LinearGradient(
//                               colors: [Color(0xFF7A5CFF), Color(0xFFFF5CA8)],
//                             ),
//                           ),
//                           child: IconButton(
//                             icon: const Icon(
//                               Icons.send,
//                               color: Colors.white,
//                               size: 20,
//                             ),
//                             onPressed: _isLoading ? null : _sendMessage,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildImage(String pathOrUrl) {
//     final isUrl = pathOrUrl.startsWith('http');
//
//     if (isUrl) {
//       return ClipRRect(
//         borderRadius: BorderRadius.circular(10),
//         child: Image.network(
//           pathOrUrl,
//           height: 160,
//           width: 160,
//           fit: BoxFit.cover,
//           errorBuilder: (_, __, ___) =>
//               const Icon(Icons.broken_image, color: Colors.white54),
//         ),
//       );
//     }
//
//     final file = File(pathOrUrl);
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(10),
//       child: Image.file(
//         file,
//         height: 160,
//         width: 160,
//         fit: BoxFit.cover,
//         errorBuilder: (_, __, ___) =>
//             const Icon(Icons.broken_image, color: Colors.white54),
//       ),
//     );
//   }
// }
