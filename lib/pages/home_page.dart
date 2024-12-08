import 'package:appointment_app/core/database_helper.dart';
import 'package:appointment_app/core/mock_api_helper.dart';
import 'package:appointment_app/models/appointment.dart';
import 'package:appointment_app/pages/add_appointment_page.dart';
import 'package:appointment_app/pages/appointment_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final dbHelper = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();
  List<Appointment> appointments = [];
  List<Appointment> uploadedAppointments = [];
  String searchQuery = '';
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    loadAppointments();
    getUploadedAppointmentsFromMockApi();
  }

  Future<void> loadAppointments() async {
    final data = await dbHelper.searchAppointments(
      query: searchQuery,
      filterDate: selectedDate,
    );
    setState(() {
      appointments = data;
    });
  }

  void pickDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
      loadAppointments();
    }
  }

  void getUploadedAppointmentsFromMockApi() async {
    final result = await MockApiHelper().getAppointmentsFromMockApi();
    setState(() {
      uploadedAppointments.clear();
      uploadedAppointments.addAll(result);
    });
  }

  void clearFilters() {
    setState(() {
      searchQuery = '';
      selectedDate = null;
      _searchController.clear();
    });
    loadAppointments();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: pickDatePicker,
            tooltip: 'Filter by Date',
          ),
          if (selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: clearFilters,
              tooltip: 'Clear Filters',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onTapOutside: (event) {
                FocusManager.instance.primaryFocus!.unfocus();
              },
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
                loadAppointments();
              },
            ),
          ),

          // Display Selected Date
          if (selectedDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Filtering by: ${dateFormatter.format(selectedDate!)}',
              ),
            ),

          // To upload warning
          if (appointments.length != uploadedAppointments.length)
            Container(
              alignment: Alignment.center,
              width: MediaQuery.sizeOf(context).width,
              color: Colors.green,
              child: Text(
                " you have ${appointments.length - uploadedAppointments.length} appointment to upload",
              ),
            ),

          // Appointments List
          Expanded(
            child: appointments.isEmpty
                ? const Text("No Appointments")
                : RefreshIndicator(
                    onRefresh: () => MockApiHelper()
                        .syncAppointmentsToMockApi(appointments)
                        .then(
                          (value) => getUploadedAppointmentsFromMockApi(),
                        ),
                    child: ListView.builder(
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        final appointment = appointments[index];
                        return Column(
                          children: [
                            ListTile(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AppointmentDetailPage(
                                              appointmentId: appointment.id!),
                                    )).then(
                                  (value) => loadAppointments(),
                                );
                              },
                              title: Text(appointment.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appointment.description,
                                    maxLines: 1,
                                  ),
                                  Text(
                                    dateFormatter.format(
                                        appointment.appointmentDateTime),
                                  ),
                                  Text(TimeOfDay(
                                          hour: appointment
                                              .appointmentDateTime.hour,
                                          minute: appointment
                                              .appointmentDateTime.minute)
                                      .format(context))
                                ],
                              ),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await dbHelper
                                      .deleteAppointment(appointment.id!);
                                  loadAppointments();
                                },
                              ),
                            ),
                            const Divider(),
                          ],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),

      // Add Appointment Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddAppointmentPage(),
              )).then(
            (value) {
              loadAppointments();
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
