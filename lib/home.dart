import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import 'package:flutter/services.dart' show ByteData, rootBundle;

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static double _latitude = 14.9430146;
  static double _logitude = 102.0456841;

  Location _location = new Location();

  bool _serviceEnabled;
  PermissionStatus _permissionGranted;

  LocationData _locationData;
  StreamSubscription<LocationData> _locationSubscription;

  GoogleMapController _mapController;
  Marker _marker;
  Circle _circle;

  Future<Uint8List> getMarker() async {
    ByteData byteData = await DefaultAssetBundle.of(context).load("assets/car_icon.png");
    return byteData.buffer.asUint8List();
  }

  static CameraPosition _initCameraPosition = CameraPosition(
    target: LatLng(_latitude, _logitude),
    zoom: 15,
  );

  updateMarker(LocationData locationData, Uint8List imageMarker) {
    LatLng latLng = LatLng(locationData.latitude, locationData.longitude);
    setState(() {
      _marker = Marker(
          markerId: MarkerId("car"),
          position: latLng,
          rotation: locationData.heading,
          draggable: false,
          zIndex: 2,
          flat: true,
          anchor: Offset(0.5, 0.5),
          icon: BitmapDescriptor.fromBytes(imageMarker));

      _circle = Circle(
          circleId: CircleId("car_circle"),
          radius: locationData.accuracy,
          zIndex: 1,
          strokeColor: Colors.blue,
          strokeWidth: 1,
          center: latLng,
          fillColor: Colors.blue.withAlpha(50));
    });
  }

  getCurrentLocation() async {
    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await _location.getLocation();

    // get marker icon
    Uint8List imageMarker = await getMarker();

    updateMarker(_locationData, imageMarker);

    _locationSubscription = _location.onLocationChanged.listen((LocationData currentLocation) {
      log(currentLocation.latitude.toString() + "," + currentLocation.longitude.toString());

      if (_mapController != null) {
        updateMarker(currentLocation, imageMarker);
        _mapController.animateCamera(CameraUpdate.newCameraPosition(new CameraPosition(
            target: LatLng(currentLocation.latitude, currentLocation.longitude),
            zoom: 18,
            tilt: 0)));
      }
    });
  }

  setMapStyle() {
    var brightness = MediaQuery.platformBrightnessOf(context);
    if (brightness == Brightness.light) {
      rootBundle.loadString('assets/mapstyle.json').then((string) {
        _mapController.setMapStyle(string);
      });
    } else {
      rootBundle.loadString('assets/mapstyle_dark.json').then((string) {
        _mapController.setMapStyle(string);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // get current location
    getCurrentLocation();
  }

  @override
  void dispose() {
    super.dispose();
    _locationSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    setMapStyle();
    return Scaffold(
      body: GoogleMap(
        zoomControlsEnabled: false,
        initialCameraPosition: _initCameraPosition,
        markers: Set.of((_marker != null) ? [_marker] : []),
        circles: Set.of((_circle != null) ? [_circle] : []),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
      ),
    );
  }
}
