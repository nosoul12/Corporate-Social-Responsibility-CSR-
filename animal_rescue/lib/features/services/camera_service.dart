import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  final ImagePicker _imagePicker = ImagePicker();

  Future<bool> hasCameraPermission() async {
    final cameraStatus = await Permission.camera.status;
    return cameraStatus.isGranted;
  }

  Future<bool> requestCameraPermission() async {
    final cameraStatus = await Permission.camera.request();
    return cameraStatus.isGranted;
  }

  Future<List<CameraDescription>> getAvailableCameras() async {
    try {
      return await availableCameras();
    } catch (e) {
      throw Exception('Failed to get available cameras: $e');
    }
  }

  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image?.path;
    } catch (e) {
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  Future<String?> takePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image?.path;
    } catch (e) {
      throw Exception('Failed to take picture: $e');
    }
  }

  Future<String?> pickVideoFromGallery() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      return video?.path;
    } catch (e) {
      throw Exception('Failed to pick video from gallery: $e');
    }
  }

  Future<String?> recordVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 2),
      );
      return video?.path;
    } catch (e) {
      throw Exception('Failed to record video: $e');
    }
  }

  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  // For advanced camera control (if using CameraController directly)
  Future<CameraController?> createCameraController(
    CameraDescription camera,
  ) async {
    try {
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      return controller;
    } catch (e) {
      throw Exception('Failed to create camera controller: $e');
    }
  }

  Future<void> disposeCameraController(CameraController controller) async {
    try {
      await controller.dispose();
    } catch (e) {
      throw Exception('Failed to dispose camera controller: $e');
    }
  }
}
