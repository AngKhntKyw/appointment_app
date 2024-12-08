import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapPage extends StatefulWidget {
  final LatLng? pickedlatLng;
  const GoogleMapPage({super.key, this.pickedlatLng});

  @override
  State<GoogleMapPage> createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  //
  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  LatLng? _selectedPoint;
  Position? currentPositionOfUser;

  CameraPosition initialCameraPosition = const CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  void getCurrentLocation() async {
    Position userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPositionOfUser = userPosition;
    LatLng userLatLag = LatLng(
        currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
    CameraPosition positionCamera =
        CameraPosition(target: userLatLag, zoom: 15);

    controllerGoogleMap!
        .animateCamera(CameraUpdate.newCameraPosition(positionCamera));
  }

  void getPickedLocation() async {
    LatLng userLatLag =
        LatLng(widget.pickedlatLng!.latitude, widget.pickedlatLng!.longitude);
    CameraPosition positionCamera =
        CameraPosition(target: userLatLag, zoom: 15);

    controllerGoogleMap!
        .animateCamera(CameraUpdate.newCameraPosition(positionCamera));
    setState(() {
      _selectedPoint = widget.pickedlatLng;
    });
  }

  void _onMapTap(LatLng point) async {
    setState(() {
      _selectedPoint = point;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Point'),
        actions: [
          IconButton(
            onPressed: () {
              if (_selectedPoint != null) {
                Navigator.pop(context, _selectedPoint);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please select a point on the map')),
                );
              }
            },
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: GoogleMap(
        padding: const EdgeInsets.all(10),
        mapType: MapType.normal,
        myLocationEnabled: true,
        initialCameraPosition: initialCameraPosition,
        onMapCreated: (controller) {
          controllerGoogleMap = controller;
          googleMapCompleterController.complete(controllerGoogleMap);
          widget.pickedlatLng == null
              ? getCurrentLocation()
              : getPickedLocation();
        },
        onTap: (argument) {
          _onMapTap(argument);
        },
        markers: _selectedPoint != null
            ? {
                Marker(
                  markerId: const MarkerId('selected'),
                  position: LatLng(
                      _selectedPoint!.latitude, _selectedPoint!.longitude),
                ),
              }
            : {},
      ),
    );
  }
}
