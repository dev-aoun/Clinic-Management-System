import 'package:flutter/material.dart';

import '../theme.dart';
import '../services/api_service.dart';
import 'edit_appointment.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> appointment;

  const AppointmentDetailsScreen({
    super.key,
    required this.token,
    required this.appointment,
  });

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  String? _patientName;
  String? _doctorName;

  bool _loadingNames = true;
  bool _isDeleting = false;

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatTime(dynamic value) {
    if (value == null) return '-';

    final text = value.toString();

    if (text.length >= 5) {
      return text.substring(0, 5);
    }

    return text;
  }

  String _formatStatus(String status) {
    if (status.isEmpty) {
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.statusCompleted;

      case 'cancelled':
        return AppTheme.statusCancelled;

      case 'confirmed':
      case 'in progress':
      case 'in_progress':
        return AppTheme.statusInProgress;

      case 'scheduled':
        return AppTheme.statusScheduled;

      default:
        return AppTheme.textSecondaryLight;
    }
  }

  // ============================================================
  // LOAD PATIENT + DOCTOR NAMES
  // ============================================================

  Future<void> _loadNames() async {
    try {
      final results = await Future.wait([
        ApiService.getPatients(widget.token),
        ApiService.getDoctors(widget.token),
      ]);

      final patients = results[0];
      final doctors = results[1];

      final patientId = widget.appointment['patient_id']?.toString();
      final doctorId = widget.appointment['doctor_id']?.toString();

      String? patientName;
      String? doctorName;

      for (final patient in patients) {
        if (patient['id']?.toString() == patientId) {
          patientName = patient['name']?.toString();
          break;
        }
      }

      for (final doctor in doctors) {
        if (doctor['id']?.toString() == doctorId) {
          doctorName = doctor['name']?.toString();
          break;
        }
      }

      if (!mounted) return;

      setState(() {
        _patientName = patientName;
        _doctorName = doctorName;
        _loadingNames = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingNames = false;
      });
    }
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<void> _editAppointment() async {
    final updatedAppointment = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditAppointmentScreen(
          token: widget.token,
          appointment: widget.appointment,
        ),
      ),
    );

    if (!mounted) return;

    if (updatedAppointment != null) {
      Navigator.pop(context, updatedAppointment);
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteAppointment() async {
    final appointmentId = int.tryParse(
      widget.appointment['id']?.toString() ?? '',
    );

    if (appointmentId == null) {
      _showError('Invalid appointment ID.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          title: Text(
            'Delete Appointment?',
            style: TextStyle(
              color: isDark
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this appointment? '
            'This action cannot be undone.',
            style: TextStyle(
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.statusCancelled,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await ApiService.deleteAppointment(widget.token, appointmentId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment deleted successfully.'),
          backgroundColor: AppTheme.statusCompleted,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.statusCancelled,
      ),
    );
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark
        ? AppTheme.textPrimaryDark
        : AppTheme.textPrimaryLight;

    final appointment = widget.appointment;

    final id = appointment['id']?.toString() ?? '-';

    final patientId = appointment['patient_id']?.toString() ?? '-';

    final doctorId = appointment['doctor_id']?.toString() ?? '-';

    final date = appointment['appointment_date']?.toString() ?? '-';

    final time = _formatTime(appointment['appointment_time']);

    final status = appointment['status']?.toString() ?? 'scheduled';

    final notes = appointment['notes']?.toString() ?? '';

    final statusColor = _statusColor(status);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        title: const Text('Appointment Details'),

        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ==================================================
                // HEADER
                // ==================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),

                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accentBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),

                  child: Row(
                    children: [
                      Container(
                        width: 78,
                        height: 78,

                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),

                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),

                      const SizedBox(width: 20),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              'Appointment #$id',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 7,
                              ),

                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),

                              child: Text(
                                _formatStatus(status).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // TITLE
                // ==================================================
                Text(
                  'Appointment Information',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // PATIENT
                // ==================================================
                _InfoCard(
                  icon: Icons.person_outline_rounded,
                  title: 'Patient',
                  value: _loadingNames
                      ? 'Loading...'
                      : (_patientName ?? 'Patient #$patientId'),
                ),

                // ==================================================
                // DOCTOR
                // ==================================================
                _InfoCard(
                  icon: Icons.medical_services_outlined,
                  title: 'Doctor',
                  value: _loadingNames
                      ? 'Loading...'
                      : (_doctorName ?? 'Doctor #$doctorId'),
                ),

                // ==================================================
                // DATE
                // ==================================================
                _InfoCard(
                  icon: Icons.calendar_today_outlined,
                  title: 'Appointment Date',
                  value: date,
                ),

                // ==================================================
                // TIME
                // ==================================================
                _InfoCard(
                  icon: Icons.access_time_rounded,
                  title: 'Appointment Time',
                  value: time,
                ),

                // ==================================================
                // STATUS
                // ==================================================
                _InfoCard(
                  icon: Icons.flag_outlined,
                  title: 'Status',
                  value: _formatStatus(status),
                  valueColor: statusColor,
                  iconColor: statusColor,
                ),

                // ==================================================
                // NOTES
                // ==================================================
                if (notes.trim().isNotEmpty)
                  _InfoCard(
                    icon: Icons.notes_rounded,
                    title: 'Notes',
                    value: notes,
                  ),

                const SizedBox(height: 14),

                // ==================================================
                // ACTIONS
                // ==================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkSurface
                        : AppTheme.lightSurface,

                    borderRadius: BorderRadius.circular(20),

                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkBorder
                          : AppTheme.lightBorder,
                    ),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        'Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // EDIT
                      SizedBox(
                        width: double.infinity,
                        height: 54,

                        child: FilledButton.icon(
                          onPressed: _isDeleting ? null : _editAppointment,

                          icon: const Icon(Icons.edit_rounded),

                          label: const Text('Edit Appointment'),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // DELETE
                      SizedBox(
                        width: double.infinity,
                        height: 54,

                        child: OutlinedButton.icon(
                          onPressed: _isDeleting ? null : _deleteAppointment,

                          icon: _isDeleting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.statusCancelled,
                                  ),
                                )
                              : const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppTheme.statusCancelled,
                                ),

                          label: Text(
                            _isDeleting
                                ? 'Deleting Appointment...'
                                : 'Delete Appointment',
                            style: const TextStyle(
                              color: AppTheme.statusCancelled,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppTheme.statusCancelled,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // BACK BUTTON
                // ==================================================
                SizedBox(
                  width: double.infinity,
                  height: 52,

                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),

                    icon: const Icon(Icons.arrow_back_rounded),

                    label: const Text('Back to Appointments'),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =================================================================
// INFO CARD
// =================================================================

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;
  final Color? iconColor;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor = isDark
        ? AppTheme.textPrimaryDark
        : AppTheme.textPrimaryLight;

    final secondaryColor = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondaryLight;

    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;

    final effectiveIconColor = iconColor ?? AppTheme.primary;

    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: surfaceColor,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: borderColor),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 52,
            height: 52,

            decoration: BoxDecoration(
              color: effectiveIconColor.withValues(alpha: isDark ? 0.18 : 0.10),

              borderRadius: BorderRadius.circular(14),
            ),

            child: Icon(icon, color: effectiveIconColor, size: 25),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  value.isEmpty ? '-' : value,
                  style: TextStyle(
                    color: valueColor ?? primaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
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
