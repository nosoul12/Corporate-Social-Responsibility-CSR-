import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:animal_rescue_app/core/constants/app_constants.dart';
import 'package:animal_rescue_app/core/theme/app_theme.dart';
import 'package:animal_rescue_app/features/auth/providers/auth_provider.dart';
import 'package:animal_rescue_app/features/cases/models/case_model.dart';
import 'package:animal_rescue_app/features/cases/providers/case_provider.dart';
import 'package:animal_rescue_app/features/adoption/providers/adoption_provider.dart';
import 'package:animal_rescue_app/features/services/api_service.dart';
import 'package:animal_rescue_app/features/services/location_service.dart';
import 'package:animal_rescue_app/features/ngo/screens/location_picker_screen.dart';
import 'package:animal_rescue_app/features/auth/screens/profile_image_selector_screen.dart';

class NgoDashboardScreen extends ConsumerStatefulWidget {
  const NgoDashboardScreen({super.key});

  @override
  ConsumerState<NgoDashboardScreen> createState() => _NgoDashboardScreenState();
}

class _NgoDashboardScreenState extends ConsumerState<NgoDashboardScreen>
    with SingleTickerProviderStateMixin {
  // Local state variables
  Position? _currentPosition;
  List<AnimalCase> _nearbyCases = [];
  bool _isLoadingCases = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(caseProvider.notifier).loadCases();
      ref.read(adoptionProvider.notifier).loadAdoptions();
    });

    _initLocationAndCases();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndCases() async {
    try {
      final position = await LocationService().getCurrentLocation();
      if (!mounted) return;

      if (position == null) {
        setState(() {
          _isLoadingCases = false;
        });
        return;
      }

      setState(() {
        _currentPosition = position;
      });

      await _loadNearbyCases(position);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load initial data: $e';
        _isLoadingCases = false;
      });
    }
  }

  Future<void> _loadNearbyCases(Position position) async {
    setState(() {
      _isLoadingCases = true;
      _error = null;
    });

    try {
      final response = await ApiService()
          .getNearbyCases(position.latitude, position.longitude);

      if (!mounted) return;

      final cases = response
          .map((json) => AnimalCase.fromJson(json))
          .where((c) => c.type != 'ADOPTION')
          .toList();

      setState(() {
        _nearbyCases = cases;
        _isLoadingCases = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load nearby cases: $e';
        _isLoadingCases = false;
      });
    }
  }

  void _refreshNearby(Position position) {
    setState(() {
      _currentPosition = position;
    });
    _loadNearbyCases(position);
  }

  Future<void> _handleRespond(AnimalCase c) async {
    // 1. Optimistic Update
    final authState = ref.read(authProvider);
    final currentUser = authState.profile;
    final assignedUser = CaseUser(
      id: currentUser?.id ?? authState.userId ?? '',
      name: currentUser?.name ?? 'NGO Responder',
      email: currentUser?.email ?? '',
    );

    // Find index and update locally
    final index = _nearbyCases.indexWhere((x) => x.id == c.id);
    if (index != -1) {
      setState(() {
        _nearbyCases[index] = c.copyWith(
          status: 'In Progress',
          assignedNgo: assignedUser,
        );
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Responding to “${c.title}”'),
          backgroundColor: AppTheme.success,
        ),
      );
    }

    // 2. Real API Update
    try {
      await ref
          .read(caseProvider.notifier)
          .updateCaseStatus(c.id, 'In Progress');
    } catch (e) {
      // Revert if failed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleResolve(AnimalCase c) async {
    // 1. Optimistic Update
    final index = _nearbyCases.indexWhere((x) => x.id == c.id);
    if (index != -1) {
      setState(() {
        _nearbyCases[index] = c.copyWith(status: 'Resolved');
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Case marked as Resolved!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }

    // 2. Real API Update
    await ref.read(caseProvider.notifier).updateCaseStatus(c.id, 'Resolved');
  }

  Future<void> _handleDelete(AnimalCase c) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Case'),
        content: Text('Are you sure you want to delete "${c.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Optimistic Update: Remove from local list
    setState(() {
      _nearbyCases.removeWhere((x) => x.id == c.id);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Case deleted!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }

    // Real API Delete
    try {
      await ref.read(caseProvider.notifier).deleteCase(c.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete case: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter lists immediately from local state
    final activeCases = _nearbyCases.where((c) {
      return c.status == 'Reported' && c.assignedNgo == null;
    }).toList();

    final userId = ref.watch(authProvider).userId;
    // Include minimal fallback if userId is empty (shouldn't happen for auth'd NGO)
    final respondedCases = _nearbyCases.where((c) {
      if (c.assignedNgo == null) return false;
      // Check ID match
      final isAssignedToMe = c.assignedNgo!.id == userId;
      // Check status
      final isRelevantStatus =
          c.status == 'In Progress' || c.status == 'Resolved';
      return isAssignedToMe && isRelevantStatus;
    }).toList();

    // Sort by distance if location available
    if (_currentPosition != null) {
      int sortFunc(AnimalCase a, AnimalCase b) {
        final da = LocationService().calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          a.latitude,
          a.longitude,
        );
        final db = LocationService().calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          b.latitude,
          b.longitude,
        );
        return da.compareTo(db);
      }

      activeCases.sort(sortFunc);
      respondedCases.sort(sortFunc);
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: AppTheme.onPrimary,
        flexibleSpace: AppTheme.appBarFlexibleSpace(context),
        title: const Text('NGO Operations'),
        actions: [
          IconButton(
            tooltip: 'Update Profile Picture',
            icon: Consumer(builder: (context, ref, child) {
              final profile = ref.watch(authProvider).profile;
              final assetPath = profile?.localImageAsset;
              if (assetPath != null) {
                return CircleAvatar(
                  backgroundImage: AssetImage(assetPath),
                  radius: 14,
                );
              }
              return const Icon(Icons.account_circle);
            }),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileImageSelectorScreen(),
                ),
              );
              if (result != null && result is Map && result['prompt'] != null) {
                await ref
                    .read(authProvider.notifier)
                    .updateProfileImage(result['prompt']);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile picture updated!')),
                  );
                }
              }
            },
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Active Reports (${activeCases.length})'),
            Tab(text: 'My Responded (${respondedCases.length})'),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoadingCases
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1: ACTIVE
                      _ActiveReportsTab(
                        cases: activeCases,
                        position: _currentPosition,
                        onRefreshLocation: _refreshNearby,
                        onRespond: _handleRespond,
                        onDelete: _handleDelete,
                      ),

                      // TAB 2: RESPONDED
                      _RespondedReportsTab(
                        cases: respondedCases,
                        position: _currentPosition,
                        onRefreshLocation: _refreshNearby,
                        onResolve: _handleResolve,
                        onDelete: _handleDelete,
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _ActiveReportsTab extends StatelessWidget {
  final List<AnimalCase> cases;
  final Position? position;
  final Function(Position) onRefreshLocation;
  final Function(AnimalCase) onRespond;
  final Function(AnimalCase) onDelete;

  const _ActiveReportsTab({
    required this.cases,
    required this.position,
    required this.onRefreshLocation,
    required this.onRespond,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _LocationStatusCard(
            position: position,
            onLocationUpdated: onRefreshLocation,
          ),
        ),
        if (cases.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text(
                'No active nearby reports.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final c = cases[index];
                final distance = position != null
                    ? LocationService().calculateDistance(
                        position!.latitude,
                        position!.longitude,
                        c.latitude,
                        c.longitude,
                      )
                    : null;

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: _NgoCaseCard(
                    caseItem: c,
                    distanceMeters: distance,
                    onRespond: () => onRespond(c),
                    onResolve: () {},
                    onDelete: () => onDelete(c),
                    showRespondButton: true,
                    showResolveButton: false,
                  ),
                );
              },
              childCount: cases.length,
            ),
          ),
      ],
    );
  }
}

class _RespondedReportsTab extends StatelessWidget {
  final List<AnimalCase> cases;
  final Position? position;
  final Function(Position) onRefreshLocation;
  final Function(AnimalCase) onResolve;
  final Function(AnimalCase) onDelete;

  const _RespondedReportsTab({
    required this.cases,
    required this.position,
    required this.onRefreshLocation,
    required this.onResolve,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (cases.isEmpty) {
      return const Center(
          child: Text('You have no active responses.',
              style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final c = cases[index];
        final distance = position != null
            ? LocationService().calculateDistance(
                position!.latitude,
                position!.longitude,
                c.latitude,
                c.longitude,
              )
            : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _NgoCaseCard(
            caseItem: c,
            distanceMeters: distance,
            onRespond: () {}, // Already responded
            onResolve: () => onResolve(c),
            onDelete: () => onDelete(c),
            showRespondButton: false,
            showResolveButton: c.status != 'Resolved',
          ),
        );
      },
    );
  }
}

class _LocationStatusCard extends StatelessWidget {
  final Position? position;
  final Function(Position) onLocationUpdated;

  const _LocationStatusCard({
    required this.position,
    required this.onLocationUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push<Map<String, double>>(
              context,
              MaterialPageRoute(
                builder: (context) => LocationPickerScreen(
                  initialLatitude: position?.latitude,
                  initialLongitude: position?.longitude,
                ),
              ),
            );

            if (result != null && context.mounted) {
              final newPos = Position(
                longitude: result['lng']!,
                latitude: result['lat']!,
                timestamp: DateTime.now(),
                accuracy: 0,
                altitude: 0,
                altitudeAccuracy: 0,
                heading: 0,
                headingAccuracy: 0,
                speed: 0,
                speedAccuracy: 0,
              );
              onLocationUpdated(newPos);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Responder location updated! Refreshing...'),
                  backgroundColor: AppTheme.success,
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.my_location,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Responder Location',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        position == null ? 'Tap to set' : 'Update location',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NgoCaseCard extends StatelessWidget {
  final AnimalCase caseItem;
  final double? distanceMeters;
  final VoidCallback onRespond;
  final VoidCallback onResolve;
  final VoidCallback? onDelete;
  final bool showRespondButton;
  final bool showResolveButton;

  const _NgoCaseCard({
    required this.caseItem,
    required this.distanceMeters,
    required this.onRespond,
    required this.onResolve,
    this.onDelete,
    this.showRespondButton = false,
    this.showResolveButton = false,
  });

  Color _severityColor(String? severity) {
    if (severity == 'Critical') return Colors.red;
    if (severity == 'Urgent') return Colors.orange;
    return Colors.blue;
  }

  Color _statusColor(String status) {
    if (status == 'Resolved') return Colors.green;
    if (status == 'In Progress') return Colors.amber;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final severityLabel = caseItem.severity ?? caseItem.type;
    final severityColor = _severityColor(severityLabel);
    final distanceText = distanceMeters == null
        ? 'Unknown dist'
        : distanceMeters! >= 1000
            ? '${(distanceMeters! / 1000).toStringAsFixed(1)} km'
            : '${distanceMeters!.toStringAsFixed(0)} m';

    final locationFuture = LocationService().getReadableLocation(
      caseItem.latitude,
      caseItem.longitude,
    );

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: () {
          context.push('${AppConstants.caseDetailRoute}?id=${caseItem.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.pets, color: severityColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          caseItem.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        FutureBuilder<String>(
                          future: locationFuture,
                          builder: (context, snapshot) {
                            final label = snapshot.data ?? 'Locating…';
                            return Text(
                              '$distanceText • $label',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: severityColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      severityLabel,
                      style: TextStyle(
                        color: severityColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (caseItem.status != 'Reported')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(caseItem.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        caseItem.status,
                        style: TextStyle(
                          color: _statusColor(caseItem.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              if (showRespondButton || showResolveButton) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (showRespondButton)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onRespond,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Respond To Case'),
                        ),
                      ),
                    if (showResolveButton) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onResolve,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text('Mark Resolved'),
                        ),
                      ),
                      if (onDelete != null) const SizedBox(width: 8),
                    ],
                    if (onDelete != null)
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                        tooltip: 'Delete Case',
                      ),
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
