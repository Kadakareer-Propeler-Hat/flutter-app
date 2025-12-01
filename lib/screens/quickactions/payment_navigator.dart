import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:horizonai/components/custom_mainappbar.dart';

class PaymentNavigator extends StatefulWidget {
  const PaymentNavigator({super.key});

  @override
  State<PaymentNavigator> createState() => _PaymentNavigatorState();
}

class _PaymentNavigatorState extends State<PaymentNavigator> {
  final String googleApiKey = "AIzaSyAFSTLE1gAErYYL7OcfffKhyBj4MJ1uDz0";

  LocationData? userLocation;
  bool loading = true;
  GoogleMapController? mapController;

  List<Map<String, dynamic>> paymentCenters = [];
  List<Map<String, dynamic>> nearby = [];
  Map<String, dynamic>? nearestCenter;

  @override
  void initState() {
    super.initState();
    loadLocation();
  }

  Future<void> loadLocation() async {
    Location location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) serviceEnabled = await location.requestService();

    PermissionStatus permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
    }

    userLocation = await location.getLocation();

    await loadGeoJson();
    computeNearbyCenters();

    setState(() => loading = false);
  }

  // -------------------------
  // LOAD & PARSE GEOJSON FILE
  // -------------------------
  Future<void> loadGeoJson() async {
    String data = await rootBundle.loadString("assets/data/bank_location.geojson");
    final jsonData = json.decode(data);

    List features = jsonData["features"];

    paymentCenters.clear();

    for (var f in features) {
      var props = f["properties"];
      var geo = f["geometry"];

      if (geo == null || geo["type"] != "Polygon") continue;

      List coords = geo["coordinates"][0];

      // COMPUTE POLYGON CENTROID
      double sumLat = 0, sumLng = 0;
      for (var p in coords) {
        sumLng += p[0];
        sumLat += p[1];
      }
      double centerLat = sumLat / coords.length;
      double centerLng = sumLng / coords.length;

      paymentCenters.add({
        "name": props["name"] ?? "Unknown Bank",
        "address": props["addr:city"] ?? "Unknown Address",
        "lat": centerLat,
        "lng": centerLng,
        "open": true,
        "hours": "Not Specified",
      });
    }
  }

  // Haversine formula
  double computeDistance(lat1, lon1, lat2, lon2) {
    const earth = 6371;
    double dLat = _deg(lat2 - lat1);
    double dLon = _deg(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg(lat1)) * cos(_deg(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return earth * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _deg(double deg) => deg * pi / 180;

  // FILTER BANKS WITHIN 5KM
  void computeNearbyCenters() {
    if (userLocation == null) return;

    List<Map<String, dynamic>> results = [];

    for (var center in paymentCenters) {
      double dist = computeDistance(
        userLocation!.latitude,
        userLocation!.longitude,
        center["lat"],
        center["lng"],
      );

      if (dist <= 10.0) {
        results.add({...center, "distance": dist});
      }
    }

    results.sort((a, b) => a["distance"].compareTo(b["distance"]));

    results = results.take(10).toList();

    if (results.isNotEmpty) {
      nearestCenter = results.first;
      nearby = results.skip(1).toList();
    }
  }

  void openGoogleMaps(lat, lng) async {
    final url = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomMainAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
              ]),
              const SizedBox(height: 20),

              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFFFC55C),
                  child: const Icon(Icons.navigation_rounded, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),

              const Center(child: Text("Payment Navigator",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
              const Center(child: Text(
                  "Find supported stores and payment centers",
                  style: TextStyle(fontSize: 14, color: Colors.grey))),
              const SizedBox(height: 25),

              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 260,
                  child: GoogleMap(
                    myLocationEnabled: true,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(userLocation!.latitude!, userLocation!.longitude!),
                      zoom: 14,
                    ),
                    markers: {
                      // USER MARKER
                      Marker(
                        markerId: const MarkerId("user"),
                        position: LatLng(
                          userLocation!.latitude!,
                          userLocation!.longitude!,
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure,
                        ),
                      ),

                      // NEAREST PAYMENT CENTER
                      if (nearestCenter != null)
                        Marker(
                          markerId: MarkerId("nearest_${nearestCenter!["name"]}"),
                          position: LatLng(
                            nearestCenter!["lat"],
                            nearestCenter!["lng"],
                          ),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueOrange,
                          ),
                        ),

                      // OTHER NEARBY PAYMENT CENTERS
                      ...nearby.map((c) {
                        return Marker(
                          markerId: MarkerId("nearby_${c["name"]}"),
                          position: LatLng(c["lat"], c["lng"]),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueOrange,
                          ),
                        );
                      }).toSet(),
                    },
                  ),
                ),
              ),

              const SizedBox(height: 25),

              if (nearestCenter != null) _nearestCenterCard(),

              const SizedBox(height: 20),
              const Text("Other Nearby Locations",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              ...nearby.map((c) => _otherLocationCard(c)),
            ],
          ),
        ),
      ),
    );
  }

  // UI COMPONENTS BELOW
  Widget _nearestCenterCard() {
    final c = nearestCenter!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Nearest Center",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                _statusBadge(c["open"]),
              ]),
          const SizedBox(height: 10),
          Text(c["name"], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(c["address"], style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          Text("${c["distance"].toStringAsFixed(2)} km away"),
          const SizedBox(height: 6),
          Text("Hours: ${c["hours"]}"),
          const SizedBox(height: 14),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC55C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => openGoogleMaps(c["lat"], c["lng"]),
            child: const Text("Get Directions", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _otherLocationCard(Map<String, dynamic> c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(children: [
        const Icon(Icons.location_on, color: Colors.red),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c["name"], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text("${c["distance"].toStringAsFixed(2)} km away",
                    style: const TextStyle(color: Colors.black54)),
              ]),
        ),
        _statusBadge(c["open"]),
      ]),
    );
  }

  Widget _statusBadge(bool open) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: open ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(open ? "Open" : "Closed",
          style: TextStyle(color: open ? Colors.green.shade700 : Colors.red.shade700)),
    );
  }
}
