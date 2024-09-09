import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:flutter/services.dart' show ByteData, rootBundle;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? _mapController;
  Marker? _marker;
  Circle? _circle;

  String? _mapStyle;

  late StreamSubscription<Position> _positionStream;
  late Position _locationData;

  Future<Uint8List> getMarker() async {
    ByteData byteData =
        await DefaultAssetBundle.of(context).load("assets/car_icon.png");
    return byteData.buffer.asUint8List();
  }

  final CameraPosition _initCameraPosition = const CameraPosition(
    target: LatLng(14.957169, 102.043775),
    zoom: 17,
  );

  updateMarker(Position locationData, Uint8List imageMarker) async {
    LatLng latLng = LatLng(
      locationData.latitude,
      locationData.longitude,
    );

    _marker = Marker(
      markerId: const MarkerId("car"),
      position: latLng,
      rotation: locationData.heading,
      zIndex: 2,
      anchor: const Offset(0.5, 0.5),
      icon: BitmapDescriptor.bytes(
        imageMarker,
        width: 24,
      ),
    );

    _circle = Circle(
      circleId: const CircleId("car_circle"),
      radius: locationData.accuracy,
      zIndex: 1,
      strokeColor: Colors.blue,
      strokeWidth: 1,
      center: latLng,
      fillColor: Colors.blue.withAlpha(50),
    );

    // move camera position
    await _mapController!.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: latLng,
        zoom: 17,
      ),
    ));
    log('update camera!');

    setState(() {});
  }

  setMapStyle() async {
    _mapStyle = await rootBundle.loadString('assets/mapstyle.json');
  }

  @override
  void initState() {
    super.initState();
    // get mapstyle
    setMapStyle();
    // get current location
    getCurrentLocation();
  }

  @override
  void dispose() {
    super.dispose();
    _positionStream.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        style: _mapStyle,
        initialCameraPosition: _initCameraPosition,
        markers: (_marker == null) ? {} : {_marker!},
        circles: (_circle == null) ? {} : {_circle!},
        compassEnabled: true,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
      ),
    );
  }

  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5,
  );

  Future<void> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.

    // get marker icon
    Uint8List imageMarker = await getMarker();
    _locationData = await Geolocator.getCurrentPosition();

    // update marker
    updateMarker(_locationData, imageMarker);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position? position) {
      // update marker
      updateMarker(position!, imageMarker);
      log('current position = $position ');
    });
  }
}
