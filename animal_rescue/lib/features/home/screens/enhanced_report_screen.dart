import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:animal_rescue_app/core/widgets/platform_file_image.dart';
import 'package:animal_rescue_app/core/theme/app_theme.dart';
import 'package:animal_rescue_app/core/theme/primary_gradient_button.dart';
import 'package:animal_rescue_app/features/adoption/providers/adoption_provider.dart';
import 'package:animal_rescue_app/features/cases/providers/case_provider.dart';
import 'package:animal_rescue_app/features/services/location_service.dart';
import 'package:animal_rescue_app/core/constants/app_constants.dart';

class EnhancedReportScreen extends ConsumerStatefulWidget {
  const EnhancedReportScreen({super.key});

  @override
  ConsumerState<EnhancedReportScreen> createState() =>
      _EnhancedReportScreenState();
}

class _EnhancedReportScreenState extends ConsumerState<EnhancedReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedPostType = 'Injured Animal';
  String _selectedSeverity = 'Moderate';
  String _selectedAnimalType = 'Dog';

  XFile? _imageFile;
  Position? _currentPosition;
  bool _isGettingLocation = false;
  bool _isSubmitting = false;

  final List<String> _postTypes = [
    'Injured Animal',
    'Newborn Animal',
    'Emergency',
    'Adoption'
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final position = await LocationService().getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _locationController.text =
              '${position.latitude}, ${position.longitude}';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _imageFile = image);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _imageFile = image);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to take picture: $e')),
      );
    }
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add an image'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable location services'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isSubmitting = true);

      try {
        final imageBytes = await _imageFile!.readAsBytes();
        final imageFilename = _imageFile!.name;

        if (_selectedPostType == 'Adoption') {
          await ref.read(adoptionProvider.notifier).createAdoption(
                title: _selectedAnimalType,
                description: _descriptionController.text,
                latitude: _currentPosition!.latitude,
                longitude: _currentPosition!.longitude,
                imageBytes: imageBytes,
                imageFilename: imageFilename,
              );
        } else {
          String type;
          switch (_selectedPostType) {
            case 'Injured Animal':
              type = 'INJURED';
              break;
            case 'Newborn Animal':
              type = 'NEWBORN';
              break;
            case 'Emergency':
              type = 'EMERGENCY';
              break;
            default:
              type = 'INJURED';
          }

          await ref.read(caseProvider.notifier).createCase(
                title: '$_selectedPostType: $_selectedAnimalType',
                description: _descriptionController.text,
                type: type,
                severity: _selectedSeverity,
                latitude: _currentPosition!.latitude,
                longitude: _currentPosition!.longitude,
                imageBytes: imageBytes,
                imageFilename: imageFilename,
              );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.transparent,
        surfaceTintColor: AppTheme.onPrimary,
        centerTitle: true,
        flexibleSpace: AppTheme.appBarFlexibleSpace(context),
        title: const Text('Report Animal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post Type Selection
              const Text(
                'Post Type *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPostType,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category),
                ),
                items: _postTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedPostType = value!),
              ),
              const SizedBox(height: 16),

              // Animal Type Selection
              const Text(
                'Animal Type *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedAnimalType,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.pets),
                ),
                items: ['Dog', 'Cat', 'Bird', 'Other'].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedAnimalType = value!),
              ),
              const SizedBox(height: 16),

              // Severity Selection
              const Text(
                'Severity *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSeverity,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.warning),
                ),
                items: AppConstants.caseSeverities.map((severity) {
                  return DropdownMenuItem(
                    value: severity,
                    child: Text(severity),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedSeverity = value!),
              ),
              const SizedBox(height: 16),

              // Description
              const Text(
                'Description *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe the situation...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.length < 10) {
                    return 'Description must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Location
              const Text(
                'Location *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _locationController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        hintText: 'Getting location...',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isGettingLocation ? null : _getCurrentLocation,
                    icon: _isGettingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                  ),
                ],
              ),
              if (_currentPosition != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Image Upload
              const Text(
                'Photo *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _imageFile != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: PlatformFileImage(
                              _imageFile!.path,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _imageFile = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 50,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add photo',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),

              // Image Selection Buttons
              Row(
                children: [
                  Expanded(
                    child: PrimaryGradientButton(
                      onPressed: _pickImage,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      borderRadius: 14,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Gallery'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PrimaryGradientButton(
                      onPressed: _takePicture,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      borderRadius: 14,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Camera'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit Button
              PrimaryGradientButton(
                height: 50,
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
