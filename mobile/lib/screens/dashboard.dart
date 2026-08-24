import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'patients.dart';
import 'add_patient.dart';
import 'doctors.dart';
import 'add_doctor.dart';
import 'appointments.dart';
import 'add_appointment.dart';
import '../main.dart';

class Dashboard extends StatefulWidget {
  final String token;
  final Future<void> Function(ThemeMode mode)? onThemeChanged;
  final ThemeMode currentThemeMode;

  const Dashboard({
    super.key,
    required this.token,
    this.onThemeChanged,
    this.currentThemeMode = ThemeMode.system,
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<dynamic> _patients = [];
  List<dynamic> _doctors = [];
  List<dynamic> _appointments = [];

  Map<String, String> _patientNameMap = {};
  Map<String, String> _doctorNameMap = {};
  Map<String, String> _doctorSpecMap = {};
  List<dynamic> _cachedTodayAppointments = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard({bool refreshing = false}) async {
    if (!mounted) return;

    setState(() {
      if (refreshing) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getPatients(widget.token),
        ApiService.getDoctors(widget.token),
        ApiService.getAppointments(widget.token),
      ]);

      if (!mounted) return;

      final fetchedPatients = List<dynamic>.from(results[0]);
      final fetchedDoctors = List<dynamic>.from(results[1]);
      final fetchedAppointments = List<dynamic>.from(results[2]);

      final pMap = <String, String>{};
      for (final p in fetchedPatients) {
        final id = p['id']?.toString();
        if (id != null) {
          pMap[id] = p['name']?.toString() ?? 'Unknown Patient';
        }
      }

      final dNameMap = <String, String>{};
      final dSpecMap = <String, String>{};
      for (final d in fetchedDoctors) {
        final id = d['id']?.toString();
        if (id != null) {
          dNameMap[id] = d['name']?.toString() ?? 'Unknown Doctor';
          dSpecMap[id] = d['specialization']?.toString() ?? '';
        }
      }

      final todayList = fetchedAppointments.where(_isToday).toList()
        ..sort((a, b) {
          final timeA = a['appointment_time']?.toString() ?? '';
          final timeB = b['appointment_time']?.toString() ?? '';
          return timeA.compareTo(timeB);
        });

      setState(() {
        _patients = fetchedPatients;
        _doctors = fetchedDoctors;
        _appointments = fetchedAppointments;

        _patientNameMap = pMap;
        _doctorNameMap = dNameMap;
        _doctorSpecMap = dSpecMap;
        _cachedTodayAppointments = todayList;

        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _refreshDashboard() async {
    await _loadDashboard(refreshing: true);
  }

  void _showThemeSelectorDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Select Display Theme',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeChoiceTile(
                dialogContext,
                title: 'Light Mode',
                icon: Icons.light_mode_rounded,
                mode: ThemeMode.light,
              ),
              const SizedBox(height: 6),
              _buildThemeChoiceTile(
                dialogContext,
                title: 'Dark Mode',
                icon: Icons.dark_mode_rounded,
                mode: ThemeMode.dark,
              ),
              const SizedBox(height: 6),
              _buildThemeChoiceTile(
                dialogContext,
                title: 'System Default',
                icon: Icons.brightness_auto_rounded,
                mode: ThemeMode.system,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeChoiceTile(
    BuildContext dialogContext, {
    required String title,
    required IconData icon,
    required ThemeMode mode,
  }) {
    final isSelected = widget.currentThemeMode == mode;
    final primary = Theme.of(dialogContext).colorScheme.primary;

    return Material(
      color: isSelected ? primary.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(dialogContext).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onThemeChanged?.call(mode);
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? primary : null, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? primary : null,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_rounded, color: primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  DateTime? _parseAppointmentDate(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  bool _isToday(dynamic appointment) {
    final rawDate = appointment['appointment_date'];
    if (rawDate == null) return false;

    final parsed = _parseAppointmentDate(rawDate);
    if (parsed == null) {
      final dateText = rawDate.toString();
      final today = DateTime.now();
      final todayText =
          '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';
      return dateText.startsWith(todayText);
    }

    final now = DateTime.now();
    return parsed.year == now.year &&
        parsed.month == now.month &&
        parsed.day == now.day;
  }

  String _formatTime(dynamic value) {
    if (value == null) return '--:--';
    final text = value.toString().trim();
    if (text.isEmpty) return '--:--';

    try {
      final parts = text.split(':');
      if (parts.length < 2) return text;

      int hour = int.parse(parts[0]);
      final minute = parts[1].padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';

      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour -= 12;
      }

      return '$hour:$minute $period';
    } catch (_) {
      return text;
    }
  }

  String _getPatientName(dynamic appointment) {
    final patientId = appointment['patient_id']?.toString();
    if (patientId == null) return 'Unknown Patient';
    return _patientNameMap[patientId] ?? 'Patient #$patientId';
  }

  String _getDoctorName(dynamic appointment) {
    final doctorId = appointment['doctor_id']?.toString();
    if (doctorId == null) return 'Unknown Doctor';
    return _doctorNameMap[doctorId] ?? 'Doctor #$doctorId';
  }

  String _getDoctorSpecialization(dynamic appointment) {
    final doctorId = appointment['doctor_id']?.toString();
    if (doctorId == null) return '';
    return _doctorSpecMap[doctorId] ?? '';
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase().trim()) {
      case 'scheduled':
        return 'Scheduled';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      case 'in_progress':
      case 'in progress':
        return 'In Progress';
      default:
        return status.isEmpty ? 'Unknown' : status;
    }
  }

  Color _statusColor(String status, Color primaryColor) {
    switch (status.toLowerCase().trim()) {
      case 'scheduled':
        return const Color(0xFF0284C7);
      case 'confirmed':
        return const Color(0xFF4F46E5);
      case 'completed':
        return const Color(0xFF16A34A);
      case 'cancelled':
      case 'canceled':
        return const Color(0xFFDC2626);
      case 'in_progress':
      case 'in progress':
        return const Color(0xFFD97706);
      default:
        return primaryColor;
    }
  }

  Color _statusBackground(String status, Color primaryColor, bool isDark) {
    final color = _statusColor(status, primaryColor);
    return color.withValues(alpha: isDark ? 0.16 : 0.09);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      drawer: _buildDrawer(context),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _isLoading
            ? _buildLoading(context)
            : _error != null
            ? _buildError(context)
            : RefreshIndicator(
                onRefresh: _refreshDashboard,
                color: theme.colorScheme.primary,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final isMobile = width < 650;
                    final isTablet = width >= 650 && width < 1100;
                    final horizontalPadding = isMobile
                        ? 16.0
                        : isTablet
                        ? 24.0
                        : 32.0;

                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        20,
                        horizontalPadding,
                        40,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1320),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ClinicalWelcomeBanner(
                                isMobile: isMobile,
                                patientCount: _patients.length,
                                appointmentCount:
                                    _cachedTodayAppointments.length,
                              ),
                              const SizedBox(height: 24),
                              _buildStatisticsGrid(width),
                              const SizedBox(height: 24),
                              _buildQuickActionsCard(isMobile),
                              const SizedBox(height: 24),
                              _buildScheduleSection(
                                context,
                                _cachedTodayAppointments,
                                isMobile,
                              ),
                              const SizedBox(height: 24),
                              _buildSystemOverviewCard(width),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1.5,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surface,
      toolbarHeight: 70,
      titleSpacing: 0,
      leading: Builder(
        builder: (innerContext) {
          return IconButton(
            tooltip: 'Open navigation',
            icon: Icon(Icons.menu_rounded, color: colors.primary),
            onPressed: () => Scaffold.of(innerContext).openDrawer(),
          );
        },
      ),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.primary.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_hospital_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CarePoint Medical',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Clinical Console',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.75,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh dashboard',
          onPressed: _isRefreshing ? null : () => _refreshDashboard(),
          icon: _isRefreshing
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: colors.primary,
                  ),
                )
              : const Icon(Icons.refresh_rounded),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: colors.primary,
                  child: const Icon(
                    Icons.person_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Admin',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsGrid(double width) {
    final items = [
      _StatData(
        title: 'Patients',
        value: '${_patients.length}',
        subtitle: 'Registered profiles',
        icon: Icons.people_alt_outlined,
        color: const Color(0xFF0284C7),
      ),
      _StatData(
        title: 'Doctors',
        value: '${_doctors.length}',
        subtitle: 'Medical specialists',
        icon: Icons.medical_services_outlined,
        color: const Color(0xFF0D9488),
      ),
      _StatData(
        title: 'Appointments',
        value: '${_appointments.length}',
        subtitle: 'Total consultations',
        icon: Icons.calendar_month_outlined,
        color: const Color(0xFF4F46E5),
      ),
      _StatData(
        title: 'Today',
        value: '${_cachedTodayAppointments.length}',
        subtitle: 'Scheduled today',
        icon: Icons.today_outlined,
        color: const Color(0xFFE11D48),
      ),
    ];

    if (width < 650) {
      return Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StatMetricCard(data: item),
              ),
            )
            .toList(),
      );
    }

    if (width < 1050) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _StatMetricCard(data: items[0])),
              const SizedBox(width: 14),
              Expanded(child: _StatMetricCard(data: items[1])),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _StatMetricCard(data: items[2])),
              const SizedBox(width: 14),
              Expanded(child: _StatMetricCard(data: items[3])),
            ],
          ),
        ],
      );
    }

    return Row(
      children: items.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _StatMetricCard(data: item),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActionsCard(bool isMobile) {
    return _ClinicalSectionContainer(
      title: 'Quick Operations',
      subtitle: 'Primary shortcuts for desk staff and clinicians',
      icon: Icons.bolt_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final buttonWidth = isMobile
              ? constraints.maxWidth
              : (constraints.maxWidth - 24) / 3;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: buttonWidth,
                child: _ActionTile(
                  icon: Icons.person_add_alt_1_rounded,
                  title: 'Register Patient',
                  subtitle: 'Create record',
                  accentColor: const Color(0xFF0284C7),
                  onPressed: _openAddPatient,
                ),
              ),
              SizedBox(
                width: buttonWidth,
                child: _ActionTile(
                  icon: Icons.medical_services_outlined,
                  title: 'Add Doctor',
                  subtitle: 'Onboard specialist',
                  accentColor: const Color(0xFF0D9488),
                  onPressed: _openAddDoctor,
                ),
              ),
              SizedBox(
                width: buttonWidth,
                child: _ActionTile(
                  icon: Icons.calendar_month_rounded,
                  title: 'Book Appointment',
                  subtitle: 'Schedule visit',
                  accentColor: const Color(0xFF6366F1),
                  onPressed: _openAddAppointment,
                ),
              ),
              SizedBox(
                width: buttonWidth,
                child: _ActionTile(
                  icon: Icons.people_outline_rounded,
                  title: 'View Patients',
                  subtitle: 'Browse index',
                  accentColor: const Color(0xFF06B6D4),
                  onPressed: _openPatients,
                ),
              ),
              SizedBox(
                width: buttonWidth,
                child: _ActionTile(
                  icon: Icons.medical_information_outlined,
                  title: 'View Doctors',
                  subtitle: 'Staff roster',
                  accentColor: const Color(0xFF10B981),
                  onPressed: _openDoctors,
                ),
              ),
              SizedBox(
                width: buttonWidth,
                child: _ActionTile(
                  icon: Icons.event_note_outlined,
                  title: 'View Appointments',
                  subtitle: 'Consultation log',
                  accentColor: const Color(0xFF8B5CF6),
                  onPressed: _openAppointments,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScheduleSection(
    BuildContext context,
    List<dynamic> appointments,
    bool isMobile,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return _ClinicalSectionContainer(
      title: "Today's Consultations",
      subtitle: 'Real-time patient schedule for the current date',
      icon: Icons.event_note_rounded,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${appointments.length} scheduled',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
      child: appointments.isEmpty
          ? _EmptyScheduleIllustration(onBookPressed: _openAddAppointment)
          : Column(
              children: [
                for (int i = 0; i < appointments.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _AppointmentRowCard(
                    patientName: _getPatientName(appointments[i]),
                    doctorName: _getDoctorName(appointments[i]),
                    specialization: _getDoctorSpecialization(appointments[i]),
                    time: _formatTime(appointments[i]['appointment_time']),
                    status: _statusLabel(
                      appointments[i]['status']?.toString() ?? 'scheduled',
                    ),
                    statusColor: _statusColor(
                      appointments[i]['status']?.toString() ?? 'scheduled',
                      primaryColor,
                    ),
                    statusBackground: _statusBackground(
                      appointments[i]['status']?.toString() ?? 'scheduled',
                      primaryColor,
                      isDark,
                    ),
                    isMobile: isMobile,
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildSystemOverviewCard(double width) {
    final items = [
      _OverviewMetric(
        icon: Icons.people_alt_outlined,
        title: 'Patient Directory',
        value: '${_patients.length} Registered',
        detail: 'Active medical charts',
        accentColor: const Color(0xFF0284C7),
      ),
      _OverviewMetric(
        icon: Icons.medical_services_outlined,
        title: 'Specialist Staff',
        value: '${_doctors.length} On Duty',
        detail: 'Covering active clinical shifts',
        accentColor: const Color(0xFF0D9488),
      ),
      _OverviewMetric(
        icon: Icons.calendar_today_outlined,
        title: 'Consultations',
        value: '${_appointments.length} Logged',
        detail: 'Lifetime appointments indexed',
        accentColor: const Color(0xFF6366F1),
      ),
    ];

    return _ClinicalSectionContainer(
      title: 'Clinic Capacity & Metrics',
      subtitle: 'Aggregated totals across database records',
      icon: Icons.analytics_outlined,
      child: width < 750
          ? Column(
              children: items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: item,
                    ),
                  )
                  .toList(),
            )
          : Row(
              children: items.map((item) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: item,
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Semantics(
        label: 'Loading dashboard clinical data',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading clinical records...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Synchronizing active patients, doctors, and schedules',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: Color(0xFFDC2626),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Connection Problem',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error ??
                      'Unable to connect to the clinic management service.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.75,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () => _loadDashboard(),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text('Try Again'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CarePoint Clinical',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Staff Administration',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.75,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _DrawerNavigationItem(
              icon: Icons.dashboard_rounded,
              title: 'Dashboard Overview',
              selected: true,
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
            _DrawerNavigationItem(
              icon: Icons.people_outline_rounded,
              title: 'Patient Directory',
              onTap: _openPatientsFromDrawer,
            ),
            _DrawerNavigationItem(
              icon: Icons.medical_services_outlined,
              title: 'Physicians & Specialists',
              onTap: _openDoctorsFromDrawer,
            ),
            _DrawerNavigationItem(
              icon: Icons.calendar_month_outlined,
              title: 'Appointment Ledger',
              onTap: _openAppointmentsFromDrawer,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(),
            ),
            _DrawerNavigationItem(
              icon: Icons.palette_outlined,
              title: 'Appearance & Theme',
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                _showThemeSelectorDialog();
              },
            ),
            const Spacer(),
            Divider(
              color: theme.dividerColor.withValues(alpha: 0.7),
              height: 1,
            ),
            _DrawerNavigationItem(
              icon: Icons.logout_rounded,
              title: 'End Session',
              danger: true,
              onTap: _logout,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddPatient() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddPatientScreen(token: widget.token)),
    );
    if (!mounted) return;
    if (result == true) {
      await _loadDashboard(refreshing: true);
    }
  }

  Future<void> _openAddDoctor() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddDoctorScreen(token: widget.token)),
    );
    if (!mounted) return;
    if (result == true) {
      await _loadDashboard(refreshing: true);
    }
  }

  Future<void> _openAddAppointment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAppointmentScreen(token: widget.token),
      ),
    );
    if (!mounted) return;
    if (result == true) {
      await _loadDashboard(refreshing: true);
    }
  }

  void _openPatients() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PatientsScreen(token: widget.token)),
    );
  }

  void _openDoctors() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DoctorsScreen(token: widget.token)),
    );
  }

  void _openAppointments() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentsScreen(token: widget.token),
      ),
    );
  }

  void _openPatientsFromDrawer() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    _openPatients();
  }

  void _openDoctorsFromDrawer() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    _openDoctors();
  }

  void _openAppointmentsFromDrawer() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    _openAppointments();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          onThemeChanged: widget.onThemeChanged,
          currentThemeMode: widget.currentThemeMode,
        ),
      ),
      (route) => false,
    );
  }
}

class _ClinicalWelcomeBanner extends StatefulWidget {
  final bool isMobile;
  final int patientCount;
  final int appointmentCount;

  const _ClinicalWelcomeBanner({
    required this.isMobile,
    required this.patientCount,
    required this.appointmentCount,
  });

  @override
  State<_ClinicalWelcomeBanner> createState() => _ClinicalWelcomeBannerState();
}

class _ClinicalWelcomeBannerState extends State<_ClinicalWelcomeBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning, Doctor';
    if (hour < 17) return 'Good Afternoon, Doctor';
    return 'Good Evening, Dear Admin';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0F3A5D), Color(0xFF0D5F7A), Color(0xFF0A7E8C)]
              : const [Color(0xFF0284C7), Color(0xFF06B6D4), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF06B6D4,
            ).withValues(alpha: isDark ? 0.25 : 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 200 + (_pulseController.value * 25),
                      height: 200 + (_pulseController.value * 25),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(
                          alpha: 0.10 + (_pulseController.value * 0.05),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: 40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.18),
                ),
              ),
            ),
            Positioned(
              right: widget.isMobile ? -15 : 20,
              bottom: widget.isMobile ? -20 : -10,
              child: Icon(
                Icons.favorite_rounded,
                size: widget.isMobile ? 120 : 160,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(widget.isMobile ? 22 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('✨', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 6),
                            Text(
                              'CarePoint Live Hub',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4ADE80),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'System Online',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getGreeting()} 👋',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: widget.isMobile ? 14 : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Clinic Operations',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: widget.isMobile ? 24 : 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!widget.isMobile)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            '🩺',
                            style: TextStyle(fontSize: 32),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Real-time overview of patient check-ins, active rosters, and consultations.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildMiniBadge(
                        emoji: '👥',
                        label: '${widget.patientCount} Patients',
                      ),
                      _buildMiniBadge(
                        emoji: '📅',
                        label: '${widget.appointmentCount} Today',
                      ),
                      _buildMiniBadge(emoji: '🏥', label: 'Desk Ready'),
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

  Widget _buildMiniBadge({required String emoji, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalSectionContainer extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _ClinicalSectionContainer({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.2 : 0.02,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: colors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _StatMetricCard extends StatelessWidget {
  final _StatData data;

  const _StatMetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.15 : 0.02,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onPressed;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      accentColor.withValues(alpha: 0.12),
                      accentColor.withValues(alpha: 0.04),
                    ]
                  : [accentColor.withValues(alpha: 0.08), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: isDark ? 0.10 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, size: 22, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.65)
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: isDark ? 0.20 : 0.10),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentRowCard extends StatelessWidget {
  final String patientName;
  final String doctorName;
  final String specialization;
  final String time;
  final String status;
  final Color statusColor;
  final Color statusBackground;
  final bool isMobile;

  const _AppointmentRowCard({
    required this.patientName,
    required this.doctorName,
    required this.specialization,
    required this.time,
    required this.status,
    required this.statusColor,
    required this.statusBackground,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = patientName.isEmpty
        ? 'P'
        : patientName.substring(0, 1).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildAvatar(theme, initial),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDetails(theme)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildTimeBadge(theme),
                    const Spacer(),
                    _buildStatusBadge(),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                _buildAvatar(theme, initial),
                const SizedBox(width: 14),
                Expanded(child: _buildDetails(theme)),
                const SizedBox(width: 16),
                _buildTimeBadge(theme),
                const SizedBox(width: 14),
                _buildStatusBadge(),
              ],
            ),
    );
  }

  Widget _buildAvatar(ThemeData theme, String initial) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          patientName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 13,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                specialization.isNotEmpty
                    ? '$doctorName ($specialization)'
                    : doctorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 5),
          Text(
            time,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: statusBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyScheduleIllustration extends StatelessWidget {
  final VoidCallback onBookPressed;

  const _EmptyScheduleIllustration({required this.onBookPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.5)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.25),
                  const Color(0xFF0284C7).withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              size: 30,
              color: Color(0xFF38BDF8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Consultations Scheduled Today',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              'The consultation queue for today is empty. You can register walk-ins or reserve upcoming slots.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(
                  alpha: 0.75,
                ),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: onBookPressed,
              icon: const Icon(
                Icons.add_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: const Text(
                'Book Appointment',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final Color accentColor;

  const _OverviewMetric({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  accentColor.withValues(alpha: 0.12),
                  accentColor.withValues(alpha: 0.03),
                ]
              : [accentColor.withValues(alpha: 0.08), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.35 : 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor, accentColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerNavigationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool selected;
  final bool danger;

  const _DrawerNavigationItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final color = danger
        ? const Color(0xFFDC2626)
        : selected
        ? colors.primary
        : theme.textTheme.bodyMedium?.color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: selected ? colors.primary.withValues(alpha: 0.08) : null,
        leading: Icon(icon, color: color, size: 20),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: selected || danger ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }
}

class _StatData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}


