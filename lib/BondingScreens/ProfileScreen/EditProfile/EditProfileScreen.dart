import 'dart:io';
import 'dart:convert';
import 'package:bonding_app/APIService/Remote/network/ApiEndPoints.dart';
import 'package:bonding_app/BondingScreens/AuthService.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/Model/UserDataModel.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/Reusable_Widgets/Common_AppBar/common_app_bar.dart';
import 'package:bonding_app/theme/brand_theme.dart';
import 'package:bonding_app/ui/app_loader.dart';
import 'package:bonding_app/ui/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart' as http_parser;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  File? _selectedImage; // New local image
  String? _currentImageUrl; // Current URL from user profile

  String? _selectedLanguage; // Selected language

  final List<String> languages = [
    "English",
    "Hindi",
    "Tamil",
    "Telugu",
    "Kannada",
    "Malayalam",
    "Marathi",
    "Bengali",
    "Gujarati",
    "Punjabi",
  ];

  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userVM = context.read<UserViewModel>();
      userVM.fetchUserDetails(); // Ensure latest data

      final user = userVM.currentUser;
      if (user != null) {
        _nameController.text = user.name ?? '';
        _bioController.text = user.bio ?? '';
        _currentImageUrl = user.image;
        _selectedLanguage =
            user.language ?? "English"; // Default to English if null
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Upload image with auth token (TEMP: form-data/file attach hidden)
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

      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      final extension = mimeType.split('/').last;

      final filePart = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: 'profile.$extension',
        contentType: http_parser.MediaType('image', extension),
      );
      request.files.add(filePart);

      // âœ… ONE PRINT: what is being sent
      if (kDebugMode) print(
          'SENDING -> URL: ${request.url}\n'
              'HEADERS: ${{
            ...request.headers,
            // donâ€™t leak full token in logs
            if (request.headers.containsKey("Authorization")) "Authorization": "Bearer ***",
          }}\n'
              'FIELDS: ${request.fields}\n'
              'FILES: ${request.files.map((f) => {
            "field": f.field,
            "filename": f.filename,
            "length": f.length,
            "contentType": f.contentType?.toString(),
          }).toList()}\n'
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // âœ… ONE PRINT: response
      if (kDebugMode) print(
          'RESPONSE <- ${response.statusCode}\n'
              'BODY: ${response.body}\n'
      );

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
      return null;
    } catch (e) {
      Utils.snackBarErrorMessage("Request error: $e");
      return null;
    }
  }
/*  Future<String?> _uploadImage(File imageFile) async {
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

      // âŒ TEMP DISABLE: file attach to multipart (HIDE form-data)
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
      return null;
    } catch (e) {
      Utils.snackBarErrorMessage("Request error: $e");
      return null;
    }
  }*/
   Future<void> _updateProfile() async {
    final userVM = context.read<UserViewModel>();
    final user = userVM.currentUser;

    if (user == null) {
      Utils.snackBarErrorMessage("No user data found");
      return;
    }

    setState(() => _isUpdating = true);

    String? newImageUrl = _currentImageUrl;

    // Upload new image if selected
    if (_selectedImage != null) {
      newImageUrl = await _uploadImage(_selectedImage!);
      if (newImageUrl == null) {
        setState(() => _isUpdating = false);
        return;
      }
    }

    // Call update in ViewModel
    final success = await userVM.updateUserProfile(
      name: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      language: _selectedLanguage,
      image: newImageUrl,
    );

    setState(() => _isUpdating = false);

    if (success) {
      Utils.snackBar("Profile updated successfully");
      bondNavigator.backPage(context);
    } else {
      Utils.snackBarErrorMessage("Failed to update profile");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserViewModel>(
      builder: (context, userVM, child) {
        final user = userVM.currentUser;

        if (userVM.isLoading || user == null) {
          return const AppScaffold(body: AppLoader.center());
        }

        final cs = Theme.of(context).colorScheme;
        final brand = BrandTheme.of(context);

        return AppScaffold(
          appBar: const CommonAppBar(
            title: "Edit profile",
            usePaddedLeading: true,
            bg: Colors.transparent,
          ),
          body: SingleChildScrollView(
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Avatar Selection (kept same as previous UI - single image)
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: cs.primary,
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child: _selectedImage != null
                                ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                : (user.image != null && user.image!.isNotEmpty
                                      ? Image.network(
                                          user.image!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Image.asset(
                                                "assets/Images/profileimg.png",
                                                fit: BoxFit.cover,
                                              ),
                                        )
                                      : Image.asset(
                                          "assets/Images/profileimg.png",
                                          fit: BoxFit.cover,
                                        )),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Text(
                          "+ add image",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Name Field (same as before)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Name:",
                            style: TextStyle(color: cs.onSurface, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            style: TextStyle(color: cs.onSurface),
                            decoration: InputDecoration(
                              hintText: "Enter the name",
                              hintStyle: TextStyle(color: cs.onSurfaceVariant),
                              filled: true,
                              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppText(
                            "• can change username 2 more time\n• Username must be 4-10 characters",
                            color: cs.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Bio Field (same as before)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bio:",
                            style: TextStyle(color: cs.onSurface, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _bioController,
                            maxLines: 4,
                            maxLength: 200,
                            style: TextStyle(color: cs.onSurface),
                            decoration: InputDecoration(
                              hintText: "Text here",
                              hintStyle: TextStyle(color: cs.onSurfaceVariant),
                              filled: true,
                              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              counterStyle: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Language Selection (Dropdown - replaced category)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Preferred Language:",
                            style: TextStyle(color: cs.onSurface, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(alpha: 0.45),
                                width: 0.8,
                              ),
                            ),
                            child: DropdownButton<String>(
                              value:
                                  _selectedLanguage ??
                                  user.language ??
                                  "English",
                              isExpanded: true,
                              underline: const SizedBox(),
                              dropdownColor: cs.surface,
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: cs.onSurfaceVariant,
                              ),
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 16,
                              ),
                              items: languages.map((String lang) {
                                return DropdownMenuItem<String>(
                                  value: lang,
                                  child: Text(lang),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedLanguage = newValue;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Gender (static display - same as before)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Gender:",
                            style: TextStyle(color: cs.onSurface, fontSize: 16),
                          ),
                          Text(
                            user.gender ?? "Not specified",
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: userVM.isLoading || _isUpdating ? null : _updateProfile,
                child: Container(
                  height: 45,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: brand.primaryGradient,
                  ),
                  alignment: Alignment.center,
                  child: _isUpdating || userVM.isLoading
                      ? const AppLoader(radius: 10, color: Colors.white)
                      : const Text(
                          "Update",
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
      },
    );
  }
}

