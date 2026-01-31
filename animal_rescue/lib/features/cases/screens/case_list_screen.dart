import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:animal_rescue_app/core/constants/app_constants.dart';
import 'package:animal_rescue_app/core/theme/app_theme.dart';
import 'package:animal_rescue_app/core/theme/primary_gradient_button.dart';
import 'package:animal_rescue_app/features/cases/models/case_model.dart';
import 'package:animal_rescue_app/features/cases/providers/case_provider.dart';
import 'package:animal_rescue_app/features/auth/providers/auth_provider.dart';
import 'package:animal_rescue_app/features/services/location_service.dart';

class CaseListScreen extends ConsumerStatefulWidget {
  const CaseListScreen({super.key});

  @override
  ConsumerState<CaseListScreen> createState() => _CaseListScreenState();
}

class _CaseListScreenState extends ConsumerState<CaseListScreen> {
  String _selectedStatus = 'All';
  String _selectedSeverity = 'All';

  String _normalizeStatusForCompare(String status) {
    return status == 'In Progress' ? 'InProgress' : status;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(caseProvider.notifier).loadCases();
    });
  }

  @override
  Widget build(BuildContext context) {
    final caseState = ref.watch(caseProvider);
    final authState = ref.watch(authProvider);
    final isNGO = authState.userRole == AppConstants.ngoRole;

    List<AnimalCase> filteredCases = caseState.cases;

    if (_selectedStatus != 'All') {
      filteredCases = filteredCases
          .where(
            (case_) =>
                _normalizeStatusForCompare(case_.status) ==
                _normalizeStatusForCompare(_selectedStatus),
          )
          .toList();
    }

    if (_selectedSeverity != 'All') {
      filteredCases = filteredCases
          .where((case_) => case_.severity == _selectedSeverity)
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.transparent,
        surfaceTintColor: AppTheme.onPrimary,
        centerTitle: true,
        flexibleSpace: AppTheme.appBarFlexibleSpace(context),
        title: const Text('Animal Cases'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(caseProvider.notifier).loadCases();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Status Filter
                Row(
                  children: [
                    const Text('Status: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', ...AppConstants.caseStatuses]
                              .map((status) {
                            final isSelected = _selectedStatus == status;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(status),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedStatus = selected ? status : 'All';
                                  });
                                },
                                backgroundColor: Colors.grey.shade200,
                                selectedColor: Colors.blue.shade100,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Severity Filter
                Row(
                  children: [
                    const Text('Severity: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', ...AppConstants.caseSeverities]
                              .map((severity) {
                            final isSelected = _selectedSeverity == severity;
                            Color getColor() {
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

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(severity),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedSeverity =
                                        selected ? severity : 'All';
                                  });
                                },
                                backgroundColor: Colors.grey.shade200,
                                selectedColor: getColor().withOpacity(0.2),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Cases List
          Expanded(
            child: caseState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : caseState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: ${caseState.error}'),
                            const SizedBox(height: 16),
                            PrimaryGradientButton(
                              onPressed: () {
                                ref.read(caseProvider.notifier).loadCases();
                              },
                              expand: false,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 18,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredCases.isEmpty
                        ? const Center(
                            child: Text('No cases found'),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              await ref.read(caseProvider.notifier).loadCases();
                            },
                            child: ListView.builder(
                              itemCount: filteredCases.length,
                              itemBuilder: (context, index) {
                                final animalCase = filteredCases[index];
                                return CaseCard(
                                  case_: animalCase,
                                  onTap: () {
                                    context.go(
                                        '${AppConstants.caseDetailRoute}?id=${animalCase.id}');
                                  },
                                  isNGO: isNGO,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: !isNGO
          ? FloatingActionButton(
              onPressed: () {
                context.go(AppConstants.reportCaseRoute);
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class CaseCard extends StatelessWidget {
  final AnimalCase case_;
  final VoidCallback onTap;
  final bool isNGO;

  const CaseCard({
    super.key,
    required this.case_,
    required this.onTap,
    this.isNGO = false,
  });

  Color getStatusColor(String status) {
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

  Color getSeverityColor(String severity) {
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

  @override
  Widget build(BuildContext context) {
    final severityLabel = case_.severity ?? case_.type;
    final displayStatus =
        case_.status == 'InProgress' ? 'In Progress' : case_.status;
    final locationFuture = LocationService().getReadableLocation(
      case_.latitude,
      case_.longitude,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and badges
              Row(
                children: [
                  Expanded(
                    child: Text(
                      case_.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: getSeverityColor(severityLabel).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      severityLabel,
                      style: TextStyle(
                        color: getSeverityColor(severityLabel),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                case_.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: getStatusColor(case_.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  displayStatus,
                  style: TextStyle(
                    color: getStatusColor(case_.status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Footer with location and time
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: FutureBuilder<String>(
                      future: locationFuture,
                      builder: (context, snapshot) {
                        final label = snapshot.data ?? 'Locating…';
                        return Text(
                          label,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, HH:mm').format(case_.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),

              // Additional info
              if (case_.type.isNotEmpty || case_.assignedNgo != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.pets,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      case_.type,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    if (case_.assignedNgo != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.volunteer_activism_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          case_.assignedNgo!.name,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
