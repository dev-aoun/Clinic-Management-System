import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme.dart';

class AddDoctorScreen extends StatefulWidget {
  final String token;

  const AddDoctorScreen({super.key, required this.token});

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _specializationController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _feeController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _specializationController.dispose();
    _qualificationController.dispose();
    _feeController.dispose();

    super.dispose();
  }

  // ============================================================
  // SAVE DOCTOR
  // ============================================================

  Future<void> _saveDoctor() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final fee = double.tryParse(_feeController.text.trim());

    if (fee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid consultation fee.'),
          backgroundColor: AppTheme.statusCancelled,
        ),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ApiService.createDoctor(
        token: widget.token,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        specialization: _specializationController.text.trim(),
        qualification: _qualificationController.text.trim(),
        consultationFee: fee,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor added successfully.'),
          backgroundColor: AppTheme.statusCompleted,
        ),
      );

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
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      labelText: label,

      prefixIcon: Icon(icon),

      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.statusCancelled),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.statusCancelled, width: 2),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final textPrimary = isDark
        ? AppTheme.textPrimaryDark
        : AppTheme.textPrimaryLight;

    final textSecondary = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondaryLight;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        title: const Text('Add Doctor'),

        leading: IconButton(
          tooltip: 'Back',

          icon: const Icon(Icons.arrow_back_rounded),

          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),

            child: Container(
              width: double.infinity,

              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,

                borderRadius: BorderRadius.circular(22),

                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),

              child: Padding(
                padding: const EdgeInsets.all(28),

                child: Form(
                  key: _formKey,

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      // ==================================================
                      // CLINICAL HEADER
                      // ==================================================
                      buildClinicalHeader(
                        context,
                        title: 'New Doctor',
                        subtitle: 'Enter the doctor information below.',
                        icon: Icons.medical_services_outlined,
                      ),

                      const SizedBox(height: 28),

                      // ==================================================
                      // SECTION TITLE
                      // ==================================================
                      Text(
                        'Doctor Information',

                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Enter the doctor details and consultation information.',
                        style: TextStyle(color: textSecondary, fontSize: 14),
                      ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // DOCTOR NAME
                      // ==================================================
                      TextFormField(
                        controller: _nameController,

                        textCapitalization: TextCapitalization.words,

                        textInputAction: TextInputAction.next,

                        decoration: _inputDecoration(
                          label: 'Doctor Name',
                          icon: Icons.person_outline_rounded,
                        ),

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Doctor name is required';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // PHONE
                      // ==================================================
                      TextFormField(
                        controller: _phoneController,

                        keyboardType: TextInputType.phone,

                        textInputAction: TextInputAction.next,

                        decoration: _inputDecoration(
                          label: 'Phone',
                          icon: Icons.phone_outlined,
                        ),

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Phone is required';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // EMAIL
                      // ==================================================
                      TextFormField(
                        controller: _emailController,

                        keyboardType: TextInputType.emailAddress,

                        textInputAction: TextInputAction.next,

                        decoration: _inputDecoration(
                          label: 'Email',
                          icon: Icons.email_outlined,
                        ),

                        validator: (value) {
                          final email = value?.trim() ?? '';

                          if (email.isEmpty) {
                            return 'Email is required';
                          }

                          if (!email.contains('@')) {
                            return 'Enter a valid email';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // SPECIALIZATION
                      // ==================================================
                      TextFormField(
                        controller: _specializationController,

                        textInputAction: TextInputAction.next,

                        decoration: _inputDecoration(
                          label: 'Specialization',
                          icon: Icons.medical_information_outlined,
                        ),

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Specialization is required';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // QUALIFICATION
                      // ==================================================
                      TextFormField(
                        controller: _qualificationController,

                        textInputAction: TextInputAction.next,

                        decoration: _inputDecoration(
                          label: 'Qualification',
                          icon: Icons.school_outlined,
                        ),

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Qualification is required';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // CONSULTATION FEE
                      // ==================================================
                      TextFormField(
                        controller: _feeController,

                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),

                        textInputAction: TextInputAction.done,

                        decoration: _inputDecoration(
                          label: 'Consultation Fee',
                          icon: Icons.payments_outlined,
                        ).copyWith(prefixText: 'PKR '),

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Consultation fee is required';
                          }

                          if (double.tryParse(value.trim()) == null) {
                            return 'Enter a valid fee';
                          }

                          return null;
                        },

                        onFieldSubmitted: (_) => _saveDoctor(),
                      ),

                      const SizedBox(height: 28),

                      // ==================================================
                      // SAVE BUTTON
                      // ==================================================
                      SizedBox(
                        width: double.infinity,
                        height: 52,

                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _saveDoctor,

                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,

                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.person_add_alt_1_rounded),

                          label: Text(
                            _isSaving ? 'Saving Doctor...' : 'Save Doctor',

                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ==================================================
                      // HELPER TEXT
                      // ==================================================
                      Center(
                        child: Text(
                          'All doctor information will be saved to the clinic system.',

                          textAlign: TextAlign.center,

                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
