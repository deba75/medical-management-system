import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/ambulance_model.dart';

enum SearchMode { phone, location }

class BookAmbulanceScreen extends ConsumerStatefulWidget {
  const BookAmbulanceScreen({super.key});

  @override
  ConsumerState<BookAmbulanceScreen> createState() => _BookAmbulanceScreenState();
}

class _BookAmbulanceScreenState extends ConsumerState<BookAmbulanceScreen> {
  SearchMode _searchMode = SearchMode.phone;
  final _searchController = TextEditingController();
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isLoadingAmbulances = true;
  List<AmbulanceModel> _ambulances = [];
  List<AmbulanceModel> _filteredAmbulances = [];

  @override
  void initState() {
    super.initState();
    _loadAmbulancesFromFirestore();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAmbulancesFromFirestore() async {
    setState(() => _isLoadingAmbulances = true);
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ambulances')
          .where('availability', isEqualTo: 'online')
          .get();
      
      if (snapshot.docs.isEmpty) {
        // If no ambulances in Firestore, load mock data
        _loadMockAmbulances();
      } else {
        _ambulances = snapshot.docs.map((doc) {
          return AmbulanceModel.fromJson(doc.data(), doc.id);
        }).toList();
        _filteredAmbulances = _ambulances;
      }
    } catch (e) {
      debugPrint('Error loading ambulances: $e');
      // On error, load mock data as fallback
      _loadMockAmbulances();
    }
    
    setState(() => _isLoadingAmbulances = false);
  }

  void _loadMockAmbulances() {
    // Mock ambulance data - used as fallback when Firestore is empty
    _ambulances = [
      AmbulanceModel(
        ambulanceId: '1',
        driverName: 'Kamal Rahman',
        driverPhone: '+8801712345678',
        type: AmbulanceType.basic,
        vehicleNumber: 'DHA-1234',
        availability: AvailabilityStatus.online,
        currentLat: 23.8103,
        currentLng: 90.4125,
        currentAddress: 'Mirpur, Dhaka',
      ),
      AmbulanceModel(
        ambulanceId: '2',
        driverName: 'Rahim Miah',
        driverPhone: '+8801812345679',
        type: AmbulanceType.icu,
        vehicleNumber: 'DHA-5678',
        availability: AvailabilityStatus.online,
        currentLat: 23.7465,
        currentLng: 90.3763,
        currentAddress: 'Dhanmondi, Dhaka',
      ),
      AmbulanceModel(
        ambulanceId: '3',
        driverName: 'Abdul Jabbar',
        driverPhone: '+8801912345680',
        type: AmbulanceType.basic,
        vehicleNumber: 'DHA-9012',
        availability: AvailabilityStatus.online,
        currentLat: 23.8608,
        currentLng: 90.3988,
        currentAddress: 'Uttara, Dhaka',
      ),
      AmbulanceModel(
        ambulanceId: '4',
        driverName: 'Shahid Hossain',
        driverPhone: '+8801612345681',
        type: AmbulanceType.icu,
        vehicleNumber: 'DHA-3456',
        availability: AvailabilityStatus.online,
        currentLat: 23.7271,
        currentLng: 90.4077,
        currentAddress: 'Motijheel, Dhaka',
      ),
      AmbulanceModel(
        ambulanceId: '5',
        driverName: 'Alamgir Kabir',
        driverPhone: '+8801512345682',
        type: AmbulanceType.neonatal,
        vehicleNumber: 'DHA-7890',
        availability: AvailabilityStatus.online,
        currentLat: 23.7925,
        currentLng: 90.4078,
        currentAddress: 'Banani, Dhaka',
      ),
    ];
    _filteredAmbulances = _ambulances;
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled. Please enable location.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission permanently denied. Enable from settings.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _filterByLocation();
        _isLoadingLocation = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      setState(() => _isLoadingLocation = false);
    }
  }

  void _filterByLocation() {
    if (_currentPosition == null) return;

    // Calculate distance for each ambulance and sort by distance
    List<MapEntry<AmbulanceModel, double>> ambulancesWithDistance = [];

    for (var ambulance in _ambulances) {
      if (ambulance.currentLat != null && ambulance.currentLng != null) {
        double distance = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          ambulance.currentLat!,
          ambulance.currentLng!,
        );
        ambulancesWithDistance.add(MapEntry(ambulance, distance));
      }
    }

    // Sort by distance
    ambulancesWithDistance.sort((a, b) => a.value.compareTo(b.value));

    setState(() {
      _filteredAmbulances = ambulancesWithDistance.map((e) => e.key).toList();
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;

  void _filterByPhone(String query) {
    if (query.isEmpty) {
      setState(() => _filteredAmbulances = _ambulances);
      return;
    }

    setState(() {
      _filteredAmbulances = _ambulances.where((ambulance) {
        return ambulance.driverPhone.toLowerCase().contains(query.toLowerCase()) ||
            ambulance.driverName.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void _showBookingDialog(AmbulanceModel ambulance) {
    showDialog(
      context: context,
      builder: (context) => BookingDialog(ambulance: ambulance),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Ambulance'),
      ),
      body: Column(
        children: [
          // Search Mode Toggle
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildModeButton(
                    'Find by Phone',
                    Icons.phone,
                    SearchMode.phone,
                  ),
                ),
                Expanded(
                  child: _buildModeButton(
                    'Find by Location',
                    Icons.location_on,
                    SearchMode.location,
                  ),
                ),
              ],
            ),
          ),

          // Search/Location Section
          if (_searchMode == SearchMode.phone) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomTextField(
                controller: _searchController,
                label: 'Search Driver',
                hint: 'Enter phone number or name',
                prefixIcon: Icons.search,
                onChanged: _filterByPhone,
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_currentPosition == null)
                    ElevatedButton.icon(
                      onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                      icon: _isLoadingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(_isLoadingLocation ? 'Getting Location...' : 'Get My Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: AppTheme.primaryColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Location',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                                  'Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _getCurrentLocation,
                            color: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Results Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchMode == SearchMode.location && _currentPosition != null
                      ? 'Nearby Ambulances (${_filteredAmbulances.length})'
                      : 'Available Ambulances (${_filteredAmbulances.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Ambulance List
          Expanded(
            child: _isLoadingAmbulances
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading ambulances...'),
                      ],
                    ),
                  )
                : _filteredAmbulances.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchMode == SearchMode.location && _currentPosition == null
                              ? 'Get your location to find nearby ambulances'
                              : 'No ambulances found',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadAmbulancesFromFirestore,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAmbulancesFromFirestore,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredAmbulances.length,
                      itemBuilder: (context, index) {
                        final ambulance = _filteredAmbulances[index];
                        double? distance;
                        
                        if (_searchMode == SearchMode.location && _currentPosition != null) {
                          distance = _calculateDistance(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                            ambulance.currentLat ?? 0,
                            ambulance.currentLng ?? 0,
                          );
                        }

                        return _buildAmbulanceCard(ambulance, distance);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String text, IconData icon, SearchMode mode) {
    final isSelected = _searchMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _searchMode = mode;
          _searchController.clear();
          _filteredAmbulances = _ambulances;
          if (mode == SearchMode.location && _currentPosition == null) {
            _getCurrentLocation();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbulanceCard(AmbulanceModel ambulance, double? distance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showBookingDialog(ambulance),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.local_shipping,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ambulance.driverName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ambulance.vehicleNumber,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (distance != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${distance.toStringAsFixed(1)} km',
                        style: TextStyle(
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    ambulance.driverPhone,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(ambulance.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppConstants.ambulanceTypes[ambulance.type.name] ?? ambulance.type.name,
                      style: TextStyle(
                        color: _getTypeColor(ambulance.type),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (ambulance.currentAddress != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ambulance.currentAddress!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(AmbulanceType type) {
    switch (type) {
      case AmbulanceType.basic:
        return AppTheme.primaryColor;
      case AmbulanceType.icu:
        return AppTheme.errorColor;
      case AmbulanceType.neonatal:
        return AppTheme.secondaryColor;
      case AmbulanceType.cardiac:
        return Colors.purple;
    }
  }
}

// Booking Dialog
class BookingDialog extends StatefulWidget {
  final AmbulanceModel ambulance;

  const BookingDialog({super.key, required this.ambulance});

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isBooking = false;

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _confirmBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isBooking = true);

    // TODO: Create booking in Firestore
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ambulance booked! ${widget.ambulance.driverName} will contact you soon.'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Book Ambulance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                
                // Driver Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.ambulance.driverName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${widget.ambulance.vehicleNumber} • ${widget.ambulance.driverPhone}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _pickupController,
                  label: 'Pickup Location',
                  hint: 'Enter pickup address',
                  prefixIcon: Icons.location_on,
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter pickup location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                CustomTextField(
                  controller: _dropController,
                  label: 'Drop Location',
                  hint: 'Enter destination',
                  prefixIcon: Icons.local_hospital,
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter destination';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                CustomTextField(
                  controller: _phoneController,
                  label: 'Your Phone',
                  hint: 'Enter contact number',
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isBooking ? null : _confirmBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isBooking
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Confirm Booking'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
