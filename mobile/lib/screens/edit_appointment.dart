import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme.dart';

class EditAppointmentScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> appointment;

  const EditAppointmentScreen({
    super.key,
    required this.token,
    required this.appointment,
  });

  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _patients = [];
  List<dynamic> _doctors = [];

  int? _selectedPatientId;
  int? _selectedDoctorId;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String _status = 'scheduled';

  late final TextEditingController _notesController;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _notesController = TextEditingController(
      text: widget.appointment['notes']?.toString() ?? '',
    );

    _initializeAppointment();
    _loadData();
  }

  // ============================================================
  // INITIALIZE EXISTING APPOINTMENT
  // ============================================================

  void _initializeAppointment() {
    _selectedPatientId = int.tryParse(
      widget.appointment['patient_id']?.toString() ?? '',
    );

    _selectedDoctorId = int.tryParse(
      widget.appointment['doctor_id']?.toString() ?? '',
    );

    final dateText = widget.appointment['appointment_date']?.toString();

    if (dateText != null && dateText.isNotEmpty) {
      _selectedDate = DateTime.tryParse(dateText);
    }

    final timeText = widget.appointment['appointment_time']?.toString();

    if (timeText != null && timeText.isNotEmpty) {
      final parts = timeText.split(':');

      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);

        if (hour != null &&
            minute != null &&
            hour >= 0 &&
            hour <= 23 &&
            minute >= 0 &&
            minute <= 59) {
          _selectedTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }

    final existingStatus = widget.appointment['status']?.toString();

    const validStatuses = ['scheduled', 'confirmed', 'completed', 'cancelled'];

    if (existingStatus != null && validStatuses.contains(existingStatus)) {
      _status = existingStatus;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD PATIENTS + DOCTORS
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
  // DATE PICKER
  // ============================================================

  Future<void> _selectDate() async {
    final now = DateTime.now();

    DateTime initialDate = _selectedDate ?? now;

    if (initialDate.isBefore(DateTime(1900))) {
      initialDate = DateTime(1900);
    }

    if (initialDate.isAfter(DateTime(now.year + 2))) {
      initialDate = DateTime(now.year + 2);
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ============================================================
  // TIME PICKER
  // ============================================================

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  // ============================================================
  // API TIME FORMAT
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
  // UPDATE APPOINTMENT
  // ============================================================

  Future<void> _updateAppointment() async {
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

    final appointmentId = int.tryParse(
      widget.appointment['id']?.toString() ?? '',
    );

    if (appointmentId == null) {
      _showError('Invalid appointment ID.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedAppointment =
          await ApiService.updateAppointment(widget.token, appointmentId, {
            'patient_id': _selectedPatientId,
            'doctor_id': _selectedDoctorId,
            'appointment_date': _formatDate(_selectedDate!),
            'appointment_time': _formatTime(_selectedTime!),
            'status': _status,
            'notes': _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment updated successfully.'),
          backgroundColor: AppTheme.statusCompleted,
        ),
      );

      Navigator.pop(context, updatedAppointment);
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
  // ERROR MESSAGE
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

  InputDecoration _decoration(String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,

      fillColor: isDark ? AppTheme.darkSurfaceMuted : AppTheme.lightSurface,

      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? AppTheme.accentCyan : AppTheme.primary,
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
      appBar: AppBar(title: const Text('Edit Appointment')),
      body: _buildBody(),
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

    return SingleChildScrollView(
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
                // HEADER
                // ==================================================
                buildClinicalHeader(
                  context,
                  title: 'Edit Appointment',
                  subtitle: 'Update the appointment information below.',
                  icon: Icons.edit_calendar_rounded,
                ),

                const SizedBox(height: 28),

                // ==================================================
                // PATIENT
                // ==================================================
                DropdownButtonFormField<int>(
                  initialValue:
                      _patients.any(
                        (patient) =>
                            int.tryParse(patient['id']?.toString() ?? '') ==
                            _selectedPatientId,
                      )
                      ? _selectedPatientId
                      : null,

                  decoration: _decoration(
                    'Patient',
                    Icons.person_outline_rounded,
                  ),

                  items: _buildPatientItems(),

                  onChanged: (value) {
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
                  initialValue:
                      _doctors.any(
                        (doctor) =>
                            int.tryParse(doctor['id']?.toString() ?? '') ==
                            _selectedDoctorId,
                      )
                      ? _selectedDoctorId
                      : null,

                  decoration: _decoration(
                    'Doctor',
                    Icons.medical_services_outlined,
                  ),

                  items: _buildDoctorItems(),

                  onChanged: (value) {
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
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(14),

                  child: InputDecorator(
                    decoration: _decoration(
                      'Appointment Date',
                      Icons.calendar_today_outlined,
                    ),

                    child: Text(
                      _selectedDate == null
                          ? 'Select date'
                          : _formatDate(_selectedDate!),

                      style: TextStyle(
                        color: _selectedDate == null
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).colorScheme.onSurface,

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
                  onTap: _selectTime,
                  borderRadius: BorderRadius.circular(14),

                  child: InputDecorator(
                    decoration: _decoration(
                      'Appointment Time',
                      Icons.access_time_rounded,
                    ),

                    child: Text(
                      _selectedTime == null
                          ? 'Select time'
                          : _displayTime(_selectedTime!),

                      style: TextStyle(
                        color: _selectedTime == null
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).colorScheme.onSurface,

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

                  decoration: _decoration('Status', Icons.flag_outlined),

                  items: const [
                    DropdownMenuItem(
                      value: 'scheduled',
                      child: Text('Scheduled'),
                    ),
                    DropdownMenuItem(
                      value: 'confirmed',
                      child: Text('Confirmed'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Completed'),
                    ),
                    DropdownMenuItem(
                      value: 'cancelled',
                      child: Text('Cancelled'),
                    ),
                  ],

                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _status = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),

                // ==================================================
                // NOTES
                // ==================================================
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,

                  decoration: _decoration(
                    'Notes',
                    Icons.notes_rounded,
                  ).copyWith(alignLabelWithHint: true),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // SAVE BUTTON
                // ==================================================
                SizedBox(
                  width: double.infinity,
                  height: 54,

                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _updateAppointment,

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
                      _isSaving
                          ? 'Updating Appointment...'
                          : 'Update Appointment',
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

  // ============================================================
  // PATIENT DROPDOWN ITEMS
  // ============================================================

  List<DropdownMenuItem<int>> _buildPatientItems() {
    final items = <DropdownMenuItem<int>>[];

    for (final patient in _patients) {
      final id = int.tryParse(patient['id']?.toString() ?? '');

      if (id == null) {
        continue;
      }

      final name = patient['name']?.toString().trim();

      final displayName = name == null || name.isEmpty
          ? 'Unknown Patient'
          : name;

      items.add(
        DropdownMenuItem<int>(
          value: id,
          child: Text('$displayName (#$id)', overflow: TextOverflow.ellipsis),
        ),
      );
    }

    return items;
  }

  // ============================================================
  // DOCTOR DROPDOWN ITEMS
  // ============================================================

  List<DropdownMenuItem<int>> _buildDoctorItems() {
    final items = <DropdownMenuItem<int>>[];

    for (final doctor in _doctors) {
      final id = int.tryParse(doctor['id']?.toString() ?? '');

      if (id == null) {
        continue;
      }

      final name = doctor['name']?.toString().trim();

      final specialization = doctor['specialization']?.toString().trim() ?? '';

      final doctorName = name == null || name.isEmpty ? 'Unknown Doctor' : name;

      final label = specialization.isEmpty
          ? doctorName
          : '$doctorName — $specialization';

      items.add(
        DropdownMenuItem<int>(
          value: id,
          child: Text('$label (#$id)', overflow: TextOverflow.ellipsis),
        ),
      );
    }

    return items;
  }

  // ============================================================
  // ERROR UI
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppTheme.statusCancelled,
            ),

            const SizedBox(height: 16),

            Text(
              _error ?? 'Unable to load appointment data.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

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
