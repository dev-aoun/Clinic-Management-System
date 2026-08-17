import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'doctor_details.dart';
import '../theme.dart';

class DoctorsScreen extends StatefulWidget {
  final String token;

  const DoctorsScreen({super.key, required this.token});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  List<dynamic> doctors = [];
  List<dynamic> filteredDoctors = [];

  bool isLoading = true;
  String? errorMessage;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    loadDoctors();

    searchController.addListener(filterDoctors);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD DOCTORS
  // ============================================================

  Future<void> loadDoctors() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final result = await ApiService.getDoctors(widget.token);

      if (!mounted) return;

      setState(() {
        doctors = result;
        filteredDoctors = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void filterDoctors() {
    if (!mounted) return;

    final query = searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredDoctors = doctors;
        return;
      }

      filteredDoctors = doctors.where((doctor) {
        final name = doctor['name']?.toString().toLowerCase() ?? '';

        final specialization =
            doctor['specialization']?.toString().toLowerCase() ?? '';

        final qualification =
            doctor['qualification']?.toString().toLowerCase() ?? '';

        final phone = doctor['phone']?.toString().toLowerCase() ?? '';

        final email = doctor['email']?.toString().toLowerCase() ?? '';

        return name.contains(query) ||
            specialization.contains(query) ||
            qualification.contains(query) ||
            phone.contains(query) ||
            email.contains(query);
      }).toList();
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctors'),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: isLoading ? null : loadDoctors,
            icon: const Icon(Icons.refresh_rounded),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? buildError()
          : RefreshIndicator(
              onRefresh: loadDoctors,

              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.all(24),

                children: [
                  // ======================================================
                  // CLINICAL HEADER
                  // ======================================================
                  buildClinicalHeader(
                    context,
                    title: 'Doctor Management',
                    subtitle: 'View and manage your clinic doctors.',
                    icon: Icons.medical_services_outlined,
                  ),

                  const SizedBox(height: 24),

                  // ======================================================
                  // SEARCH
                  // ======================================================
                  buildSearch(),

                  const SizedBox(height: 20),

                  // ======================================================
                  // COUNT
                  // ======================================================
                  Row(
                    children: [
                      Text(
                        '${filteredDoctors.length} doctor'
                        '${filteredDoctors.length == 1 ? '' : 's'}',

                        style: TextStyle(
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,

                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const Spacer(),

                      if (searchController.text.isNotEmpty)
                        Text(
                          'Search results',

                          style: TextStyle(
                            color: isDark
                                ? AppTheme.accentCyan
                                : AppTheme.primary,

                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ======================================================
                  // DOCTOR LIST
                  // ======================================================
                  if (filteredDoctors.isEmpty)
                    buildEmpty()
                  else
                    ...filteredDoctors.map((doctor) => buildDoctorCard(doctor)),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // SEARCH FIELD
  // ============================================================

  Widget buildSearch() {
    return TextField(
      controller: searchController,

      textInputAction: TextInputAction.search,

      decoration: InputDecoration(
        hintText: 'Search by name, specialization, phone, or email...',

        prefixIcon: const Icon(Icons.search_rounded),

        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',

                onPressed: () {
                  searchController.clear();
                },

                icon: const Icon(Icons.clear_rounded),
              )
            : null,
      ),
    );
  }

  // ============================================================
  // DOCTOR CARD
  // ============================================================

  Widget buildDoctorCard(dynamic doctor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final name = doctor['name']?.toString() ?? 'Unknown Doctor';

    final specialization = doctor['specialization']?.toString().trim() ?? '';

    final qualification = doctor['qualification']?.toString().trim() ?? '';

    final phone = doctor['phone']?.toString().trim() ?? '';

    final email = doctor['email']?.toString().trim() ?? '';

    final doctorId = doctor['id']?.toString() ?? '-';

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
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ==========================================================
          // AVATAR
          // ==========================================================
          Container(
            width: 54,
            height: 54,

            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: isDark ? 0.20 : 0.10),

              borderRadius: BorderRadius.circular(15),
            ),

            child: Icon(
              Icons.medical_services_rounded,

              color: isDark ? AppTheme.accentCyan : AppTheme.primary,

              size: 27,
            ),
          ),

          const SizedBox(width: 16),

          // ==========================================================
          // INFORMATION
          // ==========================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // NAME
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

                const SizedBox(height: 4),

                // DOCTOR ID
                Text(
                  'Doctor ID: $doctorId',

                  style: TextStyle(
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,

                    fontSize: 12,

                    fontWeight: FontWeight.w500,
                  ),
                ),

                // SPECIALIZATION
                if (specialization.isNotEmpty) ...[
                  const SizedBox(height: 7),

                  Row(
                    children: [
                      Icon(
                        Icons.medical_information_outlined,

                        size: 15,

                        color: isDark ? AppTheme.accentCyan : AppTheme.primary,
                      ),

                      const SizedBox(width: 6),

                      Expanded(
                        child: Text(
                          specialization,

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: TextStyle(
                            color: isDark
                                ? AppTheme.accentCyan
                                : AppTheme.primary,

                            fontSize: 13,

                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // QUALIFICATION
                if (qualification.isNotEmpty) ...[
                  const SizedBox(height: 5),

                  Row(
                    children: [
                      Icon(
                        Icons.school_outlined,

                        size: 15,

                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),

                      const SizedBox(width: 6),

                      Expanded(
                        child: Text(
                          qualification,

                          maxLines: 1,

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
                ],

                // PHONE
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 5),

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

                          maxLines: 1,

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
                ],

                // EMAIL
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 5),

                  Row(
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

                          maxLines: 1,

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
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ==========================================================
          // DETAILS BUTTON
          // ==========================================================
          Material(
            color: Colors.transparent,

            child: InkWell(
              borderRadius: BorderRadius.circular(12),

              onTap: () async {
                final result = await Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) => DoctorDetailsScreen(
                      token: widget.token,
                      doctor: doctor,
                    ),
                  ),
                );

                if (!mounted) return;

                if (result == true) {
                  await loadDoctors();
                }
              },

              child: Container(
                width: 40,
                height: 40,

                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(
                    alpha: isDark ? 0.16 : 0.06,
                  ),

                  borderRadius: BorderRadius.circular(12),
                ),

                child: Icon(
                  Icons.arrow_forward_ios_rounded,

                  size: 16,

                  color: isDark ? AppTheme.accentCyan : AppTheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget buildEmpty() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasSearch = searchController.text.trim().isNotEmpty;

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
              Icons.medical_services_outlined,

              size: 32,

              color: isDark ? AppTheme.accentCyan : AppTheme.primary,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            hasSearch ? 'No doctors found' : 'No doctors registered',

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
            hasSearch
                ? 'Try searching with a different name, specialization, phone, or email.'
                : 'There are no doctors registered yet.',

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

  Widget buildError() {
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
              'Unable to load doctors',

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
              errorMessage ?? 'Unknown error',

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
              onPressed: loadDoctors,

              icon: const Icon(Icons.refresh_rounded),

              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
