import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/location_data.dart';
import '../theme/app_colors.dart';

// ─── Public LocationPickerField widget ────────────────────────────────────────

/// Tappable field that opens a dual-mode location picker (Search + Map).
/// Calls [onLocationSelected] with a [LocationData] when the user confirms,
/// or null when they clear the selection.
class LocationPickerField extends StatelessWidget {
  final LocationData? selectedLocation;
  final ValueChanged<LocationData?> onLocationSelected;

  const LocationPickerField({
    super.key,
    required this.selectedLocation,
    required this.onLocationSelected,
  });

  void _openPicker(BuildContext context, {int initialTab = 0}) async {
    final result = await showModalBottomSheet<LocationData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        // ── Wrap in a SizedBox with bounded height ──────────────────────────
        // This is critical: DraggableScrollableSheet causes infinite-width
        // layout errors when combined with nested TabBarView + ListView.
        // A fixed-height SizedBox gives all descendants proper constraints.
        final sheetHeight = MediaQuery.of(ctx).size.height * 0.90;
        return SizedBox(
          width: MediaQuery.of(ctx).size.width,
          height: sheetHeight,
          child: _LocationPickerSheet(
            initialLocation: selectedLocation,
            initialTab: initialTab,
          ),
        );
      },
    );
    if (result != null) onLocationSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = selectedLocation != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasLocation) ...[
          // ── Selected location preview card ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Location Selected',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => onLocationSelected(null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 13, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  selectedLocation!.address,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.my_location_rounded,
                        size: 11, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${selectedLocation!.lat.toStringAsFixed(5)}, '
                      '${selectedLocation!.lng.toStringAsFixed(5)}',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Change buttons row
          Row(
            children: [
              Expanded(
                child: _PickerButton(
                  icon: Icons.search_rounded,
                  label: 'Search Address',
                  onTap: () => _openPicker(context, initialTab: 0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PickerButton(
                  icon: Icons.map_rounded,
                  label: 'Pick on Map',
                  onTap: () => _openPicker(context, initialTab: 1),
                ),
              ),
            ],
          ),
        ] else ...[
          // ── No location — two entry points ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: _PickerButton(
                  icon: Icons.search_rounded,
                  label: 'Search Address',
                  onTap: () => _openPicker(context, initialTab: 0),
                  prominent: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PickerButton(
                  icon: Icons.pin_drop_rounded,
                  label: 'Pick on Map',
                  onTap: () => _openPicker(context, initialTab: 1),
                  prominent: true,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Entry button ─────────────────────────────────────────────────────────────

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool prominent;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: prominent
              ? AppColors.primary.withValues(alpha: 0.07)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: prominent
                ? AppColors.primary.withValues(alpha: 0.35)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: prominent
                    ? AppColors.primary
                    : AppColors.textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: prominent
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Sheet ─────────────────────────────────────────────────────────────

class _LocationPickerSheet extends StatefulWidget {
  final LocationData? initialLocation;
  final int initialTab;

  const _LocationPickerSheet({
    this.initialLocation,
    this.initialTab = 0,
  });

  @override
  State<_LocationPickerSheet> createState() =>
      _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LocationData? _currentSelection;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    // Rebuild when the active tab settles so the _ConfirmBar visibility
    // condition (_tabController.index == 0) is re-evaluated on every switch.
    _tabController.addListener(_onTabChanged);
    _currentSelection = widget.initialLocation;
  }

  void _onTabChanged() {
    // indexIsChanging is true while the tab is still animating;
    // only rebuild once it has settled on its final index.
    if (!_tabController.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onLocationPicked(LocationData loc) {
    // Must use mounted check before calling setState
    if (mounted) setState(() => _currentSelection = loc);
  }

  void _confirm() {
    Navigator.pop(context, _currentSelection);
  }

  @override
  Widget build(BuildContext context) {
    // The parent SizedBox already constrains height to 90% of screen.
    // We fill it with a rounded Container.
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Drag handle ─────────────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.place_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meeting Location',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        'Search or tap on the map',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Tab bar ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 13),
                unselectedLabelStyle:
                    GoogleFonts.inter(fontSize: 13),
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: 'Search Address'),
                  Tab(text: 'Pick on Map'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Tab content ──────────────────────────────────────────────────
          // Expanded fills remaining space with bounded constraints
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SearchTab(
                  initialLocation: _currentSelection,
                  onPicked: _onLocationPicked,
                ),
                _MapTab(
                  initialLocation: _currentSelection,
                  onPicked: _onLocationPicked,
                  onConfirm: _confirm,
                ),
              ],
            ),
          ),

          // ── Confirm bar (search tab only — map tab has its own button) ──
          // Only shown when the SEARCH tab is active and a location is chosen.
          // The Map tab embeds its confirm button directly in the address panel.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) => SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1.0,
              child: child,
            ),
            child: (_currentSelection != null &&
                    _tabController.index == 0)
                ? _ConfirmBar(
                    key: const ValueKey('confirm_bar'),
                    location: _currentSelection!,
                    onConfirm: _confirm,
                  )
                : const SizedBox.shrink(key: ValueKey('confirm_empty')),
          ),
        ],
      ),
    );
  }
}

// ─── Confirm bar ──────────────────────────────────────────────────────────────

class _ConfirmBar extends StatelessWidget {
  final LocationData location;
  final VoidCallback onConfirm;

  const _ConfirmBar({super.key, required this.location, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Address preview ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.address.isNotEmpty
                          ? location.address
                          : 'Selected Location',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${location.lat.toStringAsFixed(5)},  '
                      '${location.lng.toStringAsFixed(5)}',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Full-width confirm button ──
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: Text(
                'Confirm Location',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: Address Search ─────────────────────────────────────────────────────

class _SearchTab extends StatefulWidget {
  final LocationData? initialLocation;
  final ValueChanged<LocationData> onPicked;

  const _SearchTab({
    this.initialLocation,
    required this.onPicked,
  });

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  final _searchCtrl = TextEditingController();
  List<_NominatimResult> _results = [];
  bool _isLoading = false;
  String? _error;
  Timer? _debounce;
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedAddress = widget.initialLocation!.address;
      // Set text after frame to avoid triggering listener during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchCtrl.text = widget.initialLocation!.address;
      });
    }
    _searchCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }
    _debounce =
        Timer(const Duration(milliseconds: 550), () => _search(q));
  }

  Future<void> _search(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}&limit=8',
      );
      final res = await http
          .get(uri, headers: {'User-Agent': 'BantouApp/1.0'})
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? [];
        setState(() {
          _results = features
              .map((e) => _NominatimResult.fromPhotonJson(e as Map<String, dynamic>))
              .toList();
          _isLoading = false;
          if (_results.isEmpty) {
            _error = 'No locations found. Try a different search.';
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Search unavailable. Please try again.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Network error. Check your connection.';
      });
    }
  }

  void _select(_NominatimResult r) {
    final loc =
        LocationData(lat: r.lat, lng: r.lng, address: r.displayName);
    // Cancel any pending debounced search and temporarily remove the listener
    // before setting text to prevent a secondary setState / search cascade.
    _debounce?.cancel();
    _searchCtrl.removeListener(_onChanged);
    setState(() {
      _selectedAddress = r.displayName;
      _searchCtrl.text = r.displayName;
      _results = [];
      _error = null;
    });
    _searchCtrl.addListener(_onChanged);
    widget.onPicked(loc);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Type an address or place…',
                hintStyle: GoogleFonts.inter(
                    color: AppColors.textHint, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.primary, size: 20),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary),
                        ),
                      )
                    : _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                size: 18,
                                color: AppColors.textSecondary),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _results = [];
                                _error = null;
                                _selectedAddress = null;
                              });
                            },
                          )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 4),
              ),
            ),
          ),
        ),

        // Results list — Expanded gives bounded height
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              if (_error != null && _results.isEmpty && !_isLoading)
                _ErrorCard(message: _error!),
              if (_results.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${_results.length} results',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                ..._results.map((r) => _ResultTile(
                      result: r,
                      isSelected: _selectedAddress == r.displayName,
                      onTap: () => _select(r),
                    )),
              ],
              if (_results.isEmpty && !_isLoading && _error == null)
                _buildEmptyState(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F0E0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_rounded,
                  size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedAddress != null
                  ? 'Search to change location'
                  : 'Search for a place',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter a city, address, or landmark above',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 2: Interactive Map ───────────────────────────────────────────────────

class _MapTab extends StatefulWidget {
  final LocationData? initialLocation;
  final ValueChanged<LocationData> onPicked;
  /// Called when the user taps "Confirm Location" in the map address panel.
  final VoidCallback onConfirm;

  const _MapTab({
    this.initialLocation,
    required this.onPicked,
    required this.onConfirm,
  });

  @override
  State<_MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<_MapTab> {
  // Default to Casablanca, Morocco
  LatLng _markerPos = const LatLng(33.5731, -7.5898);
  bool _hasPin = false;
  bool _isGeocoding = false;
  String? _resolvedAddress;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _markerPos = LatLng(
        widget.initialLocation!.lat,
        widget.initialLocation!.lng,
      );
      _resolvedAddress = widget.initialLocation!.address;
      _hasPin = true;
    }
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    if (!mounted) return;
    setState(() {
      _isGeocoding = true;
      _resolvedAddress = null;
    });

    final fallback =
        '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';

    try {
      final uri = Uri.parse(
        'https://photon.komoot.io/reverse?lon=${pos.longitude}&lat=${pos.latitude}',
      );
      final res = await http
          .get(uri, headers: {'User-Agent': 'BantouApp/1.0'})
          .timeout(const Duration(seconds: 8));

      if (!mounted) return;

      String address = fallback;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? [];
        if (features.isNotEmpty) {
          final props = features.first['properties'] as Map<String, dynamic>;
          final name = props['name'] as String? ?? '';
          final city = props['city'] ?? props['state'] ?? '';
          final country = props['country'] ?? '';
          final parts = [name, city, country].where((e) => e.toString().isNotEmpty).toList();
          if (parts.isNotEmpty) {
            address = parts.join(', ');
          }
        }
      }

      setState(() {
        _resolvedAddress = address;
        _isGeocoding = false;
      });
      widget.onPicked(LocationData(
          lat: pos.latitude, lng: pos.longitude, address: address));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resolvedAddress = fallback;
        _isGeocoding = false;
      });
      widget.onPicked(LocationData(
          lat: pos.latitude, lng: pos.longitude, address: fallback));
    }
  }

  void _onMapTap(TapPosition _, LatLng latlng) {
    setState(() {
      _markerPos = latlng;
      _hasPin = true;
    });
    _reverseGeocode(latlng);
  }

  void _clearPin() {
    setState(() {
      _hasPin = false;
      _resolvedAddress = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Map ─────────────────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _markerPos,
                      initialZoom: _hasPin ? 14.5 : 5.0,
                      onTap: _onMapTap,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                        userAgentPackageName: 'com.bantou.app',
                        maxZoom: 19,
                      ),
                      if (_hasPin)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _markerPos,
                              width: 50,
                              height: 60,
                              alignment: Alignment.topCenter,
                              child: _AnimatedPin(
                                  key: ValueKey(_markerPos)),
                            ),
                          ],
                        ),
                    ],
                  ),
                  // Instruction overlay (before any pin is placed)
                  if (!_hasPin)
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              Colors.white.withValues(alpha: 0.93),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.08),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.touch_app_rounded,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tap anywhere on the map to place a pin',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Zoom controls
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Column(
                      children: [
                        _ZoomButton(
                          icon: Icons.add,
                          onTap: () => _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom + 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _ZoomButton(
                          icon: Icons.remove,
                          onTap: () => _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom - 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Address resolution panel ──────────────────────────────────────
        // Wrapped in AnimatedSwitcher+SizeTransition for the same reason as
        // _ConfirmBar above: avoids unlaid-out RenderBox hit-test crashes.
        // ── Address + Confirm panel ───────────────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1.0,
            child: child,
          ),
          child: _hasPin
              ? Container(
                  key: const ValueKey('address_panel'),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: _isGeocoding
                      // ── Resolving state ──
                      ? Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Resolving address…',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        )
                      // ── Resolved state: address + confirm button ──
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _resolvedAddress ?? 'Unknown location',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_markerPos.latitude.toStringAsFixed(5)},  '
                                        '${_markerPos.longitude.toStringAsFixed(5)}',
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                // Clear pin button
                                GestureDetector(
                                  onTap: _clearPin,
                                  child: const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Icon(Icons.close_rounded,
                                        color: AppColors.textSecondary,
                                        size: 20),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // ── Prominent Confirm Location button ──
                            SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: widget.onConfirm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                ),
                                icon: const Icon(
                                    Icons.check_circle_rounded,
                                    size: 20),
                                label: Text(
                                  'Confirm Location',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15),
                                ),
                              ),
                            ),
                          ],
                        ),
                )
              : const SizedBox.shrink(key: ValueKey('address_empty')),
        ),
      ],
    );
  }
}

// ─── Animated drop-pin ────────────────────────────────────────────────────────

class _AnimatedPin extends StatefulWidget {
  const _AnimatedPin({super.key});

  @override
  State<_AnimatedPin> createState() => _AnimatedPinState();
}

class _AnimatedPinState extends State<_AnimatedPin>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350));
    _bounce = Tween<double>(begin: -18, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.bounceOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _bounce.value),
        child: child,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.location_on_rounded,
                color: Colors.white, size: 20),
          ),
          Container(
            width: 8,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Zoom button ──────────────────────────────────────────────────────────────

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}

// ─── Error card ───────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC02)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFF57C00), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFFF57C00))),
          ),
        ],
      ),
    );
  }
}

// ─── Result tile ──────────────────────────────────────────────────────────────

class _ResultTile extends StatelessWidget {
  final _NominatimResult result;
  final bool isSelected;
  final VoidCallback onTap;

  const _ResultTile({
    required this.result,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          _iconForType(result.type),
          color: isSelected ? AppColors.primary : Colors.grey,
        ),
        title: Text(
          result.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        subtitle: result.shortAddress.isNotEmpty
            ? Text(
                result.shortAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
              )
            : null,
        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18) : null,
      ),
    );
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'city':
      case 'town':
      case 'village':
        return Icons.location_city_rounded;
      case 'hotel':
      case 'hostel':
        return Icons.hotel_rounded;
      case 'restaurant':
      case 'cafe':
      case 'bar':
        return Icons.restaurant_rounded;
      case 'school':
      case 'university':
        return Icons.school_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }
}

// ─── Nominatim result model ───────────────────────────────────────────────────

class _NominatimResult {
  final double lat;
  final double lng;
  final String displayName;
  final String name;
  final String shortAddress;
  final String? type;

  const _NominatimResult({
    required this.lat,
    required this.lng,
    required this.displayName,
    required this.name,
    required this.shortAddress,
    this.type,
  });

  factory _NominatimResult.fromPhotonJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>? ?? {};
    final geom = json['geometry'] as Map<String, dynamic>? ?? {};
    final coords = geom['coordinates'] as List<dynamic>? ?? [0.0, 0.0];
    
    final lng = (coords.isNotEmpty ? coords[0] : 0.0) as double;
    final lat = (coords.length > 1 ? coords[1] : 0.0) as double;
    
    final name = props['name'] as String? ?? '';
    final street = props['street'] as String?;
    final city = props['city'] as String? ?? props['state'] as String?;
    final country = props['country'] as String?;
    
    final parts = <String>[];
    if (street != null) parts.add(street);
    if (city != null && city != name) parts.add(city);
    if (country != null) parts.add(country);
    
    final shortAddress = parts.join(', ');
    final displayName = name.isNotEmpty 
        ? (shortAddress.isNotEmpty ? '$name, $shortAddress' : name)
        : shortAddress;

    return _NominatimResult(
      lat: lat,
      lng: lng,
      displayName: displayName.isNotEmpty ? displayName : 'Unknown Location',
      name: name.isNotEmpty ? name : (city ?? 'Location'),
      shortAddress: shortAddress,
      type: props['osm_value'] as String?,
    );
  }
}
