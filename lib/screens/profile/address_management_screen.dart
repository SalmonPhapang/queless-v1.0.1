import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:queless/services/auth_service.dart';
import 'package:queless/models/user.dart';
import 'package:queless/utils/compliance_helper.dart';
import 'package:uuid/uuid.dart';

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({super.key});

  @override
  State<AddressManagementScreen> createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  final _authService = AuthService();

  void _addAddress() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddressForm(
        onSave: (address) async {
          await _authService.addAddress(address);
          setState(() {});
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _editAddress(Address address) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddressForm(
        address: address,
        onSave: (updatedAddress) async {
          await _authService.updateAddress(updatedAddress);
          setState(() {});
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _deleteAddress(Address address) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Are you sure you want to delete ${address.label}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _authService.deleteAddress(address.id);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final addresses = _authService.currentUser?.addresses ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('My Addresses')),
      body: addresses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_outlined, size: 80, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No addresses saved', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Add your first address to start ordering', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(address.isDefault ? Icons.home : Icons.location_on_outlined),
                    title: Row(
                      children: [
                        Text(address.label),
                        if (address.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Default', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white)),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(address.fullAddress, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editAddress(address);
                        } else if (value == 'delete') {
                          _deleteAddress(address);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAddress,
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
      ),
    );
  }
}

class AddressForm extends StatefulWidget {
  final Address? address;
  final Function(Address) onSave;

  const AddressForm({super.key, this.address, required this.onSave});

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  late TextEditingController _labelController;
  late TextEditingController _streetController;
  late TextEditingController _postalCodeController;
  late String _selectedCity;
  late String _selectedProvince;
  late bool _isDefault;
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;
  String? _locationMessage;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.address?.label ?? '');
    _streetController = TextEditingController(text: widget.address?.streetAddress ?? '');
    _postalCodeController = TextEditingController(text: widget.address?.postalCode ?? '');
    _selectedCity = widget.address?.city ?? ComplianceHelper.getSupportedCities().first;
    _selectedProvince = widget.address?.province ?? ComplianceHelper.getSupportedProvinces().first;
    _isDefault = widget.address?.isDefault ?? false;
    _latitude = widget.address?.latitude;
    _longitude = widget.address?.longitude;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _streetController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isLocating = true;
      _locationMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Location services are disabled. Please enable them in settings.')),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Location permission permanently denied. Please enable it in settings.')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      final placemark = placemarks.isNotEmpty ? placemarks.first : null;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;

        if (placemark != null) {
          final street = [
            placemark.street,
            placemark.subLocality,
          ].where((p) => p != null && p.trim().isNotEmpty).join(', ');

          final postalCode = placemark.postalCode ?? '';
          final city = placemark.locality ?? placemark.subAdministrativeArea ?? '';
          final province = placemark.administrativeArea ?? '';

          if (street.isNotEmpty) {
            _streetController.text = street;
          }
          if (postalCode.trim().isNotEmpty) {
            _postalCodeController.text = postalCode.trim();
          }

          final supportedCities = ComplianceHelper.getSupportedCities();
          if (city.isNotEmpty) {
            final matchingCity = supportedCities.firstWhere(
              (c) => c.toLowerCase() == city.toLowerCase(),
              orElse: () => supportedCities.first,
            );
            _selectedCity = matchingCity;
          }

          final supportedProvinces = ComplianceHelper.getSupportedProvinces();
          if (province.isNotEmpty) {
            final matchingProvince = supportedProvinces.firstWhere(
              (p) => p.toLowerCase() == province.toLowerCase(),
              orElse: () => supportedProvinces.first,
            );
            _selectedProvince = matchingProvince;
          }

          _locationMessage = 'Address suggested from your location';
        } else {
          _locationMessage = 'Location picked: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        }
      });
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLocating = false;
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      debugPrint('❌ Cannot save address: No user logged in');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add an address')),
      );
      return;
    }

    final address = Address(
      id: widget.address?.id ?? const Uuid().v4(),
      userId: currentUser.id,
      label: _labelController.text.trim(),
      streetAddress: _streetController.text.trim(),
      city: _selectedCity,
      province: _selectedProvince,
      postalCode: _postalCodeController.text.trim(),
      latitude: _latitude ?? widget.address?.latitude ?? -26.2041,
      longitude: _longitude ?? widget.address?.longitude ?? 28.0473,
      isDefault: _isDefault,
    );

    debugPrint('📍 Saving address: ${address.label} for user ${currentUser.id}');
    widget.onSave(address);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.address == null ? 'Add Address' : 'Edit Address', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(labelText: 'Label (e.g., Home, Work)'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a label' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(labelText: 'Street Address'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter street address' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCity,
                decoration: const InputDecoration(labelText: 'City'),
                items: ComplianceHelper.getSupportedCities().map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
                onChanged: (value) => setState(() => _selectedCity = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedProvince,
                decoration: const InputDecoration(labelText: 'Province'),
                items: ComplianceHelper.getSupportedProvinces().map((province) => DropdownMenuItem(value: province, child: Text(province))).toList(),
                onChanged: (value) => setState(() => _selectedProvince = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _postalCodeController,
                decoration: const InputDecoration(labelText: 'Postal Code'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter postal code' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLocating ? null : _useCurrentLocation,
                      icon: _isLocating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(_isLocating ? 'Detecting location...' : 'Use current location'),
                    ),
                  ),
                ],
              ),
              if (_locationMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _locationMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              CheckboxListTile(
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value!),
                contentPadding: EdgeInsets.zero,
                title: const Text('Set as default address'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(widget.address == null ? 'Add Address' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
