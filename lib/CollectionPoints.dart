import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  bool _isTracking = false;
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(36.81271783644581, 10.0772944703472),
    zoom: 19,
  );

  Set<Marker> _markers = {};
  List<LatLng> _polylinePoints = [];

  loc.Location _locationTracker = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSubscription;
  Timer? _locationUpdateTimer;

  void _onMarkerTapped(MarkerId markerId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Marker Clicked'),
          content: Text('You clicked on marker $markerId'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _markers.add(
      Marker(
        markerId: MarkerId('1'),
        position: LatLng(36.81271783644581, 10.0772944703472),
        icon: BitmapDescriptor.defaultMarker,
      ),
    );
    _markers.add(
      Marker(
        markerId: MarkerId('2'),
        position: LatLng(36.81569833099349, 10.067724348674307),
        icon: BitmapDescriptor.defaultMarker,
      ),
    );
    _markers.add(
      Marker(
        markerId: MarkerId('3'),
        position: LatLng(36.820817295810514, 10.05831515945172),
        icon: BitmapDescriptor.defaultMarker,
      ),
    );

    _locationSubscription =
        _locationTracker.onLocationChanged.listen((loc.LocationData location) {
      if (location != null) {
        _polylinePoints.add(LatLng(location.latitude!, location.longitude!));
        setState(() {});
      }
    });

    _locationUpdateTimer = Timer.periodic(Duration(seconds: 1), (timer) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Collection Points'),
        actions: _isTracking
            ? [
                IconButton(
                  icon: Icon(Icons.stop),
                  onPressed: _stopLocationUpdates,
                ),
              ]
            : [
                IconButton(
                  icon: Icon(Icons.play_arrow),
                  onPressed: _getUserLocation,
                ),
              ],
      ),
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: _kGooglePlex,
        markers: _markers.map((marker) {
          return Marker(
            markerId: marker.markerId,
            position: marker.position,
            icon: marker.icon,
            onTap: () => _onMarkerTapped(marker.markerId),
          );
        }).toSet(),
        polylines: {
          Polyline(
            polylineId: PolylineId('line'),
            points: _polylinePoints,
            color: Colors.blue,
            width: 3,
          ),
        },
        zoomControlsEnabled: false,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _goToTheFirstLocation,
            child: Icon(Icons.directions),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _zoomIn,
            child: Icon(Icons.add),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _zoomOut,
            child: Icon(Icons.remove),
          ),
        ],
      ),
    );
  }

  Future<void> _getUserLocation() async {
    final GoogleMapController controller = await _controller.future;
    final loc.LocationData? location = await _locationTracker.getLocation();
    if (location != null) {
      _polylinePoints.add(LatLng(location.latitude!, location.longitude!));
      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId('currentLocation'),
            position: LatLng(location.latitude!, location.longitude!),
            icon: BitmapDescriptor.defaultMarker,
          ),
        );
      });
      await controller.animateCamera(
        CameraUpdate.newLatLng(LatLng(location.latitude!, location.longitude!)),
      );

      _locationUpdateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        _getUserLocation();
      });
    }

    setState(() {
      _isTracking = true;
    });
  }

  Future<void> _goToTheFirstLocation() async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newLatLng(_kGooglePlex.target));
  }

  void _zoomIn() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.zoomOut());
  }

  void _stopLocationUpdates() {
    _locationSubscription?.cancel();
    setState(() {
      _markers
          .removeWhere((marker) => marker.markerId.value == 'currentLocation');
    });
    _locationUpdateTimer?.cancel();

    setState(() {
      _isTracking = false;
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }
}
