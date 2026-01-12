class AmbulanceModel {
  final String ambulanceId;
  final String driverName;
  final String driverPhone;
  final AmbulanceType type;
  final String vehicleNumber;
  final AvailabilityStatus availability;
  final double? currentLat;
  final double? currentLng;
  final String? currentAddress;

  AmbulanceModel({
    required this.ambulanceId,
    required this.driverName,
    required this.driverPhone,
    required this.type,
    required this.vehicleNumber,
    required this.availability,
    this.currentLat,
    this.currentLng,
    this.currentAddress,
  });

  factory AmbulanceModel.fromJson(Map<String, dynamic> json, String id) {
    return AmbulanceModel(
      ambulanceId: id,
      driverName: json['driverName'] ?? '',
      driverPhone: json['driverPhone'] ?? '',
      type: AmbulanceType.values.firstWhere(
        (e) => e.toString() == 'AmbulanceType.${json['type']}',
        orElse: () => AmbulanceType.basic,
      ),
      vehicleNumber: json['vehicleNumber'] ?? '',
      availability: AvailabilityStatus.values.firstWhere(
        (e) => e.toString() == 'AvailabilityStatus.${json['availability']}',
        orElse: () => AvailabilityStatus.offline,
      ),
      currentLat: json['currentLat']?.toDouble(),
      currentLng: json['currentLng']?.toDouble(),
      currentAddress: json['currentAddress'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverName': driverName,
      'driverPhone': driverPhone,
      'type': type.name,
      'vehicleNumber': vehicleNumber,
      'availability': availability.name,
      'currentLat': currentLat,
      'currentLng': currentLng,
      'currentAddress': currentAddress,
    };
  }
}

enum AmbulanceType {
  basic,
  icu,
  neonatal,
}

enum AvailabilityStatus {
  online,
  offline,
}

class AmbulanceRequestModel {
  final String requestId;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final AmbulanceType ambulanceType;
  final LocationData pickup;
  final LocationData drop;
  final DateTime requestTime;
  final String? ambulanceId;
  final RequestStatus status;
  final String? driverName;
  final String? driverPhone;
  final String? vehicleNumber;

  AmbulanceRequestModel({
    required this.requestId,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.ambulanceType,
    required this.pickup,
    required this.drop,
    required this.requestTime,
    this.ambulanceId,
    required this.status,
    this.driverName,
    this.driverPhone,
    this.vehicleNumber,
  });

  factory AmbulanceRequestModel.fromJson(Map<String, dynamic> json, String id) {
    return AmbulanceRequestModel(
      requestId: id,
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? '',
      patientPhone: json['patientPhone'] ?? '',
      ambulanceType: AmbulanceType.values.firstWhere(
        (e) => e.toString() == 'AmbulanceType.${json['ambulanceType']}',
        orElse: () => AmbulanceType.basic,
      ),
      pickup: LocationData.fromJson(json['pickup'] ?? {}),
      drop: LocationData.fromJson(json['drop'] ?? {}),
      requestTime: DateTime.parse(json['requestTime'] ?? DateTime.now().toIso8601String()),
      ambulanceId: json['ambulanceId'],
      status: RequestStatus.values.firstWhere(
        (e) => e.toString() == 'RequestStatus.${json['status']}',
        orElse: () => RequestStatus.pending,
      ),
      driverName: json['driverName'],
      driverPhone: json['driverPhone'],
      vehicleNumber: json['vehicleNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'ambulanceType': ambulanceType.name,
      'pickup': pickup.toJson(),
      'drop': drop.toJson(),
      'requestTime': requestTime.toIso8601String(),
      'ambulanceId': ambulanceId,
      'status': status.name,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'vehicleNumber': vehicleNumber,
    };
  }
}

class LocationData {
  final String address;
  final double? lat;
  final double? lng;

  LocationData({
    required this.address,
    this.lat,
    this.lng,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      address: json['address'] ?? '',
      lat: json['lat']?.toDouble(),
      lng: json['lng']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'lat': lat,
      'lng': lng,
    };
  }
}

enum RequestStatus {
  pending,
  accepted,
  onRoute,
  completed,
  cancelled,
}
