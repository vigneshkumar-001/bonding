import 'dart:convert';
import 'dart:io';

import 'package:bonding_app/BondingScreens/AuthService.dart';
import 'package:bonding_app/BondingScreens/SupportScreen/ViewModel/support_ticket_list_vm.dart';
import 'package:bonding_app/BondingScreens/SupportScreen/ViewModel/support_ticket_vm.dart';
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:bonding_app/Bonding_Utils/ColorHandlers/AppColors.dart';
import 'package:bonding_app/StaffScreenScreens/SupportScreen/support_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' as http_parser;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../APIService/Remote/network/ApiEndPoints.dart';
import '../../Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import '../../Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import '../../Reusable_Widgets/BondingNavigator.dart';
import '../../Reusable_Widgets/Common_AppBar/common_app_bar.dart';





import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart' as http_parser;

class CreateSupportScreen extends StatefulWidget {
  final bool isStaff;
  const CreateSupportScreen({super.key, required this.isStaff});

  @override
  State<CreateSupportScreen> createState() => _CreateSupportScreenState();
}

class _CreateSupportScreenState extends State<CreateSupportScreen> {
  TextEditingController subjects = TextEditingController();
  TextEditingController description = TextEditingController();
  final FocusNode _focusNode1 = FocusNode();
  final FocusNode _focusNode2 = FocusNode();
  Color labelColor1 = Colors.white.withOpacity(0.9);
  Color labelColor2 = Colors.white.withOpacity(0.9);
  bool _isUpdating = false;
  File? _selectedImage; // New local image
  String? _currentImageUrl; // Current URL from user profile

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (image.path.endsWith('.png') || image.path.endsWith('.jpg')
      // image.path.endsWith('.jpeg')
      ) {
        setState(() {
          _selectedImage = File(image.path);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Only PNG and JPG formats are supported')),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final token = await AuthService.getToken() ?? "";

      if (token.isEmpty) {
        Utils.snackBarErrorMessage("Authentication token not found");
        return null;
      }

      final uri = Uri.parse('${ApiEndPoints().baseUrl}auth/user/editProfile');

      final request = http.MultipartRequest('POST', uri);

      // Add auth header
      request.headers['Authorization'] = 'Bearer $token';

      // ❌ TEMP DISABLE: file attach to multipart (HIDE form-data)
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      final extension = mimeType.split('/').last;

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: 'profile.$extension',
        contentType: http_parser.MediaType('image', extension),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true && json['data'] != null) {
          final newImageUrl = json['data']['image'] as String?;
          if (newImageUrl != null && newImageUrl.isNotEmpty) {
            return newImageUrl;
          }
        }
      }

      Utils.snackBarErrorMessage(
        "Request failed: ${response.statusCode} - ${response.body}",
      );
      AppLogger.log.e(
        "Request failed: ${response.statusCode} - ${response.body}",
      );
      return null;
    } catch (e) {
      AppLogger.log.e(e);
      Utils.snackBarErrorMessage("Request error: $e");
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (_isUpdating) return; // ✅ prevent double click

    final userVM = context.read<SupportTicketVM>();

    setState(() => _isUpdating = true);

    final success = await userVM.createTicket(
      isStaff: widget.isStaff,
      description: description.text.trim(),
      title: subjects.text.trim(),
      mediaUrls: [],
      message: '',
    );

    if (!mounted) return;
    setState(() => _isUpdating = false);

    if (success) {
      Utils.snackBar("Ticket created successfully");
      bondNavigator.backPage(context);
      context.read<SupportTicketListVM>().fetchTickets(isStaff: widget.isStaff);
    } else {
      Utils.snackBarErrorMessage(
        userVM.errorMessage ?? "Failed to create ticket",
      );
    }
  }

  // Future<void> _updateProfile() async {
  //   final userVM = context.read<SupportTicketVM>();
  //
  //   setState(() => _isUpdating = true);
  //
  //   String? newImageUrl = _currentImageUrl;
  //
  //   // Upload new image if selected
  //   // if (_selectedImage != null) {
  //   //   newImageUrl = await _uploadImage(_selectedImage!);
  //   //   if (newImageUrl == null) {
  //   //     setState(() => _isUpdating = false);
  //   //     return;
  //   //   }
  //   // }
  //
  //   // Call update in ViewModel
  //   final success = await userVM.createTicket(
  //     description: description.text.trim(),
  //     title: subjects.text.trim(),
  //     mediaUrls: [],
  //     message: '',
  //   );
  //
  //   setState(() => _isUpdating = false);
  //
  //   if (success) {
  //     Utils.snackBar("Profile updated successfully");
  //
  //     bondNavigator.backPage(context);
  //     context.read<SupportTicketListVM>().fetchTickets();
  //   } else {
  //     Utils.snackBarErrorMessage("Failed to update profile");
  //   }
  // }

  @override
  void initState() {
    super.initState();
    AppLogger.log.w(widget.isStaff);
    _focusNode1.addListener(() {
      setState(() {
        labelColor1 = _focusNode1.hasFocus
            ? Colors.blue
            : Colors.white.withOpacity(0.9);
      });
    });

    _focusNode2.addListener(() {
      setState(() {
        labelColor2 = _focusNode2.hasFocus
            ? Colors.blue
            : Colors.white.withOpacity(0.9);
      });
    });
  }

  @override
  void dispose() {
    _focusNode1.dispose();
    _focusNode2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF100a0a),
      appBar: CommonAppBar(
        title: 'Raise Ticket',
        usePaddedLeading: true,
        bg: const Color(0xFF100a0a),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 20,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xff141725),

                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Subjects',

                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          style: const TextStyle(color: Colors.white),
                          controller: subjects,
                          focusNode: _focusNode1,
                          decoration: _inputDecoration(),
                        ),
                        const SizedBox(height: 20),

                        AppText(
                          'Description',

                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          style: const TextStyle(color: Colors.white),
                          controller: description,
                          focusNode: _focusNode2,
                          maxLines: 12,
                          decoration: _inputDecoration(),
                        ),
                        const SizedBox(height: 20),
                        /* GestureDetector(
                          onTap: _pickImage,
                          child: DottedBorder(
                            borderType: BorderType.RRect,
                            radius: const Radius.circular(15),
                            dashPattern: const [8, 4],
                            strokeWidth: 1.5,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: _selectedImage == null
                                  ? GestureDetector(
                                      onTap: _pickImage,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.cloud_upload, size: 30),
                                          const SizedBox(width: 10),
                                          Text(
                                            "Upload Screenshot Here",
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: Image.file(
                                            _selectedImage!,
                                            width: 90,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Container(
                                          height: 90,
                                          width: 80,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            child: TextButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red
                                                    .withOpacity(0.1),
                                              ),
                                              onPressed: _removeImage,
                                              child: Text(
                                                "Remove\n  Image",
                                                style: TextStyle(
                                                  color: Colors.red.withOpacity(
                                                    0.6,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),*/
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: _selectedImage == null
                                ? GestureDetector(
                                    onTap: _pickImage,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.cloud_upload,
                                          size: 30,
                                          color: appColors.appPrimaryColorLight,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          "Upload Screenshot Here",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                appColors.appPrimaryColorLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          _selectedImage!,
                                          width: 90,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Container(
                                        height: 90,
                                        width: 80,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          child: TextButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red
                                                  .withOpacity(0.1),
                                            ),
                                            onPressed: _removeImage,
                                            child: Text(
                                              "Remove\n  Image",
                                              style: TextStyle(
                                                color: Colors.red.withOpacity(
                                                  0.6,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _isUpdating
                    ? null
                    : _updateProfile, // ✅ disable while loading
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 15,
                  ),
                  child: Container(
                    height: 60,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: _isUpdating
                            ? [
                                Colors.grey.shade700,
                                Colors.grey.shade600,
                              ] // ✅ muted while loading
                            : const [Color(0xFFB86AF6), Color(0xFFFF6A6A)],
                      ),
                    ),
                    child: Center(
                      child: _isUpdating
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Create Tickets",
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

              // GestureDetector(
              //   onTap: () {
              //     _updateProfile();
              //     // bondNavigator.newPage(context, page: SupportChatScreen());
              //   },
              //   child: Padding(
              //     padding: const EdgeInsets.symmetric(
              //       horizontal: 15,
              //       vertical: 15,
              //     ),
              //     child: Container(
              //       height: 60,
              //       width: double.infinity,
              //       decoration: BoxDecoration(
              //         borderRadius: BorderRadius.circular(8),
              //         gradient: const LinearGradient(
              //           colors: [Color(0xFFB86AF6), Color(0xFFFF6A6A)],
              //         ),
              //       ),
              //       child: Center(
              //         child: const Text(
              //           "Create Tickets",
              //           style: TextStyle(
              //             color: Colors.white,
              //             fontSize: 16,
              //             fontWeight: FontWeight.w600,
              //           ),
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.only(bottom: 2, left: 15, top: 15),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(15),
      ),

      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.4),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }
}
