// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocode/geocode.dart';
//import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:alan_voice/alan_voice.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

// ignore: use_key_in_widget_constructors
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _latitude = "";
  var _longitude = "";
  var _altitude = "";
  var _speed = "";
  String currentAddress = 'My Address';

  _MyHomePageState() {
    /// Init Alan Button with project key from Alan Studio
    AlanVoice.addButton(
        "beb2b72d4d3b2be88f8ed8be0af7fc9a2e956eca572e1d8b807a3e2338fdd0dc/stage",
        buttonAlign: AlanVoice.BUTTON_ALIGN_LEFT);

    /// Handle commands from Alan Studio
    AlanVoice.onCommand.add((command) => _handleCommand(command.data));
    //    {
    //  debugPrint("got new command ${command.toString()}");
    //});
  }

  Future<void> _handleCommand(Map<String, dynamic> command) async {
    switch (command['comand']) {
      case "location":
        _activateAlanVoice();
        await _updatePosition();
        AlanVoice.playText(currentAddress);
        break;
      default:
        debugPrint("Unknow command");
    }
  }

  void _activateAlanVoice() async {
    var isActive = await AlanVoice.isActive();
    if (!isActive) {
      AlanVoice.activate();
    }
  }

  void sendData() async {
    _activateAlanVoice();
    var params = jsonEncode({"location": currentAddress});
    AlanVoice.callProjectApi("script::getLocation", params);
  }

  Future<String> _getAddress(double? lat, double? lang) async {
    if (lat == null || lang == null) return "";
    GeoCode geoCode = GeoCode();
    Address address =
        await geoCode.reverseGeocoding(latitude: lat, longitude: lang);
    return "${address.streetAddress}, ${address.city}, ${address.countryName}, ${address.postal}";
  }

  Future<void> _updatePosition() async {
    Position position = await _determinePosition();
    //List<Placemark> placemarks =
    //  await placemarkFromCoordinates(position.latitude, position.longitude);
    //Placemark place = placemarks[0];
    String place =
        "Avenida Colonel Maximiliano España, Santa Cruz de la Sierra, Bolivia, 6495";
    //await _getAddress(position.latitude, position.longitude);
    setState(() {
      _latitude = position.latitude.toString();
      _longitude = position.longitude.toString();
      _altitude = position.altitude.toString();
      _speed = position.speed.toString();
      currentAddress = place;
      //place.toString();
      // "${place.locality}, ${place.postalCode}, ${place.country}, ${place.administrativeArea}, ${place.isoCountryCode}, ${place.name}, ${place.street}, ${place.subAdministrativeArea},${place.subLocality}, ${place.subThoroughfare}, ${place.thoroughfare}";
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: 'Please keep your location on.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: 'Location Permissions are denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(msg: 'Permission is denied Forever');
    }
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FOX ASSISTANT')),
      body: Center(
        child: Column(
          children: [
            Text(
              currentAddress,
              style: const TextStyle(fontSize: 20),
            ),
            Text('Latitude = $_latitude'),
            Text('Longitude = $_longitude'),
            TextButton(
                onPressed: () async {
                  await _updatePosition();
                  sendData();
                },
                child: const Text('Locate Me')),
          ],
        ),
      ),
    );
  }
}
