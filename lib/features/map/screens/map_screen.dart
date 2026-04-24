import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:voyage_app/core/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/features/detail/screens/detail_screen.dart';

// List of hardcoded popular cities for map demo
final _demoCities = [
  {
    'nom': 'Paris',
    'pays': 'France',
    'continent': 'Europe',
    'lat': 48.8566,
    'lng': 2.3522,
    'rating': 4.9,
    'budget': 'Élevé',
    'image_url': 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?auto=format&fit=crop&q=80&w=600',
  },
  {
    'nom': 'Barcelone',
    'pays': 'Espagne',
    'continent': 'Europe',
    'lat': 41.3851,
    'lng': 2.1734,
    'rating': 4.7,
    'budget': 'Moyen',
    'image_url': 'https://images.unsplash.com/photo-1583422409516-2895a77efded?auto=format&fit=crop&q=80&w=600',
  },
  {
    'nom': 'Rome',
    'pays': 'Italie',
    'continent': 'Europe',
    'lat': 41.9028,
    'lng': 12.4964,
    'rating': 4.8,
    'budget': 'Moyen',
    'image_url': 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&q=80&w=600',
  },
  {
    'nom': 'Marrakech',
    'pays': 'Maroc',
    'continent': 'Afrique',
    'lat': 31.6295,
    'lng': -7.9811,
    'rating': 4.6,
    'budget': 'Faible',
    'image_url': 'https://images.unsplash.com/photo-1597212618440-806262de4f6b?auto=format&fit=crop&q=80&w=600',
  },
  {
    'nom': 'Le Caire',
    'pays': 'Égypte',
    'continent': 'Afrique',
    'lat': 30.0444,
    'lng': 31.2357,
    'rating': 4.5,
    'budget': 'Faible',
    'image_url': 'https://images.unsplash.com/photo-1572252009286-268caa20141a?auto=format&fit=crop&q=80&w=600',
  },
  {
    'nom': 'Le Cap',
    'pays': 'Afrique du Sud',
    'continent': 'Afrique',
    'lat': -33.9249,
    'lng': 18.4241,
    'rating': 4.8,
    'budget': 'Moyen',
    'image_url': 'https://images.unsplash.com/photo-1580060839134-75a5edca2e99?auto=format&fit=crop&q=80&w=600',
  },
  {
    'nom': 'Tokyo',
    'pays': 'Japon',
    'continent': 'Asie',
    'lat': 35.6762,
    'lng': 139.6503,
    'rating': 4.9,
    'budget': 'Élevé',
    'image_url': 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?auto=format&fit=crop&q=80&w=600',
  },
  {
    'nom': 'Bali',
    'pays': 'Indonésie',
    'continent': 'Asie',
    'lat': -8.4095,
    'lng': 115.1889,
    'rating': 4.8,
    'budget': 'Moyen',
    'image_url': 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&q=80&w=600',
  },
  {
    'nom': 'Bangkok',
    'pays': 'Thaïlande',
    'continent': 'Asie',
    'lat': 13.7563,
    'lng': 100.5018,
    'rating': 4.6,
    'budget': 'Faible',
    'image_url': 'https://images.unsplash.com/photo-1508009603885-247a8bc611ba?auto=format&fit=crop&q=80&w=600',
  },
];

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _selectedCity;
  Map<String, dynamic>? _dbCity; // The city object from Supabase
  bool _isSheetVisible = false;

  @override
  void initState() {
    super.initState();
  }

  Future<Map<String, dynamic>?> _getDbCity(String cityName) async {
    try {
      final res = await _supabase
          .from('villes')
          .select('*, pays(*)')
          .eq('nom', cityName)
          .maybeSingle();
      return res;
    } catch (e) {
      debugPrint('Error fetching city from DB: $e');
      return null;
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
        begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(
        begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);

    final Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _onMarkerTapped(Map<String, dynamic> city) async {
    final latLng = LatLng(city['lat'] as double, city['lng'] as double);
    
    // Zoom slightly in and move slightly down so the bottom sheet doesn't cover the marker
    final destLat = latLng.latitude - 1.5;
    
    _animatedMapMove(LatLng(destLat, latLng.longitude), 5.5);
    
    // Fetch DB city data for navigation
    final dbCity = await _getDbCity(city['nom'] as String);
    
    setState(() {
      _selectedCity = city;
      _dbCity = dbCity;
      _isSheetVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkNavy, // Keeps the dark theme while loading tiles
      body: Stack(
        children: [
          // 1. Interactive Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(30.0, 10.0), // Show EU/Africa roughly
              initialZoom: 2.5,
              minZoom: 2.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: (_, __) {
                if (_isSheetVisible) {
                  setState(() => _isSheetVisible = false);
                }
              },
            ),
            children: [
              TileLayer(
                // Ultra Dark Premium Map Tiles (CartoDB Dark Matter)
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              MarkerLayer(
                markers: _demoCities.map((city) {
                  return Marker(
                    point: LatLng(city['lat'] as double, city['lng'] as double),
                    width: 70,
                    height: 70,
                    child: _PulseMarker(
                      imageUrl: city['image_url'] as String,
                      color: AppTheme.limeGreen,
                      onTap: () => _onMarkerTapped(city),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // 2. Parallax Safe Area Gradient (top overlay)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0F1B2D).withOpacity(0.9),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Floating Bottom Content
          
          // FAB Close Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 24,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: _buildCloseFab(),
            ),
          ),
          
          // Glassmorphism Premium Bottom Sheet
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            bottom: _isSheetVisible ? 40 : -400,
            left: 20,
            right: 20,
            child: _selectedCity != null ? _buildGlassBottomSheet(_selectedCity!) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseFab() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildGlassBottomSheet(Map<String, dynamic> city) {
    final budgetColor = city['budget'] == 'Faible'
        ? const Color(0xFF4CAF50)
        : city['budget'] == 'Élevé'
            ? const Color(0xFFFF6B6B)
            : const Color(0xFFFFD97D);
            
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          setState(() => _isSheetVisible = false);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF162544).withOpacity(0.65), // Soft deep dark navy blur
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium Rounded Thumbnail
                    Hero(
                      tag: 'map_thumb_${city['nom']}',
                      child: Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            imageUrl: city['image_url'] as String,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            city['nom'] as String,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            city['pays'] as String,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Color(0xFFFFD97D), size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      city['rating'].toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: budgetColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: budgetColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  city['budget'] as String,
                                  style: TextStyle(
                                    color: budgetColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_dbCity != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(ville: _dbCity!),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Détails non disponibles pour cette ville')),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.limeGreen,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.limeGreen.withOpacity(0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Explorer',
                              style: TextStyle(
                                color: Color(0xFF0F1B2D),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
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

// ─────────────────────────────────────────────
// CUSTOM ANIMATED PULSE MARKER
// ─────────────────────────────────────────────
class _PulseMarker extends StatefulWidget {
  final String imageUrl;
  final Color color;
  final VoidCallback onTap;

  const _PulseMarker({
    required this.imageUrl,
    required this.color,
    required this.onTap,
  });

  @override
  State<_PulseMarker> createState() => _PulseMarkerState();
}

class _PulseMarkerState extends State<_PulseMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat(reverse: false);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.8 : 1.0, // Micro-bounce on tap
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 1. Soft Pulse Wave loop
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: (1.0 - _pulseAnimation.value) * 0.6,
                  child: Transform.scale(
                    scale: 1.0 + (_pulseAnimation.value * 1.8),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color,
                      ),
                    ),
                  ),
                );
              },
            ),
            
            // 2. Outer Pin solid glow
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.4),
                    blurRadius: 14,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            
            // 3. Inner Center Image
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0F1B2D), width: 2.5),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: widget.color.withOpacity(0.2)),
                  errorWidget: (_,__,___) => Container(
                    color: widget.color.withOpacity(0.2),
                    child: const Icon(Icons.location_city, size: 20, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
