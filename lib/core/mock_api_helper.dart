import 'package:appointment_app/models/appointment.dart';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;

class MockApiHelper {
  final String mockApi =
      "https://67549c3036bcd1eec8519692.mockapi.io/appointmentApp/api/v1/appointments";

  //
  Future syncAppointmentsToMockApi(List<Appointment> appointments) async {
    await deleteAppointment();
    for (Appointment appointment in appointments) {
      final result = await http.post(
        Uri.parse(mockApi),
        headers: {
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        body: jsonEncode(appointment.toMap()),
      );
      log(result.statusCode.toString());
    }
  }

  Future<List<Appointment>> getAppointmentsFromMockApi() async {
    final result = await http.get(
      Uri.parse(mockApi),
      headers: {
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.contentTypeHeader: 'application/json',
      },
    );
    final List<dynamic> jsonResponse = jsonDecode(result.body);
    return jsonResponse.map((json) => Appointment.fromMap(json)).toList();
  }

  Future deleteAppointment() async {
    final uploadedAppointments = await getAppointmentsFromMockApi();
    for (Appointment appointment in uploadedAppointments) {
      final result = await http.delete(
        Uri.parse("$mockApi/${appointment.mockId}"),
        headers: {
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.contentTypeHeader: 'application/json',
        },
      );
      log(result.body);
    }
  }
}
