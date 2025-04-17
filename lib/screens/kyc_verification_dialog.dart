import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:investment_plan_app/services/kyc_service.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart';

class KYCVerificationDialog extends StatefulWidget {
  final int userId;
  final Function onVerificationSubmitted;

  const KYCVerificationDialog({
    super.key,
    required this.userId,
    required this.onVerificationSubmitted,
  });

  @override
  _KYCVerificationDialogState createState() => _KYCVerificationDialogState();
}

class _KYCVerificationDialogState extends State<KYCVerificationDialog> {
  final KycService _apiService = KycService();
  final ImagePicker _picker = ImagePicker();

  String _selectedMethod = 'NIC';
  File? _frontImage;
  File? _backImage;
  bool _isUploading = false;
  String? _errorMessage;

  final List<String> _verificationMethods = [
    'NIC',
    'Driving License',
    'Passport'
  ];

  Future<void> _pickImage(bool isFront) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          if (isFront) {
            _frontImage = File(image.path);
          } else {
            _backImage = File(image.path);
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to pick image: $e";
      });
    }
  }

  Future<void> _submitVerification() async {
    if (_frontImage == null) {
      setState(() {
        _errorMessage = "Please upload the front image of your document.";
      });
      return;
    }

    if (_selectedMethod == 'NIC' && _backImage == null) {
      setState(() {
        _errorMessage = "Please upload the back image of your NIC.";
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.submitKYCVerification(
        widget.userId,
        _selectedMethod,
        _frontImage!,
        _backImage,
      );

      if (response['success']) {
        widget.onVerificationSubmitted();
        Navigator.of(context).pop();
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? "Failed to submit verification";
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error submitting verification: $e";
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "KYC Verification",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Select Verification Method",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0x1AD9D9D9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E1E1E),
                  underline: Container(),
                  style: const TextStyle(color: Colors.white),
                  value: _selectedMethod,
                  items: _verificationMethods.map((method) {
                    return DropdownMenuItem<String>(
                      value: method,
                      child: Text(method),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMethod = value!;
                      // Reset images when changing method
                      _frontImage = null;
                      _backImage = null;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Upload Document",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              // Front image upload
              _buildImageUploadSection(
                label:
                    "$_selectedMethod ${_selectedMethod == 'NIC' ? 'Front Side' : ''}",
                image: _frontImage,
                onTap: () => _pickImage(true),
              ),
              // Back image upload (only for NIC)
              if (_selectedMethod == 'NIC')
                _buildImageUploadSection(
                  label: "NIC Back Side",
                  image: _backImage,
                  onTap: () => _pickImage(false),
                ),
              const SizedBox(height: 12),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed:
                        _isUploading ? null : () => Navigator.of(context).pop(),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isUploading ? null : _submitVerification,
                    child: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text("Submit"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection({
    required String label,
    required File? image,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0x1AD9D9D9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
              ),
            ),
            child: image == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        "Tap to upload",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
