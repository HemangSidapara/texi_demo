import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart' as Geolocator;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:texi_demo/calender.dart';
import 'package:texi_demo/const.dart';
import 'package:texi_demo/direction.dart';
import 'package:texi_demo/direction_model.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:texi_demo/notification_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotifyHelper().initializeNotification();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Geolocator.Location? location;
  Geolocator.LocationData? currentLocation;
  String loc = "Finding location...";
  GoogleMapController? googleMapController;
  Marker? origin;
  Marker? destination;
  Directions? info;
  CameraPosition? cameraPosition;
  PolylinePoints polylinePoints = PolylinePoints();
  final Mode mode = Mode.overlay;
  final homeScaffoldKey = GlobalKey<ScaffoldMessengerState>();
  Set<Marker> markersList = {};
  final Completer<GoogleMapController> controller = Completer();
  CameraPosition initialCameraPosition = const CameraPosition(target: LatLng(0, 0));
  var mapType;

  late BitmapDescriptor customIcon;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await BitmapDescriptor.fromAssetImage(const ImageConfiguration(devicePixelRatio: .5), "assets/car.png").then((d) {
        customIcon = d;
      });
      await getLocation();
    });
  }

  @override
  void dispose() {
    super.dispose();
    googleMapController!.dispose();
  }

  Future<void> getLocation() async {
    location = Geolocator.Location();

    bool serviceEnabled;
    Geolocator.PermissionStatus permissionGranted;

    serviceEnabled = await location!.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location!.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location!.hasPermission();
    if (permissionGranted == Geolocator.PermissionStatus.denied) {
      permissionGranted = await location!.requestPermission();
      if (permissionGranted != Geolocator.PermissionStatus.granted) {
        return;
      }
    }

    currentLocation = await location!.getLocation();
    setState(() {
      currentLocation;
    });

    initialCameraPosition = CameraPosition(
      target: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
      zoom: 16,
    );

    cameraPosition = CameraPosition(
      target: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
      zoom: 16,
    );

    GoogleMapController googleMapController = await controller.future;

    location!.onLocationChanged.listen(
      (newLoc) {
        setState(() {
          currentLocation = newLoc;
        });
        print(currentLocation!.latitude);
        print(currentLocation!.longitude);
        googleMapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              zoom: 16,
              target: LatLng(
                newLoc.latitude!,
                newLoc.longitude!,
              ),
            ),
          ),
        );
        cameraPosition = CameraPosition(
          target: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
          zoom: 16,
        );
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: homeScaffoldKey,
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
          'Google Map',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        actions: [
          if (origin != null)
            TextButton(
              onPressed: () {
                googleMapController!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: origin!.position,
                      zoom: 16,
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                primary: Colors.green,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('Origin'),
            ),
          if (destination != null)
            TextButton(
              onPressed: () {
                googleMapController!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: destination!.position,
                      zoom: 16,
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                  primary: Colors.blue,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                  )),
              child: const Text('Destination'),
            ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          currentLocation != null
              ? GoogleMap(
                  initialCameraPosition: initialCameraPosition,
                  buildingsEnabled: true,
                  compassEnabled: true,
                  tiltGesturesEnabled: true,
                  // myLocationEnabled: true,
                  // myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: true,
                  trafficEnabled: true,
                  rotateGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  polylines: {
                    if (info != null && destination != null)
                      Polyline(
                        polylineId: const PolylineId('overview_polyline'),
                        color: Colors.red,
                        width: 5,
                        points: info!.polylinePoints.map((e) => LatLng(e.latitude, e.longitude)).toList(),
                      ),
                  },
                  onMapCreated: (mapController) async {
                    setState(() {
                      controller.complete(mapController);
                      // googleMapController = controller;
                    });
                    print(cameraPosition!.target.latitude);
                    print(cameraPosition!.target.longitude);
                    final directions = DirectionsRepo().getDirections(origin: LatLng(cameraPosition!.target.latitude, cameraPosition!.target.longitude), destination: LatLng(cameraPosition!.target.latitude, cameraPosition!.target.longitude));
                    directions.then((value) {
                      print("loc ::: ${value!.info}");
                      setState(() {
                        loc = value.info;
                      });
                    });
                  },
                  onCameraMove: (CameraPosition cameraPosition) async {
                    cameraPosition = cameraPosition;
                    final directions = await directionHandle(destination);
                    setState(() {
                      info = directions;
                    });
                    // print(cameraPosition!.target.latitude);
                    // print(cameraPosition!.target.longitude);
                    // final directions = DirectionsRepo().getDirections(origin: LatLng(cameraPosition!.target.latitude, cameraPosition!.target.longitude), destination: LatLng(cameraPosition!.target.latitude, cameraPosition!.target.longitude));
                    // directions.then((value) {
                    //   print("loc ::: ${value!.info}");
                    //   setState(() {
                    //     loc = value.info;
                    //   });
                    // });
                  },
                  onCameraIdle: () {
                    print(cameraPosition!.target.latitude);
                    print(cameraPosition!.target.longitude);
                    final directions = DirectionsRepo().getDirections(origin: LatLng(cameraPosition!.target.latitude, cameraPosition!.target.longitude), destination: LatLng(cameraPosition!.target.latitude, cameraPosition!.target.longitude));
                    directions.then((value) {
                      print("loc ::: ${value!.info}");
                      setState(() {
                        loc = value.info;
                      });
                    });
                  },
                  // markers: markersList,
                  markers: {
                    Marker(
                        markerId: const MarkerId('origin'),
                        infoWindow: const InfoWindow(title: 'Origin'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        position: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
                        onTap: () {
                          origin = null;
                        }),
                    if (destination != null)
                      if ((currentLocation!.latitude != destination!.position.latitude) && (currentLocation!.longitude != destination!.position.longitude)) destination!,
                  },
                  mapType: mapType,
                  onLongPress: addMarker,
                )
              : const Center(child: CircularProgressIndicator()),
          location != null
              ? (destination == null
                  ? Center(
                      child: Image.asset(
                        'assets/placeholder.png',
                        width: 30,
                      ),
                    )
                  : const SizedBox())
              : const SizedBox(),
          Positioned(
            top: 20,
            left: 10,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (builder) => const CalenderEvents(),
                  ),
                );
              },
              child: Tooltip(
                message: "Event Reminder",
                triggerMode: TooltipTriggerMode.longPress,
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(90),
                  ),
                  child: const Icon(
                    Icons.event,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(90),
              ),
              child: PopupMenuButton(
                icon: const Icon(
                  Icons.map_rounded,
                  color: Colors.white,
                ),
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      value: 0,
                      onTap: () {
                        setState(() {
                          mapType = MapType.normal;
                        });
                      },
                      child: const Text('Normal'),
                    ),
                    PopupMenuItem(
                      value: 1,
                      onTap: () {
                        setState(() {
                          mapType = MapType.satellite;
                        });
                      },
                      child: const Text("Satellite"),
                    ),
                    PopupMenuItem(
                      value: 2,
                      onTap: () {
                        setState(() {
                          mapType = MapType.terrain;
                        });
                      },
                      child: const Text("Terrain"),
                    ),
                    PopupMenuItem(
                      value: 3,
                      onTap: () {
                        setState(() {
                          mapType = MapType.hybrid;
                        });
                      },
                      child: const Text("Hybrid"),
                    ),
                    PopupMenuItem(
                      value: 4,
                      onTap: () {
                        setState(() {
                          mapType = MapType.none;
                        });
                      },
                      child: const Text("None"),
                    ),
                  ];
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: EdgeInsets.zero,
                tooltip: "Select MapView",
              ),
            ),
          ),
          Positioned(
              //widget to display location name
              bottom: 100,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Card(
                  child: Container(
                      padding: const EdgeInsets.all(0),
                      width: MediaQuery.of(context).size.width - 40,
                      child: ListTile(
                        leading: Image.asset(
                          "assets/placeholder.png",
                          width: 25,
                        ),
                        title: Text(
                          loc ?? "Finding location...",
                          style: const TextStyle(fontSize: 18),
                        ),
                        dense: true,
                      )),
                ),
              )),
          Positioned(
            bottom: 12,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(25),
              ),
              child: IconButton(
                onPressed: () {
                  handlePressButton("Pick-Up Location");
                },
                icon: const Icon(Icons.search, color: Colors.white),
                tooltip: "Pick-Up Location",
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 72,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(25),
              ),
              child: IconButton(
                onPressed: () {
                  handlePressButton("Destination Location");
                },
                icon: const Icon(Icons.search, color: Colors.white),
                tooltip: "Destination Location",
              ),
            ),
          ),
          if (info != null)
            Positioned(
              top: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(color: Colors.yellowAccent, borderRadius: BorderRadius.circular(20), boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 6,
                  )
                ]),
                child: Text(
                  '${info!.totalDistance}, ${info!.totalDuration}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void addMarker(LatLng pos) async {
    if (origin != null || (origin == null && destination != null)) {
      setState(() {
        origin = Marker(
            markerId: const MarkerId('origin'),
            infoWindow: const InfoWindow(title: 'Origin'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            position: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
            onTap: () {
              markersList.clear();
            });
        destination = null;
        info = null;
      });
    } else {
      setState(() {
        destination = Marker(
            markerId: const MarkerId('destination'),
            infoWindow: const InfoWindow(title: 'Destination'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            position: pos,
            onTap: () {
              destination = null;
            });
      });

      final directions = await directionHandle(destination);
      setState(() {
        info = directions;
      });
    }
    markersList = {
      if (origin != null) origin!,
      if (destination != null) destination!,
    };
  }

  directionHandle(Marker? destination) async {
    return await DirectionsRepo().getDirections(origin: LatLng(currentLocation!.latitude!, currentLocation!.longitude!), destination: destination!.position);
  }

  Future<void> handlePressButton(String? s) async {
    Prediction? p = await PlacesAutocomplete.show(
      context: context,
      apiKey: googleAPIKey,
      onError: onError,
      mode: mode,
      language: 'en',
      strictbounds: false,
      types: [""],
      decoration: InputDecoration(
        hintText: s,
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.white)),
      ),
      components: [Component(Component.country, 'IN')],
    );

    displayPrediction(p!, homeScaffoldKey.currentState);
  }

  void onError(PlacesAutocompleteResponse response) {
    homeScaffoldKey.currentState!.showSnackBar(SnackBar(content: Text(response.errorMessage!)));
  }

  void displayPrediction(Prediction p, ScaffoldMessengerState? currentState) async {
    GoogleMapsPlaces places = GoogleMapsPlaces(apiKey: googleAPIKey, apiHeaders: await const GoogleApiHeaders().getHeaders());

    PlacesDetailsResponse detailsResponse = await places.getDetailsByPlaceId(p.placeId!);

    final lat = detailsResponse.result.geometry!.location.lat;
    final lng = detailsResponse.result.geometry!.location.lng;

    markersList.clear();
    markersList.add(Marker(markerId: const MarkerId("0"), position: LatLng(lat, lng), infoWindow: InfoWindow(title: detailsResponse.result.name)));

    setState(() {});

    googleMapController!.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16.0),
    );
  }
}
