import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // =========================
  // LOGIN
  // =========================

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['detail']?.toString() ?? 'Login failed (${response.statusCode})',
    );
  }

  // =========================
  // GET PATIENTS
  // =========================

  static Future<List<dynamic>> getPatients(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/patients/'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception('Failed to load patients (${response.statusCode})');
  }

  // =========================
  // GET DOCTORS
  // =========================

  static Future<List<dynamic>> getDoctors(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/doctors/'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception('Failed to load doctors (${response.statusCode})');
  }

  // =========================
  // GET APPOINTMENTS
  // =========================

  static Future<List<dynamic>> getAppointments(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/appointments/'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception('Failed to load appointments (${response.statusCode})');
  }

  // =========================
  // GET CURRENT USER
  // =========================

  static Future<Map<String, dynamic>> getMe(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['detail']?.toString() ??
          'Failed to load user (${response.statusCode})',
    );
  }

  static Future<Map<String, dynamic>> createPatient({
    required String token,
    required String name,
    required String phone,
    required String email,
    required String dateOfBirth,
    required String gender,
    required String address,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/patients/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'email': email,
        'date_of_birth': dateOfBirth,
        'gender': gender,
        'address': address,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['detail']?.toString() ??
          'Failed to create patient (${response.statusCode})',
    );
  }

  static Future<Map<String, dynamic>> updatePatient(
    String token,
    int patientId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/patients/$patientId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(responseData);
    }

    throw Exception(
      responseData['detail']?.toString() ??
          'Failed to update patient (${response.statusCode})',
    );
  }
  // =========================
  // DELETE PATIENT
  // =========================

  static Future<void> deletePatient(String token, int patientId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/patients/$patientId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return;
    }

    String message = 'Failed to delete patient (${response.statusCode})';

    try {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic> && data['detail'] != null) {
        message = data['detail'].toString();
      }
    } catch (_) {
      // Keep the default error message.
    }

    throw Exception(message);
  }
  // =========================
  // CREATE DOCTOR
  // =========================

  static Future<Map<String, dynamic>> createDoctor({
    required String token,
    required String name,
    required String phone,
    required String email,
    required String specialization,
    required String qualification,
    required double consultationFee,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/doctors/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'email': email,
        'specialization': specialization,
        'qualification': qualification,
        'consultation_fee': consultationFee,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['detail']?.toString() ??
          'Failed to create doctor (${response.statusCode})',
    );
  }

  // =========================
  // UPDATE DOCTOR
  // =========================

  static Future<Map<String, dynamic>> updateDoctor(
    String token,
    int doctorId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/doctors/$doctorId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(responseData);
    }

    throw Exception(
      responseData['detail']?.toString() ??
          'Failed to update doctor (${response.statusCode})',
    );
  }

  // =========================
  // DELETE DOCTOR
  // =========================

  static Future<void> deleteDoctor(String token, int doctorId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/doctors/$doctorId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return;
    }

    String message = 'Failed to delete doctor (${response.statusCode})';

    try {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic> && data['detail'] != null) {
        message = data['detail'].toString();
      }
    } catch (_) {
      // Keep the default error message.
    }

    throw Exception(message);
  }
  // =========================
  // CREATE APPOINTMENT
  // =========================

  static Future<Map<String, dynamic>> createAppointment({
    required String token,
    required int patientId,
    required int doctorId,
    required String appointmentDate,
    required String appointmentTime,
    String status = 'scheduled',
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/appointments/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'patient_id': patientId,
        'doctor_id': doctorId,
        'appointment_date': appointmentDate,
        'appointment_time': appointmentTime,
        'status': status,
        'notes': notes,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['detail']?.toString() ??
          'Failed to create appointment (${response.statusCode})',
    );
  }

  // =========================
  // UPDATE APPOINTMENT
  // =========================

  static Future<Map<String, dynamic>> updateAppointment(
    String token,
    int appointmentId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/appointments/$appointmentId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(responseData);
    }

    throw Exception(
      responseData['detail']?.toString() ??
          'Failed to update appointment (${response.statusCode})',
    );
  }

  // =========================
  // DELETE APPOINTMENT
  // =========================

  static Future<void> deleteAppointment(String token, int appointmentId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/appointments/$appointmentId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return;
    }

    String message = 'Failed to delete appointment (${response.statusCode})';

    try {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic> && data['detail'] != null) {
        message = data['detail'].toString();
      }
    } catch (_) {
      // Keep default error message.
    }

    throw Exception(message);
  }
}
