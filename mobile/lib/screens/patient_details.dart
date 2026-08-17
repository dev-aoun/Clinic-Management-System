import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme.dart';
import 'edit_patient.dart';

class PatientDetailsScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> patient;

  const PatientDetailsScreen({
    super.key,
    required this.token,
    required this.patient,
  });

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  late Map<String, dynamic> _patient;

  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();

    _patient = Map<String, dynamic>.from(widget.patient);
  }

  // ============================================================
  // VALUE HELPER
  // ============================================================

  String _value(String key) {
    final value = _patient[key]?.toString().trim();

    if (value == null || value.isEmpty || value == 'null') {
      return '--';
    }

    return value;
  }

  // ============================================================
  // EDIT PATIENT
  // ============================================================

  Future<void> _editPatient() async {
    if (_isDeleting) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditPatientScreen(token: widget.token, patient: _patient),
      ),
    );

    if (!mounted) return;

    if (result is Map<String, dynamic>) {
      setState(() {
        _patient = Map<String, dynamic>.from(result);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient updated successfully.'),
          backgroundColor: AppTheme.statusCompleted,
        ),
      );
    }
  }

  // ============================================================
  // DELETE PATIENT
  // ============================================================

  Future<void> _deletePatient() async {
    if (_isDeleting) return;

    final patientId = int.tryParse(_patient['id']?.toString() ?? '');

    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid patient ID.'),
          backgroundColor: AppTheme.statusCancelled,
        ),
      );

      return;
    }

    final patientName = _patient['name']?.toString().trim().isNotEmpty == true
        ? _patient['name'].toString()
        : 'this patient';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Patient?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),

          content: Text(
            'Are you sure you want to permanently delete '
            '$patientName?\n\n'
            'This action cannot be undone.',
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
      await ApiService.deletePatient(widget.token, patientId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient deleted successfully.'),
          backgroundColor: AppTheme.statusCompleted,
        ),
      );

      // Tell the Patients screen that this patient was deleted.
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.statusCancelled,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final name = _value('name');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        title: const Text('Patient Details'),

        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),

          onPressed: _isDeleting ? null : () => Navigator.pop(context),
        ),

        actions: [
          IconButton(
            tooltip: 'Edit patient',
            icon: const Icon(Icons.edit_outlined),

            onPressed: _isDeleting ? null : _editPatient,
          ),

          const SizedBox(width: 8),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.all(24),

        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ============================================================
                // HEADER
                // ============================================================
                buildClinicalHeader(
                  context,
                  title: name,
                  subtitle: 'Patient ID: ${_value('id')}',
                  icon: Icons.person_outline_rounded,
                ),

                const SizedBox(height: 24),

                // ============================================================
                // PATIENT INFORMATION
                // ============================================================
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,

                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(
                                  alpha: isDark ? 0.18 : 0.08,
                                ),

                                borderRadius: BorderRadius.circular(12),
                              ),

                              child: Icon(
                                Icons.person_outline_rounded,

                                color: isDark
                                    ? AppTheme.accentCyan
                                    : AppTheme.primary,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Text(
                                    'Patient Information',

                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),

                                  const SizedBox(height: 3),

                                  Text(
                                    'Personal and contact information',

                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // PHONE
                        buildDetailCard(
                          context,
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: _value('phone'),
                          iconAccent: AppTheme.primary,
                        ),

                        // EMAIL
                        buildDetailCard(
                          context,
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: _value('email'),
                          iconAccent: AppTheme.accentBlue,
                        ),

                        // DATE OF BIRTH
                        buildDetailCard(
                          context,
                          icon: Icons.calendar_today_outlined,
                          label: 'Date of Birth',
                          value: _value('date_of_birth'),
                          iconAccent: AppTheme.accentCyan,
                        ),

                        // GENDER
                        buildDetailCard(
                          context,
                          icon: Icons.wc_outlined,
                          label: 'Gender',
                          value: _value('gender'),
                          iconAccent: AppTheme.primary,
                        ),

                        // ADDRESS
                        buildDetailCard(
                          context,
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: _value('address'),
                          iconAccent: AppTheme.accentBlue,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ============================================================
                // EDIT BUTTON
                // ============================================================
                SizedBox(
                  width: double.infinity,
                  height: 52,

                  child: FilledButton.icon(
                    onPressed: _isDeleting ? null : _editPatient,

                    icon: const Icon(Icons.edit_outlined),

                    label: const Text(
                      'Edit Patient',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ============================================================
                // DELETE BUTTON
                // ============================================================
                SizedBox(
                  width: double.infinity,
                  height: 52,

                  child: FilledButton.icon(
                    onPressed: _isDeleting ? null : _deletePatient,

                    icon: _isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,

                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.delete_outline_rounded),

                    label: Text(
                      _isDeleting ? 'Deleting Patient...' : 'Delete Patient',

                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),

                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.statusCancelled,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ============================================================
                // BACK BUTTON
                // ============================================================
                SizedBox(
                  width: double.infinity,
                  height: 52,

                  child: OutlinedButton.icon(
                    onPressed: _isDeleting
                        ? null
                        : () => Navigator.pop(context),

                    icon: const Icon(Icons.arrow_back_rounded),

                    label: const Text(
                      'Back to Patients',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ============================================================
                // DELETE WARNING
                // ============================================================
                Center(
                  child: Text(
                    'Deleting a patient is permanent and cannot be undone.',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,

                      fontSize: 12,
                    ),
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
