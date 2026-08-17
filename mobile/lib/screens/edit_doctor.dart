import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

class EditDoctorScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> doctor;

  const EditDoctorScreen({
    super.key,
    required this.token,
    required this.doctor,
  });

  @override
  State<EditDoctorScreen> createState() => _EditDoctorScreenState();
}

class _EditDoctorScreenState extends State<EditDoctorScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _specializationController;
  late final TextEditingController _qualificationController;
  late final TextEditingController _feeController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.doctor['name']?.toString() ?? '',
    );

    _phoneController = TextEditingController(
      text: widget.doctor['phone']?.toString() ?? '',
    );

    _emailController = TextEditingController(
      text: widget.doctor['email']?.toString() ?? '',
    );

    _specializationController = TextEditingController(
      text: widget.doctor['specialization']?.toString() ?? '',
    );

    _qualificationController = TextEditingController(
      text: widget.doctor['qualification']?.toString() ?? '',
    );

    _feeController = TextEditingController(
      text: widget.doctor['consultation_fee']?.toString() ?? '',
    );
  }

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
  // UPDATE DOCTOR
  // ============================================================

  Future<void> _updateDoctor() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final doctorId = int.tryParse(widget.doctor['id'].toString());

    if (doctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid doctor ID'),
          backgroundColor: AppTheme.statusCancelled,
        ),
      );
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
      final updatedDoctor =
          await ApiService.updateDoctor(widget.token, doctorId, {
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'email': _emailController.text.trim(),
            'specialization': _specializationController.text.trim(),
            'qualification': _qualificationController.text.trim(),
            'consultation_fee': fee,
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor updated successfully!'),
          backgroundColor: AppTheme.statusCompleted,
        ),
      );

      Navigator.pop(context, updatedDoctor);
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
    return InputDecoration(labelText: label, prefixIcon: Icon(icon));
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

    final textSecondary = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondaryLight;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Doctor'),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),

            child: Container(
              width: double.infinity,

              padding: const EdgeInsets.all(28),

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
                      title: 'Edit Doctor',
                      subtitle: 'Update the doctor information below.',
                      icon: Icons.medical_services_rounded,
                    ),

                    const SizedBox(height: 28),

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
                      'Update the doctor details and consultation information.',
                      style: TextStyle(color: textSecondary, fontSize: 14),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // NAME
                    // ==================================================
                    TextFormField(
                      controller: _nameController,
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
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }

                        if (!value.contains('@')) {
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
                      onFieldSubmitted: (_) => _updateDoctor(),
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // UPDATE BUTTON
                    // ==================================================
                    SizedBox(
                      width: double.infinity,
                      height: 52,

                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _updateDoctor,

                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded),

                        label: Text(
                          _isSaving ? 'Updating Doctor...' : 'Update Doctor',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
