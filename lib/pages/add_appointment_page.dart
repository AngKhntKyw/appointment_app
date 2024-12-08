import 'package:appointment_app/core/database_helper.dart';
import 'package:appointment_app/models/appointment.dart';
import 'package:appointment_app/pages/google_map_page.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class AddAppointmentPage extends StatefulWidget {
  final Appointment? appointment;
  const AddAppointmentPage({super.key, this.appointment});

  @override
  State<AddAppointmentPage> createState() => _AddAppointmentPageState();
}

class _AddAppointmentPageState extends State<AddAppointmentPage> {
  final dbHelper = DatabaseHelper.instance;
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  LatLng? selctedAddress;

  @override
  void initState() {
    if (widget.appointment != null) {
      nameController.text = widget.appointment!.name;
      descriptionController.text = widget.appointment!.description;
      selctedAddress = LatLng(
          widget.appointment!.addressLat, widget.appointment!.addressLng);
      _selectedDate = DateTime(
        widget.appointment!.appointmentDateTime.year,
        widget.appointment!.appointmentDateTime.month,
      );
      _selectedTime = TimeOfDay(
          hour: widget.appointment!.appointmentDateTime.hour,
          minute: widget.appointment!.appointmentDateTime.minute);
    }
    super.initState();
  }

  void pickDatePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void pickTimePicker() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(title: const Text("Add appointment")),
      body: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: "Name",
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Enter name";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  hintText: "Description",
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Enter description";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'Select Date'
                          : 'Date: ${dateFormatter.format(_selectedDate!)}',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: pickDatePicker,
                    child: const Text('Pick Date'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedTime == null
                          ? 'Select Time'
                          : 'Time: ${_selectedTime!.format(context)}',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: pickTimePicker,
                    child: const Text('Pick Time'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selctedAddress == null
                          ? 'Select location'
                          : 'location: $selctedAddress',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await Permission.locationWhenInUse.isDenied.then(
                        (value) {
                          if (value) {
                            Permission.locationWhenInUse.request();
                          }
                        },
                      );

                      //
                      final point = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                GoogleMapPage(pickedlatLng: selctedAddress)),
                      );
                      setState(() {
                        selctedAddress = point;
                      });
                    },
                    child: const Text('Open Map'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                  onPressed: () async {
                    FocusManager.instance.primaryFocus!.unfocus();
                    if (formKey.currentState!.validate()) {
                      if (selctedAddress != null &&
                          _selectedDate != null &&
                          _selectedTime != null) {
                        widget.appointment == null
                            ? await dbHelper.createAppointment(
                                Appointment(
                                  name: nameController.text,
                                  description: descriptionController.text,
                                  addressLat: selctedAddress!.latitude,
                                  addressLng: selctedAddress!.longitude,
                                  appointmentDateTime: DateTime(
                                    _selectedDate!.year,
                                    _selectedDate!.month,
                                    _selectedDate!.day,
                                    _selectedTime!.hour,
                                    _selectedTime!.minute,
                                  ),
                                ),
                              )
                            : await dbHelper.updateAppointment(
                                Appointment(
                                  id: widget.appointment!.id,
                                  name: nameController.text,
                                  description: descriptionController.text,
                                  addressLat: selctedAddress!.latitude,
                                  addressLng: selctedAddress!.longitude,
                                  appointmentDateTime: DateTime(
                                    _selectedDate!.year,
                                    _selectedDate!.month,
                                    _selectedDate!.day,
                                    _selectedTime!.hour,
                                    _selectedTime!.minute,
                                  ),
                                ),
                              );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Enter all fields")));
                      }
                    }
                  },
                  child: const Text("Save"))
            ],
          ),
        ),
      ),
    );
  }
}
