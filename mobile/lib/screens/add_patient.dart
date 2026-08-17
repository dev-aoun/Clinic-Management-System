import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

class AddPatientScreen extends StatefulWidget {
  final String token;

  const AddPatientScreen({super.key, required this.token});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();

  String _gender = 'Male';
  bool _isLoading = false;

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
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
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
  // SAVE PATIENT
  // ============================================================

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.createPatient(
        token: widget.token,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        gender: _gender,
        address: _addressController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient created successfully!'),
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
          _isLoading = false;
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
    String? hint,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      labelText: label,
      hintText: hint,

      prefixIcon: Icon(icon),

      filled: true,

      fillColor: isDark ? AppTheme.darkSurfaceMuted : AppTheme.lightSurface,

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.6),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.statusCancelled),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppTheme.statusCancelled,
          width: 1.6,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Patient'),

        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),

              child: Form(
                key: _formKey,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // ==================================================
                    // GLOBAL CLINICAL HEADER
                    // ==================================================
                    buildClinicalHeader(
                      context,

                      title: 'Add Patient',

                      subtitle: 'Register a new patient in your clinic.',

                      icon: Icons.person_add_alt_1_rounded,
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // INFORMATION CARD
                    // ==================================================
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),

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
                                      alpha: 0.10,
                                    ),

                                    borderRadius: BorderRadius.circular(12),
                                  ),

                                  child: const Icon(
                                    Icons.person_outline_rounded,

                                    color: AppTheme.primary,

                                    size: 22,
                                  ),
                                ),

                                const SizedBox(width: 14),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      Text(
                                        'Patient Information',

                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,

                                          fontSize: 19,

                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        'Enter the basic information for this patient.',

                                        style: TextStyle(
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? AppTheme.textSecondaryDark
                                              : AppTheme.textSecondaryLight,

                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
                                hint: 'e.g. Ali Khan',
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
                                hint: '03001234567',
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
                                hint: 'patient@example.com',
                                icon: Icons.email_outlined,
                              ),

                              validator: (value) {
                                final email = value?.trim() ?? '';

                                if (email.isEmpty) {
                                  return null;
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

                              onTap: _selectDate,

                              decoration: _inputDecoration(
                                label: 'Date of Birth',
                                hint: 'Select date',
                                icon: Icons.calendar_today_outlined,
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
                                icon: Icons.wc_outlined,
                              ),

                              items: const [
                                DropdownMenuItem(
                                  value: 'Male',
                                  child: Text('Male'),
                                ),

                                DropdownMenuItem(
                                  value: 'Female',
                                  child: Text('Female'),
                                ),

                                DropdownMenuItem(
                                  value: 'Other',
                                  child: Text('Other'),
                                ),
                              ],

                              onChanged: (value) {
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

                              textInputAction: TextInputAction.done,

                              decoration: _inputDecoration(
                                label: 'Address',
                                hint: 'Enter patient address',
                                icon: Icons.location_on_outlined,
                              ).copyWith(alignLabelWithHint: true),

                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter address';
                                }

                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // SAVE BUTTON
                    // ==================================================
                    SizedBox(
                      width: double.infinity,
                      height: 52,

                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _savePatient,

                        icon: _isLoading
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
                          _isLoading ? 'Saving Patient...' : 'Save Patient',

                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
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
