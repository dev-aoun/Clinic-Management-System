import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme.dart';
import 'appointment_details.dart';

class AppointmentsScreen extends StatefulWidget {
  final String token;

  const AppointmentsScreen({super.key, required this.token});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<dynamic> appointments = [];
  List<dynamic> patients = [];
  List<dynamic> doctors = [];

  bool isLoading = true;
  String? error;

  final TextEditingController searchController = TextEditingController();

  List<dynamic> get filteredAppointments {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return appointments;
    }

    return appointments.where((appointment) {
      final patientName = _patientName(appointment['patient_id']).toLowerCase();

      final doctorName = _doctorName(appointment['doctor_id']).toLowerCase();

      final date =
          appointment['appointment_date']?.toString().toLowerCase() ?? '';

      final time =
          appointment['appointment_time']?.toString().toLowerCase() ?? '';

      final status = appointment['status']?.toString().toLowerCase() ?? '';

      final notes = appointment['notes']?.toString().toLowerCase() ?? '';

      return patientName.contains(query) ||
          doctorName.contains(query) ||
          date.contains(query) ||
          time.contains(query) ||
          status.contains(query) ||
          notes.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    _loadAppointments();

    searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD APPOINTMENTS
  // ============================================================

  Future<void> _loadAppointments() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getAppointments(widget.token),
        ApiService.getPatients(widget.token),
        ApiService.getDoctors(widget.token),
      ]);

      if (!mounted) return;

      setState(() {
        appointments = results[0];
        patients = results[1];
        doctors = results[2];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  // ============================================================
  // PATIENT NAME
  // ============================================================

  String _patientName(dynamic patientId) {
    final id = int.tryParse(patientId?.toString() ?? '');

    if (id == null) {
      return '-';
    }

    for (final patient in patients) {
      if (patient['id']?.toString() == id.toString()) {
        return patient['name']?.toString() ?? 'Patient #$id';
      }
    }

    return 'Patient #$id';
  }

  // ============================================================
  // DOCTOR NAME
  // ============================================================

  String _doctorName(dynamic doctorId) {
    final id = int.tryParse(doctorId?.toString() ?? '');

    if (id == null) {
      return '-';
    }

    for (final doctor in doctors) {
      if (doctor['id']?.toString() == id.toString()) {
        return doctor['name']?.toString() ?? 'Doctor #$id';
      }
    }

    return 'Doctor #$id';
  }

  // ============================================================
  // TIME FORMAT
  // ============================================================

  String _formatTime(dynamic value) {
    if (value == null) {
      return '-';
    }

    final text = value.toString();

    if (text.length >= 5) {
      return text.substring(0, 5);
    }

    return text;
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.statusCompleted;

      case 'cancelled':
      case 'canceled':
        return AppTheme.statusCancelled;

      case 'confirmed':
      case 'in progress':
      case 'in_progress':
        return AppTheme.statusInProgress;

      case 'scheduled':
      default:
        return AppTheme.statusScheduled;
    }
  }

  // ============================================================
  // FORMAT STATUS
  // ============================================================

  String _formatStatus(String status) {
    if (status.trim().isEmpty) {
      return 'Scheduled';
    }

    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Appointments'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAppointments,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          // ======================================================
          // HEADER
          // ======================================================
          buildClinicalHeader(
            context,
            title: 'Appointment Management',
            subtitle: 'View and manage clinic appointments.',
            icon: Icons.calendar_month_outlined,
          ),

          const SizedBox(height: 24),

          // ======================================================
          // SEARCH
          // ======================================================
          _buildSearch(),

          const SizedBox(height: 18),

          // ======================================================
          // COUNT
          // ======================================================
          _buildAppointmentCount(),

          const SizedBox(height: 14),

          // ======================================================
          // LIST
          // ======================================================
          if (filteredAppointments.isEmpty)
            _buildEmptyState()
          else
            ...filteredAppointments.map(
              (appointment) => _buildAppointmentCard(context, appointment),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: 'Search patient, doctor, date, status...',

        prefixIcon: const Icon(Icons.search_rounded),

        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  searchController.clear();
                },
                icon: const Icon(Icons.clear_rounded),
              )
            : null,
      ),
    );
  }

  // ============================================================
  // COUNT
  // ============================================================

  Widget _buildAppointmentCount() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final count = filteredAppointments.length;

    return Row(
      children: [
        Text(
          '$count appointment${count == 1 ? '' : 's'}',
          style: TextStyle(
            color: isDark
                ? AppTheme.textSecondaryDark
                : AppTheme.textSecondaryLight,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),

        const Spacer(),

        if (searchController.text.isNotEmpty)
          Text(
            'Search results',
            style: TextStyle(
              color: isDark ? AppTheme.accentCyan : AppTheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  // ============================================================
  // APPOINTMENT CARD
  // ============================================================

  Widget _buildAppointmentCard(BuildContext context, dynamic appointment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final id = appointment['id']?.toString() ?? '-';

    final patientName = _patientName(appointment['patient_id']);

    final doctorName = _doctorName(appointment['doctor_id']);

    final date = appointment['appointment_date']?.toString() ?? '-';

    final time = _formatTime(appointment['appointment_time']);

    final status = appointment['status']?.toString() ?? 'scheduled';

    final notes = appointment['notes']?.toString() ?? '';

    final statusColor = _statusColor(status);

    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ======================================================
          // HEADER
          // ======================================================
          Row(
            children: [
              Container(
                width: 54,
                height: 54,

                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(
                    alpha: isDark ? 0.20 : 0.10,
                  ),

                  borderRadius: BorderRadius.circular(15),
                ),

                child: Icon(
                  Icons.calendar_month_rounded,
                  size: 28,
                  color: isDark ? AppTheme.accentCyan : AppTheme.primary,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Appointment #$id',
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      patientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.20 : 0.10),

                  borderRadius: BorderRadius.circular(20),
                ),

                child: Text(
                  _formatStatus(status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ======================================================
          // DOCTOR
          // ======================================================
          _InfoItem(
            icon: Icons.medical_services_outlined,
            title: 'Doctor',
            value: doctorName,
          ),

          const SizedBox(height: 14),

          // ======================================================
          // DATE + TIME
          // ======================================================
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  icon: Icons.calendar_today_outlined,
                  title: 'Date',
                  value: date,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: _InfoItem(
                  icon: Icons.access_time_rounded,
                  title: 'Time',
                  value: time,
                ),
              ),
            ],
          ),

          // ======================================================
          // NOTES
          // ======================================================
          if (notes.trim().isNotEmpty) ...[
            const SizedBox(height: 14),

            _InfoItem(icon: Icons.notes_rounded, title: 'Notes', value: notes),
          ],

          const SizedBox(height: 18),

          // ======================================================
          // DETAILS BUTTON
          // ======================================================
          SizedBox(
            width: double.infinity,
            height: 46,

            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AppointmentDetailsScreen(
                      token: widget.token,
                      appointment: appointment,
                    ),
                  ),
                );

                if (result != null) {
                  await _loadAppointments();
                }
              },

              icon: const Icon(Icons.visibility_outlined, size: 19),

              label: const Text('View Details'),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasSearch = searchController.text.trim().isNotEmpty;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(vertical: 55, horizontal: 24),

      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),

      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,

            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: isDark ? 0.18 : 0.08),

              borderRadius: BorderRadius.circular(18),
            ),

            child: Icon(
              hasSearch
                  ? Icons.search_off_rounded
                  : Icons.calendar_month_outlined,

              size: 32,

              color: isDark ? AppTheme.accentCyan : AppTheme.primary,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            hasSearch ? 'No appointments found' : 'No appointments yet',

            style: TextStyle(
              color: isDark
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,

              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            hasSearch
                ? 'Try searching with a different patient, doctor, date, or status.'
                : 'Appointments will appear here once they are created.',

            textAlign: TextAlign.center,

            style: TextStyle(
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,

              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 70,
              height: 70,

              decoration: BoxDecoration(
                color: AppTheme.statusCancelled.withValues(
                  alpha: isDark ? 0.18 : 0.08,
                ),

                borderRadius: BorderRadius.circular(20),
              ),

              child: const Icon(
                Icons.error_outline_rounded,
                size: 38,
                color: AppTheme.statusCancelled,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'Unable to load appointments',

              style: TextStyle(
                color: isDark
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,

                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              error ?? 'Unknown error',

              textAlign: TextAlign.center,

              style: TextStyle(
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,

                fontSize: 14,
              ),
            ),

            const SizedBox(height: 22),

            FilledButton.icon(
              onPressed: _loadAppointments,

              icon: const Icon(Icons.refresh_rounded),

              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// INFO ITEM
// =================================================================

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final secondaryColor = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondaryLight;

    final primaryColor = isDark
        ? AppTheme.textPrimaryDark
        : AppTheme.textPrimaryLight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Icon(
          icon,
          size: 19,
          color: isDark ? AppTheme.accentCyan : AppTheme.primary,
        ),

        const SizedBox(width: 9),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style: TextStyle(
                  fontSize: 12,
                  color: secondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value.isEmpty ? '-' : value,

                maxLines: 2,
                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
