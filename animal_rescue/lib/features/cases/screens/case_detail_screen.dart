import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:animal_rescue_app/core/constants/app_constants.dart';
import 'package:animal_rescue_app/core/theme/app_theme.dart';
import 'package:animal_rescue_app/features/auth/providers/auth_provider.dart';
import 'package:animal_rescue_app/features/cases/models/case_model.dart';
import 'package:animal_rescue_app/features/cases/providers/case_provider.dart';
import 'package:animal_rescue_app/features/services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';

class CaseDetailScreen extends ConsumerStatefulWidget {
  final String caseId;

  const CaseDetailScreen({
    super.key,
    required this.caseId,
  });

  @override
  ConsumerState<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends ConsumerState<CaseDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(caseProvider.notifier).loadCase(widget.caseId);
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Reported':
        return Colors.blue;
      case 'In Progress':
      case 'InProgress':
        return Colors.orange;
      case 'Resolved':
        return Colors.green;
      case 'Closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'Critical':
        return Colors.red;
      case 'Urgent':
        return Colors.orange;
      case 'Moderate':
        return Colors.yellow;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showUpdateStatusSheet(BuildContext context, AnimalCase animalCase) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: AppConstants.caseStatuses.map((status) {
              return ListTile(
                title: Text(status),
                trailing: animalCase.status == status
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref
                      .read(caseProvider.notifier)
                      .updateCaseStatus(animalCase.id, status);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final caseState = ref.watch(caseProvider);
    final authState = ref.watch(authProvider);
    final isNGO = authState.userRole == AppConstants.ngoRole;

    final AnimalCase? selected = caseState.selectedCase?.id == widget.caseId
        ? caseState.selectedCase
        : null;
    final AnimalCase? animalCase = selected ??
        (() {
          final matches =
              caseState.cases.where((c) => c.id == widget.caseId).toList();
          return matches.isNotEmpty ? matches.first : null;
        })();

    final String? severityLabel = animalCase?.severity ?? animalCase?.type;
    final displayStatus =
        animalCase?.status == 'InProgress' ? 'In Progress' : animalCase?.status;
    final locationFuture = animalCase == null
        ? null
        : LocationService()
            .getReadableLocation(animalCase.latitude, animalCase.longitude);

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        flexibleSpace: AppTheme.appBarFlexibleSpace(context),
        title: const Text('Case Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Share functionality coming soon!')),
              );
            },
          ),
        ],
      ),
      body: caseState.isLoading && animalCase == null
          ? const Center(child: CircularProgressIndicator())
          : caseState.error != null && animalCase == null
              ? Center(child: Text('Error: ${caseState.error}'))
              : animalCase == null
                  ? const Center(child: Text('Case not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Case Header
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.pets,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          animalCase.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _StatusChip(
                                        label: displayStatus ?? '',
                                        color: _statusColor(animalCase.status),
                                      ),
                                      const SizedBox(width: 8),
                                      if (severityLabel != null)
                                        _StatusChip(
                                          label: severityLabel,
                                          color: _severityColor(severityLabel),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Case Information
                          _InfoSection(
                            title: 'Case Information',
                            children: [
                              _InfoRow(
                                icon: Icons.description,
                                label: 'Description',
                                value: animalCase.description,
                              ),
                              _InfoRow(
                                icon: Icons.location_on,
                                label: 'Location',
                                value: '',
                                valueWidget: locationFuture == null
                                    ? const Text('Location unavailable')
                                    : FutureBuilder<String>(
                                        future: locationFuture,
                                        builder: (context, snapshot) {
                                          final label = snapshot.data ??
                                              'Lat: ${animalCase.latitude.toStringAsFixed(4)}, Lng: ${animalCase.longitude.toStringAsFixed(4)}';
                                          return Text(label);
                                        },
                                      ),
                              ),
                              _InfoRow(
                                icon: Icons.category,
                                label: 'Type',
                                value: animalCase.type,
                              ),
                              _InfoRow(
                                icon: Icons.calendar_today,
                                label: 'Reported Date',
                                value: DateFormat('MMM dd, yyyy - hh:mm a')
                                    .format(animalCase.createdAt),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Reporter Information
                          _InfoSection(
                            title: 'Reporter Information',
                            children: [
                              _InfoRow(
                                icon: Icons.person,
                                label: 'Name',
                                value: animalCase.reportedBy.name,
                              ),
                              _InfoRow(
                                icon: Icons.email,
                                label: 'Email',
                                value: animalCase.reportedBy.email,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Images Section
                          _InfoSection(
                            title: 'Photos',
                            children: [
                              SizedBox(
                                height: 200,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount:
                                      animalCase.imageUrl.isNotEmpty ? 1 : 0,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      width: 250,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Image.network(
                                        animalCase.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Center(
                                            child: Icon(Icons.image, size: 40),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                              if (animalCase.imageUrl.isEmpty)
                                const Text('No photos available'),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Action Buttons
                          if (animalCase.status != 'Resolved')
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Reporter: ${animalCase.reportedBy.email}',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.phone),
                                    label: const Text('Contact Reporter'),
                                  ),
                                ),
                                if (isNGO) ...[
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        _showUpdateStatusSheet(
                                          context,
                                          animalCase,
                                        );
                                      },
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Update Status'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final url = Uri.parse(
                                            'https://www.google.com/maps/dir/?api=1&destination=${animalCase.latitude},${animalCase.longitude}');
                                        if (!await launchUrl(url,
                                            mode:
                                                LaunchMode.externalApplication)) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Could not launch maps')),
                                            );
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.directions),
                                      label: const Text('Directions'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(context).colorScheme.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                        ],
                      ),
                    ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? valueWidget;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Expanded(
          child: valueWidget ??
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
        ),
      ]),
    );
  }
}
