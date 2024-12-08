import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:appointment_app/core/database_helper.dart';
import 'package:appointment_app/models/appointment.dart';
import 'package:appointment_app/pages/add_appointment_page.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AppointmentDetailPage extends StatefulWidget {
  final int appointmentId;
  const AppointmentDetailPage({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  final dbHelper = DatabaseHelper.instance;
  Appointment? appointment;

  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;

  CameraPosition initialCameraPosition = const CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  void getAppointmentLocation(LatLng position) async {
    LatLng userLatLag = LatLng(position.latitude, position.longitude);
    CameraPosition positionCamera =
        CameraPosition(target: userLatLag, zoom: 15);
    controllerGoogleMap!
        .animateCamera(CameraUpdate.newCameraPosition(positionCamera));
  }

  @override
  void initState() {
    getAppointmentById(widget.appointmentId);
    super.initState();
  }

  Future<void> getAppointmentById(int id) async {
    final data = await dbHelper.getAppointmentById(id);
    setState(() {
      appointment = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(),
      body: appointment == null
          ? const CircularProgressIndicator()
          : Stack(
              alignment: Alignment.bottomCenter,
              children: [
                GoogleMap(
                  padding: const EdgeInsets.all(10),
                  mapType: MapType.normal,
                  myLocationEnabled: true,
                  initialCameraPosition: initialCameraPosition,
                  onMapCreated: (controller) {
                    controllerGoogleMap = controller;
                    googleMapCompleterController.complete(controllerGoogleMap);
                    getAppointmentLocation(LatLng(
                        appointment!.addressLat, appointment!.addressLng));
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: LatLng(
                          appointment!.addressLat, appointment!.addressLng),
                    ),
                  },
                ),
                DraggableScrollableSheet(
                  snap: true,
                  maxChildSize: 1,
                  minChildSize: 0.2,
                  initialChildSize: 0.4,
                  builder: (context, scrollController) {
                    return SingleChildScrollView(
                      controller: scrollController,
                      child: Card(
                        child: Container(
                          margin: const EdgeInsets.all(10),
                          width: MediaQuery.sizeOf(context).width,
                          height: MediaQuery.sizeOf(context).height,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(appointment!.name),
                              Text(appointment!.description),
                              ListTile(
                                title: const Text("Date"),
                                trailing: Text(
                                  dateFormatter
                                      .format(appointment!.appointmentDateTime),
                                ),
                              ),
                              ListTile(
                                title: const Text("Time"),
                                trailing: Text(TimeOfDay(
                                        hour: appointment!
                                            .appointmentDateTime.hour,
                                        minute: appointment!
                                            .appointmentDateTime.minute)
                                    .format(context)),
                              ),
                              FutureBuilder(
                                future: changeLatLngIntoString(LatLng(
                                    appointment!.addressLat,
                                    appointment!.addressLng)),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const CircularProgressIndicator();
                                  } else if (snapshot.hasError) {
                                    return Text(snapshot.error.toString());
                                  }
                                  return Text(snapshot.data!);
                                },
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddAppointmentPage(
                  appointment: appointment!,
                ),
              )).then(
            (value) {
              getAppointmentById(widget.appointmentId);
            },
          );
        },
        child: const Icon(Icons.edit),
      ),
    );
  }

  sendRequestToAPI(String apiUrl) async {
    http.Response responseFromAPI = await http.get(Uri.parse(apiUrl));

    try {
      if (responseFromAPI.statusCode == HttpStatus.ok) {
        String dataFromApi = responseFromAPI.body;
        var dataDecoded = jsonDecode(dataFromApi);
        return dataDecoded;
      } else {
        return "error";
      }
    } catch (e) {
      return "error";
    }
  }

  Future<String> changeLatLngIntoString(LatLng latlng) async {
    String geoCodingAPIUrl =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${latlng.latitude},${latlng.longitude}&key=AIzaSyBtzaTGeBrb0mTh911fAeuv2ZB0eJk8J-M";
    var responseFromAPI = await sendRequestToAPI(geoCodingAPIUrl);
    String humanReadableAddress =
        responseFromAPI['results'][0]['formatted_address'];
    return humanReadableAddress;
  }
}
