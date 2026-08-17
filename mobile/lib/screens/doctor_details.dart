import 'package:flutter/material.dart';

import '../theme.dart';
import 'edit_doctor.dart';
import '../services/api_service.dart';

class DoctorDetailsScreen extends StatelessWidget {
  final String token;
  final Map<String, dynamic> doctor;

  const DoctorDetailsScreen({
    super.key,
    required this.token,
    required this.doctor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final name = doctor['name']?.toString() ?? 'Unknown Doctor';
    final specialization = doctor['specialization']?.toString() ?? '-';
    final qualification = doctor['qualification']?.toString() ?? '-';
    final phone = doctor['phone']?.toString() ?? '-';
    final email = doctor['email']?.toString() ?? '-';
    final consultationFee = doctor['consultation_fee']?.toString() ?? '-';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Doctor Details'),
        actions: [
          IconButton(
            tooltip: 'Edit Doctor',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final updatedDoctor = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EditDoctorScreen(token: token, doctor: doctor),
                ),
              );

              if (updatedDoctor != null && context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DoctorDetailsScreen(
                      token: token,
                      doctor: Map<String, dynamic>.from(updatedDoctor),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======================================================
            // CLINICAL HEADER
            // ======================================================
            buildClinicalHeader(
              context,
              title: name,
              subtitle: specialization,
              icon: Icons.medical_services_rounded,
            ),

            const SizedBox(height: 28),

            // ======================================================
            // SECTION TITLE
            // ======================================================
            Text(
              'Doctor Information',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,
              ),
            ),

            const SizedBox(height: 16),

            // ======================================================
            // DOCTOR DETAILS
            // ======================================================
            buildDetailCard(
              context,
              icon: Icons.school_rounded,
              label: 'Qualification',
              value: qualification,
              iconAccent: AppTheme.accentBlue,
            ),

            buildDetailCard(
              context,
              icon: Icons.phone_rounded,
              label: 'Phone',
              value: phone,
              iconAccent: AppTheme.primary,
            ),

            buildDetailCard(
              context,
              icon: Icons.email_rounded,
              label: 'Email',
              value: email,
              iconAccent: AppTheme.accentCyan,
            ),

            buildDetailCard(
              context,
              icon: Icons.payments_rounded,
              label: 'Consultation Fee',
              value: consultationFee,
              iconAccent: AppTheme.statusCompleted,
            ),

            const SizedBox(height: 16),

            // ======================================================
            // ACTION BUTTONS
            // ======================================================
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final updatedDoctor = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditDoctorScreen(token: token, doctor: doctor),
                        ),
                      );

                      if (updatedDoctor != null && context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DoctorDetailsScreen(
                              token: token,
                              doctor: Map<String, dynamic>.from(updatedDoctor),
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Doctor'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.statusCancelled,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: const Text('Delete Doctor'),
                            content: Text(
                              'Are you sure you want to delete $name?',
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

                      if (confirmed != true) return;

                      final doctorId = int.tryParse(
                        doctor['id']?.toString() ?? '',
                      );

                      if (doctorId == null) {
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invalid doctor ID.'),
                            backgroundColor: AppTheme.statusCancelled,
                          ),
                        );

                        return;
                      }

                      try {
                        await ApiService.deleteDoctor(token, doctorId);

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Doctor deleted successfully.'),
                            backgroundColor: AppTheme.statusCompleted,
                          ),
                        );

                        Navigator.pop(context, true);
                      } catch (e) {
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceFirst('Exception: ', ''),
                            ),
                            backgroundColor: AppTheme.statusCancelled,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete Doctor'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
