import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:animal_rescue_app/core/constants/app_constants.dart';
import 'package:animal_rescue_app/core/theme/app_theme.dart';
import 'package:animal_rescue_app/core/theme/primary_gradient_button.dart';
import 'package:animal_rescue_app/features/adoption/providers/adoption_provider.dart';
import 'package:animal_rescue_app/features/auth/providers/auth_provider.dart';
import 'package:animal_rescue_app/features/bookmarks/providers/bookmark_provider.dart';
import 'package:animal_rescue_app/features/cases/models/case_model.dart';
import 'package:animal_rescue_app/features/cases/providers/case_provider.dart';
import 'package:animal_rescue_app/features/home/screens/enhanced_report_screen.dart';
import 'package:animal_rescue_app/features/home/widgets/location_map_widget.dart';
import 'package:animal_rescue_app/features/services/location_service.dart';
import 'package:animal_rescue_app/features/auth/screens/profile_image_selector_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(caseProvider.notifier).loadCases();
      ref.read(adoptionProvider.notifier).loadAdoptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (_currentIndex != 0) {
          // Navigate back to home tab first
          setState(() => _currentIndex = 0);
          return;
        }

        // Show exit confirmation dialog
        final shouldExit = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Exit App'),
                content: const Text('Are you sure you want to exit?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  PrimaryGradientButton(
                    onPressed: () => Navigator.pop(context, true),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 18),
                    borderRadius: 14,
                    expand: false,
                    child: const Text('Exit'),
                  ),
                ],
              ),
            ) ??
            false;

        if (shouldExit && context.mounted) {
          // Exit the app (on Android)
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            FeedTab(),
            ReportTab(),
            AdoptionTab(),
            ProfileTab(),
          ],
        ),
        bottomNavigationBar: _buildBottomNavBar(),
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton(
                onPressed: () => _showReportBottomSheet(context),
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primary,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.22),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppTheme.accent,
            unselectedItemColor: AppTheme.background,
            selectedIconTheme: const IconThemeData(size: 24),
            unselectedIconTheme: const IconThemeData(size: 24),
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.report_outlined),
                activeIcon: Icon(Icons.report),
                label: 'Report',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_outline),
                activeIcon: Icon(Icons.favorite),
                label: 'Adopt',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ReportBottomSheet(),
    );
  }
}

class FeedTab extends ConsumerWidget {
  const FeedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseState = ref.watch(caseProvider);
    final adoptionState = ref.watch(adoptionProvider);

    final isLoading = caseState.isLoading || adoptionState.isLoading;
    final errorText = caseState.error ?? adoptionState.error;

    final feedItems = [
      ...caseState.cases,
      ...adoptionState.adoptions,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          elevation: 1,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          flexibleSpace: AppTheme.appBarFlexibleSpace(context),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pets,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 26,
              ),
              const SizedBox(width: 8),
              Text(
                'Pet Buddy',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => _showNotifications(context),
            ),
          ],
        ),
        if (isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (errorText != null)
          SliverFillRemaining(
            child: Center(child: Text('Error: $errorText')),
          )
        else if (feedItems.isEmpty)
          const SliverFillRemaining(
            child: Center(child: Text('No cases or adoptions yet.')),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final animalCase = feedItems[index];
                return _FeedCaseCard(
                  animalCase: animalCase,
                  isAdoption: animalCase.type == 'ADOPTION',
                );
              },
              childCount: feedItems.length,
            ),
          ),
      ],
    );
  }

  void _showNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No new notifications'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _FeedCaseCard extends ConsumerWidget {
  final AnimalCase animalCase;
  final bool isAdoption;

  const _FeedCaseCard({required this.animalCase, this.isAdoption = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkState = ref.watch(bookmarkProvider);
    final isSaved = bookmarkState.caseIds.contains(animalCase.id);
    final displayStatus = isAdoption
        ? 'Adoption'
        : animalCase.status == 'InProgress'
            ? 'In Progress'
            : animalCase.status;
    final locationFuture = LocationService().getReadableLocation(
      animalCase.latitude,
      animalCase.longitude,
    );
    final dateLabel = DateFormat('MMM d, HH:mm').format(animalCase.createdAt);

    return Card(
      child: InkWell(
        onTap: () {
          context.go('${AppConstants.caseDetailRoute}?id=${animalCase.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          animalCase.reportedBy.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        FutureBuilder<String>(
                          future: locationFuture,
                          builder: (context, snapshot) {
                            final locationLabel = snapshot.data;
                            final subtitle = locationLabel == null
                                ? '$dateLabel • Locating…'
                                : '$dateLabel • $locationLabel';
                            return Text(
                              subtitle,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon:
                        Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                    onPressed: () async {
                      final isNowSaved =
                          await ref.read(bookmarkProvider.notifier).toggle(
                                animalCase.id,
                              );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isNowSaved ? 'Saved post' : 'Removed from saved',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 280,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      animalCase.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.image, size: 48),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        displayStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _showLocationMap(context, animalCase),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animalCase.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    animalCase.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.pets, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        isAdoption ? 'Adoption' : animalCase.type,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      if (animalCase.severity != null && !isAdoption)
                        Text(
                          animalCase.severity!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationMap(BuildContext context, AnimalCase animalCase) {
    final locationFuture = LocationService().getReadableLocation(
      animalCase.latitude,
      animalCase.longitude,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => FutureBuilder<String>(
          future: locationFuture,
          builder: (context, snapshot) {
            final locationName = snapshot.data ??
                'Lat ${animalCase.latitude.toStringAsFixed(5)}, Lng ${animalCase.longitude.toStringAsFixed(5)}';

            return SingleChildScrollView(
              controller: scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Location Details',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  LocationMapWidget(
                    latitude: animalCase.latitude,
                    longitude: animalCase.longitude,
                    locationName: locationName,
                    caseTitle: animalCase.title,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class ReportTab extends StatelessWidget {
  const ReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.report_problem,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Report an Animal in Need',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Use the floating action button to report a case',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class AdoptionTab extends ConsumerWidget {
  const AdoptionTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adoptionState = ref.watch(adoptionProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          elevation: 1,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          flexibleSpace: AppTheme.appBarFlexibleSpace(context),
          title: Text(
            'Adoption Center',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
          ),
        ),
        if (adoptionState.isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (adoptionState.error != null)
          SliverFillRemaining(
            child: Center(child: Text('Error: ${adoptionState.error}')),
          )
        else if (adoptionState.adoptions.isEmpty)
          const SliverFillRemaining(
            child: Center(child: Text('No adoption listings yet.')),
          )
        else
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final adoption = adoptionState.adoptions[index];
                return _AdoptionCard(adoption: adoption);
              },
              childCount: adoptionState.adoptions.length,
            ),
          ),
      ],
    );
  }
}

class _AdoptionCard extends StatelessWidget {
  final AnimalCase adoption;

  const _AdoptionCard({required this.adoption});

  @override
  Widget build(BuildContext context) {
    final locationFuture = LocationService().getReadableLocation(
      adoption.latitude,
      adoption.longitude,
    );

    return GestureDetector(
      onTap: () => _showAdoptionDetails(context),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  adoption.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.pets, size: 48),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adoption.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, HH:mm').format(adoption.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        FutureBuilder<String>(
                          future: locationFuture,
                          builder: (context, snapshot) {
                            final label = snapshot.data ?? 'Locating…';
                            return Text(
                              label,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdoptionDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(adoption.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Description: ${adoption.description}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final caseState = ref.watch(caseProvider);
    final bookmarkState = ref.watch(bookmarkProvider);
    final savedCases = caseState.cases
        .where((c) => bookmarkState.caseIds.contains(c.id))
        .toList();

    if (authState.isAuthenticated &&
        !authState.isProfileLoading &&
        authState.profile == null) {
      Future.microtask(
        () => ref.read(authProvider.notifier).loadProfile(silent: true),
      );
    }

    final profile = authState.profile;
    final roleLabel = profile?.role ?? authState.userRole ?? 'User';
    final displayName = profile?.name ?? 'User';
    final email = profile?.email ?? '';
    final stats = profile?.stats ??
        const UserStats(
          reportedCases: 0,
          adoptionListings: 0,
          assignedCases: 0,
        );

    final localImage = profile?.localImageAsset;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Row(
            children: [
              Stack(
                children: [
                   GestureDetector(
                    onTap: () => _updateProfilePicture(context, ref),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.15),
                      backgroundImage: localImage != null
                          ? AssetImage(localImage)
                          : null,
                      child: localImage == null
                          ? Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : 'U',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _updateProfilePicture(context, ref),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      roleLabel,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey[700]),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                    if (authState.isProfileLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Saved Posts
          Text(
            'Saved Posts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          if (savedCases.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No saved posts yet. Tap the bookmark icon on a post to save it here.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: savedCases.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final savedCase = savedCases[index];
                return _FeedCaseCard(animalCase: savedCase);
              },
            ),
          const SizedBox(height: 24),

          // Stats
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: stats.reportedCases.toString(),
                  label: 'Reports',
                  icon: Icons.report,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  value: stats.adoptionListings.toString(),
                  label: 'Adoptions',
                  icon: Icons.favorite,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  value: stats.assignedCases.toString(),
                  label: 'Responded',
                  icon: Icons.volunteer_activism,
                ),
              ),
            ],
          ),
          if (profile?.ngo != null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.apartment,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(profile!.ngo?['name'] ?? 'NGO Account'),
                subtitle: Text(
                  profile!.ngo?['phone'] != null
                      ? 'Phone: ${profile!.ngo?['phone']}'
                      : 'NGO profile pending details',
                ),
                trailing: profile!.ngo?['verified'] == true
                    ? const Icon(Icons.verified, color: Colors.green)
                    : const Icon(Icons.verified_outlined, color: Colors.grey),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Menu Items
          Card(
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                  },
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfilePicture(
      BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileImageSelectorScreen(),
      ),
    );

    if (result != null && result is Map && result['prompt'] != null) {
      await ref.read(authProvider.notifier).updateProfileImage(result['prompt']);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
    }
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      onTap: onTap,
    );
  }
}

class ReportBottomSheet extends ConsumerWidget {
  const ReportBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report an Animal',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _ReportOption(
                  icon: Icons.pets,
                  title: 'Injured Animal',
                  subtitle: 'Report an animal that needs medical help',
                  onTap: () => Navigator.pop(context),
                ),
                _ReportOption(
                  icon: Icons.home,
                  title: 'Stray Animal',
                  subtitle: 'Report a lost or abandoned animal',
                  onTap: () => Navigator.pop(context),
                ),
                _ReportOption(
                  icon: Icons.warning,
                  title: 'Emergency Case',
                  subtitle: 'Report critical situations immediately',
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportOption extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ReportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _handleReport(context, ref, title),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  void _handleReport(BuildContext context, WidgetRef ref, String reportType) {
    Navigator.pop(context);

    // Navigate to enhanced report screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EnhancedReportScreen(),
      ),
    );
  }
}
