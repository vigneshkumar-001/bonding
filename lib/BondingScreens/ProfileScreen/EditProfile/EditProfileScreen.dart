import 'dart:io';
import 'dart:convert';
import 'package:bonding_app/APIService/Remote/network/ApiEndPoints.dart';
import 'package:bonding_app/BondingScreens/AuthService.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/Model/UserDataModel.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';
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
        _selectedLanguage = user.language ?? "English"; // Default to English if null
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

  // Upload image with auth token
  Future<String?> _uploadImage(File imageFile) async {
    try {
      final token = await AuthService.getToken() ?? "";

      if (token.isEmpty) {
        Utils.snackBarErrorMessage("Authentication token not found");
        return null;
      }

      final uri = Uri.parse('${ApiEndPoints().baseUrl}auth/user/editProfile');

      var request = http.MultipartRequest('POST', uri);

      // Add auth header
      request.headers['Authorization'] = 'Bearer $token';

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

      Utils.snackBarErrorMessage("Image upload failed: ${response.statusCode} - ${response.body}");
      return null;
    } catch (e) {
      Utils.snackBarErrorMessage("Image upload error: $e");
      print("Upload error: $e");
      return null;
    }
  }

  // Update full profile
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
          return const Scaffold(
            backgroundColor: Color(0xFF100a0a),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF100a0a),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF100a0a),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => bondNavigator.backPage(context),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF282323),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.arrow_back, color: Colors.white),
                              ),
                            ),
                          ),
                          AppText(
                            "edit profile",
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          SizedBox()
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

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
                            border: Border.all(color: const Color(0xFFcc529f), width: 3),
                          ),
                          child: ClipOval(
                            child: _selectedImage != null
                                ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                : (user.image != null && user.image!.isNotEmpty
                                ? Image.network(
                              user.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset("assets/Images/profileimg.png", fit: BoxFit.cover),
                            )
                                : Image.asset("assets/Images/profileimg.png", fit: BoxFit.cover)),
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
                          const Text(
                            "Name:",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white70),
                            decoration: InputDecoration(
                              hintText: "Enter the name",
                              hintStyle: TextStyle(color: Color(0XFFb6b6ba)),
                              filled: true,
                              fillColor: const Color(0xFF35272d).withOpacity(0.6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppText(
                            "• can change username 2 more time\n• Username must be 4-10 characters",
                            color: Color(0XFFb6b6ba),
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
                          const Text(
                            "Bio:",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _bioController,
                            maxLines: 4,
                            maxLength: 200,
                            style: const TextStyle(color: Colors.white70),
                            decoration: InputDecoration(
                              hintText: "Text here",
                              hintStyle: TextStyle(color: Color(0XFFb6b6ba)),
                              filled: true,
                              fillColor: const Color(0xFF35272d).withOpacity(0.6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              counterStyle: const TextStyle(color: Colors.grey),
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
                          const Text(
                            "Preferred Language:",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF35272d).withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedLanguage ?? user.language ?? "English",
                              isExpanded: true,
                              underline: const SizedBox(),
                              dropdownColor: const Color(0xFF35272d),
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
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
                          const Text(
                            "Gender:",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          Text(
                            user.gender ?? "Not specified",
                            style: const TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: Container(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: userVM.isLoading || _isUpdating ? null : _updateProfile,
                  child: Container(
                    height: 45,
                    width: MediaQuery.of(context).size.width * 0.55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8d51d2), Color(0xFFf8655f)],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: _isUpdating || userVM.isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
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
          ),
        );
      },
    );
  }
}