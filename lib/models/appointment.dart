class Appointment {
  final int? id;
  final String name;
  final String description;
  final DateTime appointmentDateTime;
  final double addressLat;
  final double addressLng;
  final String? mockId;

  Appointment({
    this.id,
    required this.name,
    required this.description,
    required this.addressLat,
    required this.addressLng,
    required this.appointmentDateTime,
    this.mockId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'addressLat': addressLat,
      'addressLng': addressLng,
      'appointmentDateTime': appointmentDateTime.toIso8601String(),
      'mockId': mockId,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      addressLat: map['addressLat'],
      addressLng: map['addressLng'],
      appointmentDateTime: DateTime.parse(map['appointmentDateTime']),
      mockId: map['mockId'],
    );
  }
}
