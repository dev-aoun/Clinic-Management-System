import 'package:flutter/material.dart';
import '../services/api_service.dart';

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

  // =========================
  // LOAD PATIENTS
  // =========================

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final patients = await ApiService.getPatients(widget.token);

      if (!mounted) return;

      setState(() {
        _patients = patients;
        _filteredPatients = patients;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // =========================
  // SEARCH
  // =========================

  void _filterPatients() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredPatients = _patients;
      } else {
        _filteredPatients = _patients.where((patient) {
          final name = patient['name']?.toString().toLowerCase() ?? '';

          final phone = patient['phone']?.toString().toLowerCase() ?? '';

          final email = patient['email']?.toString().toLowerCase() ?? '';

          return name.contains(query) ||
              phone.contains(query) ||
              email.contains(query);
        }).toList();
      }
    });
  }

  // =========================
  // PATIENT DETAILS
  // =========================

  void _showPatientDetails(dynamic patient) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(patient['name']?.toString() ?? 'Patient Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Phone', patient['phone']),
              _detailRow('Email', patient['email']),
              _detailRow('Date of Birth', patient['date_of_birth']),
              _detailRow('Gender', patient['gender']),
              _detailRow('Address', patient['address']),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value?.toString() ?? '-')),
        ],
      ),
    );
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'Patients',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF172033),
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadPatients,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF172033)),
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
                    _buildHeader(),

                    const SizedBox(height: 24),

                    _buildSearch(),

                    const SizedBox(height: 20),

                    Text(
                      '${_filteredPatients.length} patient${_filteredPatients.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Color(0xFF7A8292),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _buildPatientList(),
                  ],
                ),
              ),
            ),
    );
  }

  // =========================
  // HEADER
  // =========================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Patient Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'View and manage your clinic patients.',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),

          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add Patient'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // SEARCH
  // =========================

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by name, phone, or email...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                },
                icon: const Icon(Icons.clear_rounded),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // =========================
  // PATIENT LIST
  // =========================

  Widget _buildPatientList() {
    if (_filteredPatients.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(50),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 55,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 14),
            Text(
              'No patients found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _filteredPatients.map((patient) {
        return _buildPatientCard(patient);
      }).toList(),
    );
  }

  // =========================
  // PATIENT CARD
  // =========================

  Widget _buildPatientCard(dynamic patient) {
    final name = patient['name']?.toString() ?? 'Unknown Patient';

    final phone = patient['phone']?.toString() ?? '-';

    final email = patient['email']?.toString() ?? '-';

    final id = patient['id']?.toString() ?? '-';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E9F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE0EBFF),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF2563EB),
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF172033),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Patient ID: $id',
                  style: const TextStyle(
                    color: Color(0xFF7A8292),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  phone,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  email,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'View details',
            onPressed: () {
              _showPatientDetails(patient);
            },
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  // =========================
  // ERROR
  // =========================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.red,
            ),

            const SizedBox(height: 16),

            const Text(
              'Unable to load patients',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: _loadPatients,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
