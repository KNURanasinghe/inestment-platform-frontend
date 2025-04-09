import 'package:flutter/material.dart';
import 'package:investment_plan_app/screens/home_screen.dart';
import 'package:investment_plan_app/services/user_service.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart' as path;

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  File? _file;
  String? _fileType;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  UserApiService? _userApiService;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadUserId();
  }

  Future<void> _initializeService() async {
    _userApiService = UserApiService(
        baseUrl:
            'http://145.223.21.62:5021'); // Replace with your actual base URL
  }

  Future<void> _loadUserId() async {
    final userId = await UserApiService.getUserId();
    setState(() {
      _userId = userId;
    });
  }

  // Add custom SnackBar method
  void _showCustomSnackBar(
      BuildContext context, String message, bool isSuccess) {
    // Get the ScaffoldMessengerState
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Clear any existing SnackBars
    scaffoldMessenger.clearSnackBars();

    // Show the SnackBar with the gradient wrapper
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSuccess
                  ? [
                      const Color(0xFF4776E6),
                      const Color(0xFF8E54E9)
                    ] // Success gradient - blue to purple
                  : [
                      const Color(0xFFFF416C),
                      const Color(0xFFFF4B2B)
                    ], // Error gradient - red to orange
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error_outline,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 3),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        final fileExt = path.extension(pickedFile.path).toLowerCase();
        setState(() {
          _file = File(pickedFile.path);
          _fileType = fileExt == '.png' ? 'PNG Image' : 'JPEG Image';
        });
        _showCustomSnackBar(context, "Image selected successfully", true);
      }
    } catch (e) {
      print('Error picking image: $e');
      _showCustomSnackBar(
          context, "Error selecting image: ${e.toString()}", false);
    }
  }

  Future<void> _pickPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          _file = File(result.files.single.path!);
          _fileType = 'PDF Document';
        });
        _showCustomSnackBar(
            context, "PDF document selected successfully", true);
      }
    } catch (e) {
      print('Error picking PDF: $e');
      _showCustomSnackBar(
          context, "Error selecting PDF: ${e.toString()}", false);
    }
  }

  Future<void> _uploadFile() async {
    if (_file == null) {
      _showCustomSnackBar(
          context, "Please select a payment proof file first", false);
      return;
    }

    if (_userId == null) {
      _showCustomSnackBar(
          context, "User not logged in. Please login first", false);
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushNamed(context, '/login');
      });
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final result =
          await _userApiService!.uploadPaymentImage(_userId!, _file!);

      if (result['success'] == true) {
        _showCustomSnackBar(
            context, "Payment proof uploaded successfully!", true);

        final isPayed = await _userApiService!.getPaymentStatus(_userId!);
        print('isPayed $isPayed');

        if (isPayed == false) {
          //TODO : need here true
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const HomeScreen()));
          });
        }
      } else {
        _showCustomSnackBar(context,
            result['message'] ?? "Failed to upload payment proof", false);
      }
    } catch (e) {
      _showCustomSnackBar(
          context, "Error uploading payment proof: ${e.toString()}", false);
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showFileSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.backgroundColor,
          title: Text('Select File Source', style: AppTheme.textStyleBold),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: Text('Gallery', style: AppTheme.textStyleRegular),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: Text('Camera', style: AppTheme.textStyleRegular),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.white),
                title: Text('PDF Document', style: AppTheme.textStyleRegular),
                onTap: () {
                  Navigator.pop(context);
                  _pickPDF();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTheme.textStyleBold
                  .copyWith(fontSize: 14, color: Colors.white70)),
          Text(value,
              style: AppTheme.textStyleRegular
                  .copyWith(fontSize: 14, color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          AppTheme.appBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: height * 0.1),
                  const Text(
                    'Welcome to Investment Platform',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3),

                  const SizedBox(height: 16),

                  const Text(
                    'Start your investment journey with a minimum deposit of 5000 rupees',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms)
                      .slideY(begin: -0.2),

                  const SizedBox(height: 20),

                  // Admin Account Details
                  Container(
                    width: width,
                    decoration: AppTheme.boxDecoration(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bank Account Details',
                            style: AppTheme.textStyleBold),
                        const SizedBox(height: 16),
                        _buildDetailRow("Bank Name", "Your Bank"),
                        _buildDetailRow("Account Holder", "John Doe"),
                        _buildDetailRow("Account Number", "123456789"),
                        _buildDetailRow("Routing Number", "987654"),
                        _buildDetailRow("Swift Code", "SWIFT123"),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 400.ms)
                      .slideX(begin: -0.3),

                  const SizedBox(height: 20),

                  // Deposit Slip Upload
                  GestureDetector(
                    onTap: _showFileSourceDialog,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color.fromARGB(255, 172, 21, 177)
                              .withOpacity(0.5),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: _file != null
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_fileType == 'PDF Document')
                                  const Icon(
                                    Icons.picture_as_pdf,
                                    size: 70,
                                    color: Colors.red,
                                  )
                                else
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.file(
                                      _file!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _fileType ?? 'File',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.cloud_upload,
                                      color: Colors.white, size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Tap to upload payment proof",
                                    style: AppTheme.textStyleSmall,
                                  ),
                                  Text(
                                    "Supported: JPG, PNG, PDF",
                                    style: AppTheme.textStyleSmall.copyWith(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 600.ms)
                      .slideY(begin: 0.3),

                  const SizedBox(height: 20),

                  const Spacer(),

                  // Get Started Button (modified to show uploading state)
                  Container(
                    width: width,
                    decoration: AppTheme.buttonDecoration(),
                    child: ElevatedButton(
                      style: AppTheme.buttonStyle(),
                      onPressed: _isUploading ? null : _uploadFile,
                      child: _isUploading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Uploading...',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 18),
                                ),
                              ],
                            )
                          : const Text(
                              'Get Started',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 800.ms)
                      .slideY(begin: 0.3),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
