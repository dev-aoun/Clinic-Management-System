import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme.dart';

class AddAppointmentScreen extends StatefulWidget {
  final String token;

  const AddAppointmentScreen({super.key, required this.token});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _patients = [];
  List<dynamic> _doctors = [];

  int? _selectedPatientId;
  int? _selectedDoctorId;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String _status = 'scheduled';

  final _notesController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        ApiService.getPatients(widget.token),
        ApiService.getDoctors(widget.token),
      ]);

      if (!mounted) return;

      setState(() {
        _patients = results[0];
        _doctors = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // DATE
  // ============================================================

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      helpText: 'Select Appointment Date',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = picked;
    });
  }

  // ============================================================
  // TIME
  // ============================================================

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      helpText: 'Select Appointment Time',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedTime = picked;
    });
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  // ============================================================
  // FORMAT API TIME
  // ============================================================

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute:00';
  }

  // ============================================================
  // DISPLAY TIME
  // ============================================================

  String _displayTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  // ============================================================
  // SAVE APPOINTMENT
  // ============================================================

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPatientId == null) {
      _showError('Please select a patient.');
      return;
    }

    if (_selectedDoctorId == null) {
      _showError('Please select a doctor.');
      return;
    }

    if (_selectedDate == null) {
      _showError('Please select an appointment date.');
      return;
    }

    if (_selectedTime == null) {
      _showError('Please select an appointment time.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ApiService.createAppointment(
        token: widget.token,
        patientId: _selectedPatientId!,
        doctorId: _selectedDoctorId!,
        appointmentDate: _formatDate(_selectedDate!),
        appointmentTime: _formatTime(_selectedTime!),
        status: _status,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment created successfully.'),
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
          _isSaving = false;
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
  // INPUT DECORATION
  // ============================================================

  InputDecoration _decoration({required String label, required IconData icon}) {
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

      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // ============================================================
  // SAFE TEXT
  // ============================================================

  Widget _dropdownText(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,

      appBar: AppBar(
        title: const Text('Add Appointment'),

        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
      ),

      body: SafeArea(child: _buildBody()),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError();
    }

    if (_patients.isEmpty || _doctors.isEmpty) {
      return _buildEmptyData();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        final horizontalPadding = isSmallScreen ? 16.0 : 24.0;

        final cardPadding = isSmallScreen ? 18.0 : 28.0;

        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            30,
          ),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),

              child: Container(
                width: double.infinity,

                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkSurface
                      : AppTheme.lightSurface,

                  borderRadius: BorderRadius.circular(22),

                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkBorder
                        : AppTheme.lightBorder,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.20
                            : 0.04,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),

                child: Padding(
                  padding: EdgeInsets.all(cardPadding),

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
                          title: 'New Appointment',
                          subtitle: 'Schedule an appointment for a patient.',
                          icon: Icons.calendar_month_rounded,
                        ),

                        const SizedBox(height: 28),

                        Text(
                          'Appointment Information',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.textPrimaryDark
                                : AppTheme.textPrimaryLight,
                            fontSize: isSmallScreen ? 20 : 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Select the patient, doctor, date, and time.',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ==================================================
                        // PATIENT
                        // ==================================================
                        DropdownButtonFormField<int>(
                          initialValue: _selectedPatientId,

                          isExpanded: true,

                          decoration: _decoration(
                            label: 'Patient',
                            icon: Icons.person_outline_rounded,
                          ),

                          items: _patients
                              .where(
                                (patient) =>
                                    int.tryParse(
                                      patient['id']?.toString() ?? '',
                                    ) !=
                                    null,
                              )
                              .map<DropdownMenuItem<int>>((patient) {
                                final id = int.parse(patient['id'].toString());

                                final name =
                                    patient['name']?.toString() ??
                                    'Unknown Patient';

                                return DropdownMenuItem<int>(
                                  value: id,
                                  child: _dropdownText('$name (#$id)'),
                                );
                              })
                              .toList(),

                          onChanged: _isSaving
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedPatientId = value;
                                  });
                                },

                          validator: (value) {
                            if (value == null) {
                              return 'Please select a patient';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // DOCTOR
                        // ==================================================
                        DropdownButtonFormField<int>(
                          initialValue: _selectedDoctorId,

                          // IMPORTANT:
                          // This prevents the long doctor name /
                          // specialization from causing horizontal
                          // RenderFlex overflow on mobile.
                          isExpanded: true,

                          decoration: _decoration(
                            label: 'Doctor',
                            icon: Icons.medical_services_outlined,
                          ),

                          items: _doctors
                              .where(
                                (doctor) =>
                                    int.tryParse(
                                      doctor['id']?.toString() ?? '',
                                    ) !=
                                    null,
                              )
                              .map<DropdownMenuItem<int>>((doctor) {
                                final id = int.parse(doctor['id'].toString());

                                final name =
                                    doctor['name']?.toString() ??
                                    'Unknown Doctor';

                                final specialization =
                                    doctor['specialization']
                                        ?.toString()
                                        .trim() ??
                                    '';

                                final label = specialization.isEmpty
                                    ? '$name (#$id)'
                                    : '$name — '
                                          '$specialization (#$id)';

                                return DropdownMenuItem<int>(
                                  value: id,
                                  child: _dropdownText(label),
                                );
                              })
                              .toList(),

                          onChanged: _isSaving
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedDoctorId = value;
                                  });
                                },

                          validator: (value) {
                            if (value == null) {
                              return 'Please select a doctor';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // DATE
                        // ==================================================
                        InkWell(
                          onTap: _isSaving ? null : _selectDate,

                          borderRadius: BorderRadius.circular(14),

                          child: InputDecorator(
                            decoration:
                                _decoration(
                                  label: 'Appointment Date',
                                  icon: Icons.calendar_today_outlined,
                                ).copyWith(
                                  suffixIcon: const Icon(
                                    Icons.calendar_month_rounded,
                                  ),
                                ),

                            child: Text(
                              _selectedDate == null
                                  ? 'Select date'
                                  : _formatDate(_selectedDate!),

                              maxLines: 1,

                              overflow: TextOverflow.ellipsis,

                              style: TextStyle(
                                color: _selectedDate == null
                                    ? (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppTheme.textSecondaryDark
                                          : AppTheme.textSecondaryLight)
                                    : (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppTheme.textPrimaryDark
                                          : AppTheme.textPrimaryLight),

                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // TIME
                        // ==================================================
                        InkWell(
                          onTap: _isSaving ? null : _selectTime,

                          borderRadius: BorderRadius.circular(14),

                          child: InputDecorator(
                            decoration:
                                _decoration(
                                  label: 'Appointment Time',
                                  icon: Icons.access_time_rounded,
                                ).copyWith(
                                  suffixIcon: const Icon(
                                    Icons.schedule_rounded,
                                  ),
                                ),

                            child: Text(
                              _selectedTime == null
                                  ? 'Select time'
                                  : _displayTime(_selectedTime!),

                              maxLines: 1,

                              overflow: TextOverflow.ellipsis,

                              style: TextStyle(
                                color: _selectedTime == null
                                    ? (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppTheme.textSecondaryDark
                                          : AppTheme.textSecondaryLight)
                                    : (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppTheme.textPrimaryDark
                                          : AppTheme.textPrimaryLight),

                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // STATUS
                        // ==================================================
                        DropdownButtonFormField<String>(
                          initialValue: _status,

                          isExpanded: true,

                          decoration: _decoration(
                            label: 'Status',
                            icon: Icons.flag_outlined,
                          ),

                          items: const [
                            DropdownMenuItem(
                              value: 'scheduled',
                              child: Text(
                                'Scheduled',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'confirmed',
                              child: Text(
                                'Confirmed',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'completed',
                              child: Text(
                                'Completed',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'cancelled',
                              child: Text(
                                'Cancelled',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],

                          onChanged: _isSaving
                              ? null
                              : (value) {
                                  if (value == null) {
                                    return;
                                  }

                                  setState(() {
                                    _status = value;
                                  });
                                },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // NOTES
                        // ==================================================
                        TextFormField(
                          controller: _notesController,

                          enabled: !_isSaving,

                          maxLines: 4,

                          minLines: 4,

                          textCapitalization: TextCapitalization.sentences,

                          decoration: _decoration(
                            label: 'Notes',
                            icon: Icons.notes_rounded,
                          ).copyWith(alignLabelWithHint: true),
                        ),

                        const SizedBox(height: 28),

                        // ==================================================
                        // SAVE BUTTON
                        // ==================================================
                        SizedBox(
                          width: double.infinity,
                          height: 52,

                          child: FilledButton.icon(
                            onPressed: _isSaving ? null : _saveAppointment,

                            icon: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,

                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.event_available_rounded),

                            label: Text(
                              _isSaving
                                  ? 'Saving Appointment...'
                                  : 'Save Appointment',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
      },
    );
  }

  // ============================================================
  // EMPTY DATA
  // ============================================================

  Widget _buildEmptyData() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = _patients.isEmpty
        ? 'No patients available'
        : 'No doctors available';

    final message = _patients.isEmpty
        ? 'Please add at least one patient before creating an appointment.'
        : 'Please add at least one doctor before creating an appointment.';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 70,
              height: 70,

              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: isDark ? 0.18 : 0.08),

                borderRadius: BorderRadius.circular(20),
              ),

              child: Icon(
                Icons.calendar_month_outlined,
                size: 36,
                color: isDark ? AppTheme.accentCyan : AppTheme.primary,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              title,

              textAlign: TextAlign.center,

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
              message,

              textAlign: TextAlign.center,

              style: TextStyle(
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 22),

            OutlinedButton.icon(
              onPressed: _loadData,

              icon: const Icon(Icons.refresh_rounded),

              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
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
              'Unable to load appointment data',

              textAlign: TextAlign.center,

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
              _error ?? 'Unknown error',

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
              onPressed: _loadData,

              icon: const Icon(Icons.refresh_rounded),

              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
