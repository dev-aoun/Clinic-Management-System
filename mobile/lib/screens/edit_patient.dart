import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

class EditPatientScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> patient;

  const EditPatientScreen({
    super.key,
    required this.token,
    required this.patient,
  });

  @override
  State<EditPatientScreen> createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends State<EditPatientScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _dobController;
  late final TextEditingController _addressController;

  String _gender = 'Male';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.patient['name']?.toString() ?? '',
    );

    _phoneController = TextEditingController(
      text: widget.patient['phone']?.toString() ?? '',
    );

    _emailController = TextEditingController(
      text: widget.patient['email']?.toString() ?? '',
    );

    _dobController = TextEditingController(
      text: widget.patient['date_of_birth']?.toString() ?? '',
    );

    _addressController = TextEditingController(
      text: widget.patient['address']?.toString() ?? '',
    );

    final existingGender = widget.patient['gender']?.toString();

    if (existingGender == 'Male' ||
        existingGender == 'Female' ||
        existingGender == 'Other') {
      _gender = existingGender!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _addressController.dispose();

    super.dispose();
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDate() async {
    final now = DateTime.now();

    DateTime initialDate = DateTime(now.year - 18, now.month, now.day);

    final existingDate = DateTime.tryParse(_dobController.text.trim());

    if (existingDate != null) {
      initialDate = existingDate;

      if (initialDate.isAfter(now)) {
        initialDate = now;
      }
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select Date of Birth',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    final month = pickedDate.month.toString().padLeft(2, '0');
    final day = pickedDate.day.toString().padLeft(2, '0');

    setState(() {
      _dobController.text = '${pickedDate.year}-$month-$day';
    });
  }

  // ============================================================
  // UPDATE PATIENT
  // ============================================================

  Future<void> _updatePatient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final patientId = int.tryParse(widget.patient['id']?.toString() ?? '');

    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid patient ID'),
          backgroundColor: AppTheme.statusCancelled,
        ),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedPatient =
          await ApiService.updatePatient(widget.token, patientId, {
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'email': _emailController.text.trim(),
            'date_of_birth': _dobController.text.trim(),
            'gender': _gender,
            'address': _addressController.text.trim(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient updated successfully!'),
          backgroundColor: AppTheme.statusCompleted,
        ),
      );

      Navigator.pop(context, updatedPatient);
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
    );
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
        title: const Text('Edit Patient'),

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
                      // HEADER
                      // ==================================================
                      buildClinicalHeader(
                        context,
                        title: 'Edit Patient',
                        subtitle: 'Update the patient information below.',
                        icon: Icons.edit_rounded,
                      ),

                      const SizedBox(height: 28),

                      Text(
                        'Patient Information',

                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Make the required changes and save the updated information.',

                        style: TextStyle(color: textSecondary, fontSize: 14),
                      ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // NAME
                      // ==================================================
                      TextFormField(
                        controller: _nameController,

                        textCapitalization: TextCapitalization.words,

                        textInputAction: TextInputAction.next,

                        decoration: _inputDecoration(
                          label: 'Full Name',
                          icon: Icons.person_outline_rounded,
                        ),

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter patient name';
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
                            return 'Please enter phone number';
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
                            return 'Please enter email';
                          }

                          if (!email.contains('@')) {
                            return 'Enter a valid email';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // DATE OF BIRTH
                      // ==================================================
                      TextFormField(
                        controller: _dobController,

                        readOnly: true,

                        onTap: _isSaving ? null : _selectDate,

                        decoration:
                            _inputDecoration(
                              label: 'Date of Birth',
                              icon: Icons.calendar_today_outlined,
                            ).copyWith(
                              suffixIcon: const Icon(
                                Icons.calendar_month_rounded,
                              ),
                            ),

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please select date of birth';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // GENDER
                      // ==================================================
                      DropdownButtonFormField<String>(
                        initialValue: _gender,

                        decoration: _inputDecoration(
                          label: 'Gender',
                          icon: Icons.people_outline_rounded,
                        ),

                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text('Female'),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                        ],

                        onChanged: _isSaving
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }

                                setState(() {
                                  _gender = value;
                                });
                              },
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // ADDRESS
                      // ==================================================
                      TextFormField(
                        controller: _addressController,

                        maxLines: 3,

                        textCapitalization: TextCapitalization.sentences,

                        decoration: _inputDecoration(
                          label: 'Address',
                          icon: Icons.location_on_outlined,
                        ).copyWith(alignLabelWithHint: true),

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter address';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 28),

                      // ==================================================
                      // UPDATE BUTTON
                      // ==================================================
                      SizedBox(
                        width: double.infinity,
                        height: 52,

                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _updatePatient,

                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,

                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),

                          label: Text(
                            _isSaving ? 'Updating...' : 'Update Patient',
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
      ),
    );
  }
}
