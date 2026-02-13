import 'dart:io';

import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:bonding_app/StaffScreenScreens/VerificationApprovedScreen/VerificationApprovedScreen.dart';
import 'package:bonding_app/StaffScreenScreens/VerificationInprogressScreen/VerificationInprogressScreen.dart';
import 'package:bonding_app/StaffScreenScreens/VerificationUnsuccessfulScreen/VerificationUnsuccessScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class LiveVerificationScreen extends StatefulWidget {
  const LiveVerificationScreen({super.key});

  @override
  State<LiveVerificationScreen> createState() => _LiveVerificationScreenState();
}

class _LiveVerificationScreenState extends State<LiveVerificationScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool _isPickingImage = false;

  /// Request camera & gallery permissions
  Future<bool> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final photosStatus = await Permission.photos.request();

    if (cameraStatus.isDenied || photosStatus.isDenied) {
      Utils.snackBarErrorMessage("Camera and photo permissions are required");
      return false;
    }

    if (cameraStatus.isPermanentlyDenied || photosStatus.isPermanentlyDenied) {
      Utils.snackBarErrorMessage("Please enable permissions in settings");
      openAppSettings();
      return false;
    }

    return true;
  }

  /// Take live selfie (camera)
  Future<void> _takeSelfie() async {
    if (_isPickingImage) return;

    if (!await _requestPermissions()) return;

    setState(() => _isPickingImage = true);

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 70,
      );

      if (photo != null && mounted) {
        setState(() {
          _selectedImage = File(photo.path);
        });
      }
    } catch (e) {
      Utils.snackBarErrorMessage("Failed to open camera: $e");
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  /// Pick image from gallery
  Future<void> _pickFromGallery() async {
    if (_isPickingImage) return;

    if (!await _requestPermissions()) return;

    setState(() => _isPickingImage = true);

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (photo != null && mounted) {
        setState(() {
          _selectedImage = File(photo.path);
        });
      }
    } catch (e) {
      Utils.snackBarErrorMessage("Failed to pick image: $e");
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  @override
  void initState() {
    super.initState();

    // Force fresh fetch when entering this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffViewModel>().fetchStaffSingleData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LoginViewModel, StaffViewModel>(
      builder: (context, vm, staffVM, child) {
        final staff = staffVM.currentStaff;

        if (staff == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF140810),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text("Loading profile...", style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          );
        }

        final isApproved = staff.isApproved?.toString() ?? '0';

        print("????????? isApproved: $isApproved (raw: ${staff.isApproved})");

        return Scaffold(
          backgroundColor: const Color(0xFF140810),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFF5A1F3F),
                  Color(0xFF3A152A),
                  Color(0xFF140810),
                  Color(0xFF140810),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    SvgPicture.asset("assets/Images/bonding.svg", height: 35),
                    const SizedBox(height: 30),

                    Center(
                      child: AppText(
                        "Profile Verification Screen",
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Center(
                      child: AppText(
                        "Complete verification to activate your account.",
                        fontSize: 15,
                        color: const Color(0xFFc7c7cc),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Image Preview Area
                    Center(
                      child: GestureDetector(
                        onTap: vm.isUploading ? null : _takeSelfie,
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 2),
                            color: const Color(0xFF5b2749),
                            image: _selectedImage != null
                                ? DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                          child: _selectedImage == null
                              ? Center(
                            child: SvgPicture.asset(
                              "assets/Images/camera.svg",
                              width: 80,
                              height: 80,
                            ),
                          )
                              : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons: Camera + Gallery
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildImageOption(
                          icon: Icons.camera_alt,
                          label: "Take Selfie",
                          onTap: vm.isUploading ? null : _takeSelfie,
                        ),
                        const SizedBox(width: 40),
                        _buildImageOption(
                          icon: Icons.photo_library,
                          label: "From Gallery",
                          onTap: vm.isUploading ? null : _pickFromGallery,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    Center(
                      child: AppText(
                        "Upload a clear live selfie or photo to confirm your identity.",
                        color: const Color(0xFFc7c7cc),
                        fontSize: 16,
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),

          // Upload Button
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: vm.isUploading || _selectedImage == null
                    ? null
                    : () async {
                  final success = await vm.uploadSelfie(_selectedImage!);

                  if (success) {
                    final nextScreen = isApproved == "1"
                        ? const ApprovedScreen()
                        : isApproved == "2"
                        ? const VerificationUnsuccessScreen()
                        : const VerificationInprogressScreen();

                    bondNavigator.newPageRemoveUntil(context, page: nextScreen);
                  } else {
                    Utils.snackBarErrorMessage("Failed to upload photo");
                  }
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: vm.isUploading || _selectedImage == null
                        ? const LinearGradient(colors: [Colors.grey, Colors.blueGrey])
                        : const LinearGradient(colors: [Color(0xFFB86AF6), Color(0xFFFF6A6A)]),
                  ),
                  child: Center(
                    child: vm.isUploading
                        ? const SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                        : Text(
                      _selectedImage == null ? "Select Image First" : "Upload & Verify  →",
                      style: TextStyle(
                        color: _selectedImage == null ? Colors.white60 : Colors.white,
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

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF5b2749),
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}