import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:animal_rescue_app/core/theme/app_theme.dart';
import 'package:animal_rescue_app/core/theme/primary_gradient_button.dart';

class ProfileImageSelectorScreen extends StatefulWidget {
  const ProfileImageSelectorScreen({super.key});

  @override
  State<ProfileImageSelectorScreen> createState() =>
      _ProfileImageSelectorScreenState();
}

class _ProfileImageSelectorScreenState
    extends State<ProfileImageSelectorScreen> {
  final List<_AvatarOption> _options = const [
    _AvatarOption(
      assetPath: 'assets/images/cow.png',
      label: 'Gentle Cow',
    ),
    _AvatarOption(
      assetPath: 'assets/images/parrot.png',
      label: 'Bright Parrot',
    ),
    _AvatarOption(
      assetPath: 'assets/images/whole.png',
      label: 'Paw Buddy',
    ),
  ];

  final Map<String, Uint8List> _assetBytes = {};
  String? _selectedAsset;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAssets());
  }

  Future<void> _loadAssets() async {
    for (final option in _options) {
      final data = await rootBundle.load(option.assetPath);
      _assetBytes[option.assetPath] = data.buffer.asUint8List();
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
        _selectedAsset = _options.first.assetPath;
      });
    }
  }

  void _confirmSelection() {
    if (_selectedAsset == null) return;
    final bytes = _assetBytes[_selectedAsset!];
    Navigator.pop(context, {
      'imageData': bytes,
      'prompt': _selectedAsset,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        flexibleSpace: AppTheme.appBarFlexibleSpace(context),
        title: const Text('Choose Profile Picture'),
        actions: [
          if (_selectedAsset != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _confirmSelection,
              tooltip: 'Confirm Selection',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select your companion',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pick a profile photo from Pet Buddy assets.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: _options.length,
                  itemBuilder: (context, index) {
                    final option = _options[index];
                    final isSelected = option.assetPath == _selectedAsset;

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () =>
                          setState(() => _selectedAsset = option.assetPath),
                      child: Card(
                        elevation: isSelected ? 6 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: Image.asset(
                                  option.assetPath,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface
                                            .withOpacity(0.4),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      option.label,
                                      style: theme.textTheme.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryGradientButton(
                    onPressed:
                        _selectedAsset == null ? null : _confirmSelection,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Use Selected Image'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Skip for Now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarOption {
  final String assetPath;
  final String label;

  const _AvatarOption({
    required this.assetPath,
    required this.label,
  });
}
