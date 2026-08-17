import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme.dart';
import 'patient_details.dart';

class PatientsScreen extends StatefulWidget {
  final String token;

  const PatientsScreen({super.key, required this.token});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  List<dynamic> _patients = [];
  List<dynamic> _filteredPatients = [];

  bool _isLoading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _loadPatients();
    _searchController.addListener(_filterPatients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD PATIENTS
  // ============================================================

  Future<void> _loadPatients() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final patients = await ApiService.getPatients(widget.token);

      if (!mounted) return;

      setState(() {
        _patients = patients;
        _filteredPatients = patients;
        _isLoading = false;
      });

      _filterPatients();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _filterPatients() {
    final query = _searchController.text.trim().toLowerCase();

    if (!mounted) return;

    setState(() {
      if (query.isEmpty) {
        _filteredPatients = List<dynamic>.from(_patients);
        return;
      }

      _filteredPatients = _patients.where((patient) {
        final name = patient['name']?.toString().toLowerCase() ?? '';

        final phone = patient['phone']?.toString().toLowerCase() ?? '';

        final email = patient['email']?.toString().toLowerCase() ?? '';

        return name.contains(query) ||
            phone.contains(query) ||
            email.contains(query);
      }).toList();
    });
  }

  // ============================================================
  // OPEN PATIENT DETAILS
  // ============================================================

  Future<void> _openPatientDetails(dynamic patient) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientDetailsScreen(
          token: widget.token,
          patient: Map<String, dynamic>.from(patient),
        ),
      ),
    );

    if (!mounted) return;

    // If patient was edited, reload the list from backend.
    if (result == true || result is Map<String, dynamic>) {
      await _loadPatients();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadPatients,
            icon: const Icon(Icons.refresh_rounded),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _loadPatients,

              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.all(24),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    buildClinicalHeader(
                      context,
                      title: 'Patient Management',
                      subtitle: 'View and manage your clinic patients.',
                      icon: Icons.people_alt_outlined,
                    ),

                    const SizedBox(height: 24),

                    _buildSearch(),

                    const SizedBox(height: 20),

                    _buildPatientCount(),

                    const SizedBox(height: 14),

                    _buildPatientList(),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,

      decoration: InputDecoration(
        hintText: 'Search by name, phone, or email...',

        prefixIcon: const Icon(Icons.search_rounded),

        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                },
                icon: const Icon(Icons.clear_rounded),
              )
            : null,
      ),
    );
  }

  // ============================================================
  // PATIENT COUNT
  // ============================================================

  Widget _buildPatientCount() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Text(
          '${_filteredPatients.length} patient'
          '${_filteredPatients.length == 1 ? '' : 's'}',

          style: TextStyle(
            color: isDark
                ? AppTheme.textSecondaryDark
                : AppTheme.textSecondaryLight,

            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),

        const Spacer(),

        if (_searchController.text.isNotEmpty)
          Text(
            'Search results',

            style: TextStyle(
              color: isDark ? AppTheme.accentCyan : AppTheme.primary,

              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  // ============================================================
  // PATIENT LIST
  // ============================================================

  Widget _buildPatientList() {
    if (_filteredPatients.isEmpty) {
      return _buildEmpty();
    }

    return Column(
      children: _filteredPatients
          .map((patient) => _buildPatientCard(patient))
          .toList(),
    );
  }

  // ============================================================
  // PATIENT CARD
  // ============================================================

  Widget _buildPatientCard(dynamic patient) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final name = patient['name']?.toString().trim().isNotEmpty == true
        ? patient['name'].toString()
        : 'Unknown Patient';

    final phone = patient['phone']?.toString().trim().isNotEmpty == true
        ? patient['phone'].toString()
        : '-';

    final email = patient['email']?.toString().trim().isNotEmpty == true
        ? patient['email'].toString()
        : '-';

    final id = patient['id']?.toString() ?? '-';

    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.025),

            blurRadius: 12,

            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          // ====================================================
          // AVATAR
          // ====================================================
          Container(
            width: 54,
            height: 54,

            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: isDark ? 0.20 : 0.10),

              borderRadius: BorderRadius.circular(15),
            ),

            child: Icon(
              Icons.person_outline_rounded,

              color: isDark ? AppTheme.accentCyan : AppTheme.primary,

              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          // ====================================================
          // PATIENT INFORMATION
          // ====================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  name,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,

                    fontSize: 17,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Patient ID: $id',

                  style: TextStyle(
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,

                    fontSize: 12,

                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 7),

                // PHONE
                if (phone != '-')
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,

                        size: 15,

                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),

                      const SizedBox(width: 6),

                      Expanded(
                        child: Text(
                          phone,

                          overflow: TextOverflow.ellipsis,

                          style: TextStyle(
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight,

                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                // EMAIL
                if (email != '-')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),

                    child: Row(
                      children: [
                        Icon(
                          Icons.email_outlined,

                          size: 15,

                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),

                        const SizedBox(width: 6),

                        Expanded(
                          child: Text(
                            email,

                            overflow: TextOverflow.ellipsis,

                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight,

                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ====================================================
          // DETAILS BUTTON
          // ====================================================
          IconButton(
            tooltip: 'View patient details',

            onPressed: () {
              _openPatientDetails(patient);
            },

            icon: Icon(
              Icons.arrow_forward_ios_rounded,

              size: 17,

              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmpty() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(vertical: 55, horizontal: 24),

      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),

      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,

            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: isDark ? 0.18 : 0.08),

              borderRadius: BorderRadius.circular(18),
            ),

            child: Icon(
              Icons.people_outline_rounded,

              size: 32,

              color: isDark ? AppTheme.accentCyan : AppTheme.primary,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'No patients found',

            style: TextStyle(
              color: isDark
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,

              fontSize: 18,

              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _searchController.text.isEmpty
                ? 'There are no patients registered yet.'
                : 'Try searching with a different name, phone, or email.',

            textAlign: TextAlign.center,

            style: TextStyle(
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,

              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
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
              'Unable to load patients',

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
              onPressed: _loadPatients,

              icon: const Icon(Icons.refresh_rounded),

              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
