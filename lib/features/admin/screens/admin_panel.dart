import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:voyage_app/features/admin/theme/admin_theme.dart';
import 'package:voyage_app/features/admin/services/admin_service.dart';
import 'package:voyage_app/features/admin/screens/admin_login_screen.dart';
import 'package:voyage_app/features/admin/screens/pages/dashboard_page.dart';
import 'package:voyage_app/features/admin/screens/pages/pays_page.dart';
import 'package:voyage_app/features/admin/screens/pages/villes_page.dart';
import 'package:voyage_app/features/admin/screens/pages/activites_page.dart';
import 'package:voyage_app/features/admin/screens/pages/monuments_page.dart';
import 'package:voyage_app/features/admin/screens/pages/restaurants_page.dart';
import 'package:voyage_app/features/admin/screens/pages/hotels_page.dart';
import 'package:voyage_app/features/admin/screens/pages/utilisateurs_page.dart';
import 'package:voyage_app/features/admin/screens/pages/avis_page.dart';
import 'package:voyage_app/features/admin/screens/pages/plans_voyage_page.dart';

/// Layout principal de l'admin panel avec sidebar + navbar + contenu dynamique
class AdminPanel extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const AdminPanel({super.key, required this.adminData});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0; // Index for Desktop Sidebar
  bool _sidebarCollapsed = false; // State for Desktop Sidebar
  int _mobileTab = 0; // Index for Mobile BottomNavigationBar

  final List<_SidebarItem> _menuItems = [
    _SidebarItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _SidebarItem(
        icon: Icons.public_rounded,
        label: 'Pays',
        imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=600&q=80'),
    _SidebarItem(
        icon: Icons.location_city_rounded,
        label: 'Villes',
        imageUrl: 'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=600&q=80'),
    _SidebarItem(
        icon: Icons.local_activity_rounded,
        label: 'Activités',
        imageUrl: 'https://images.unsplash.com/photo-1533105079780-92b9be482077?w=600&q=80'),
    _SidebarItem(
        icon: Icons.account_balance_rounded,
        label: 'Monuments',
        imageUrl: 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=600&q=80'),
    _SidebarItem(
        icon: Icons.restaurant_rounded,
        label: 'Restaurants',
        imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600&q=80'),
    _SidebarItem(
        icon: Icons.hotel_rounded,
        label: 'Hôtels',
        imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600&q=80'),
    _SidebarItem(
        icon: Icons.people_rounded,
        label: 'Utilisateurs',
        imageUrl: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=600&q=80'),
    _SidebarItem(
        icon: Icons.star_rounded,
        label: 'Avis',
        imageUrl: 'https://images.unsplash.com/photo-1516321497487-e288fb19713f?w=600&q=80'),
    _SidebarItem(
        icon: Icons.flight_rounded,
        label: 'Plans de voyage',
        imageUrl: 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=600&q=80'),
  ];

  Widget _getDesktopPage() {
    switch (_selectedIndex) {
      case 0: return const DashboardPage();
      case 1: return const PaysPage();
      case 2: return const VillesPage();
      case 3: return const ActivitesPage();
      case 4: return const MonumentsPage();
      case 5: return const RestaurantsPage();
      case 6: return const HotelsPage();
      case 7: return const UtilisateursPage();
      case 8: return const AvisPage();
      case 9: return const PlansVoyagePage();
      default: return const DashboardPage();
    }
  }

  // Gets the appropriate widget for the pushed mobile page wrapper
  Widget _getMobileSubPage(int index) {
    switch (index) {
      case 1: return const PaysPage();
      case 2: return const VillesPage();
      case 3: return const ActivitesPage();
      case 4: return const MonumentsPage();
      case 5: return const RestaurantsPage();
      case 6: return const HotelsPage();
      case 7: return const UtilisateursPage();
      case 8: return const AvisPage();
      case 9: return const PlansVoyagePage();
      default: return const SizedBox();
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: AdminTheme.radiusLg),
        title: const Text('Déconnexion',
            style: TextStyle(color: AdminTheme.textPrimary)),
        content: const Text('Voulez-vous vraiment vous déconnecter ?',
            style: TextStyle(color: AdminTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: AdminTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: AdminTheme.dangerButton,
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AdminService.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 768;

    if (isSmallScreen) {
      // ── LAYOUT MOBILE (FLUIDE AVEC BOTTOM NAVBAR) ──
      return Scaffold(
        backgroundColor: AdminTheme.background,
        bottomNavigationBar: Theme(
          data: ThemeData(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            backgroundColor: AdminTheme.surface,
            selectedItemColor: AdminTheme.accent,
            unselectedItemColor: AdminTheme.textMuted,
            currentIndex: _mobileTab,
            onTap: (i) => setState(() => _mobileTab = i),
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            elevation: 20,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Tableau bord'),
              BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Gestion'),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Compte'),
            ],
          ),
        ),
        body: SafeArea(
          child: _buildMobileBody(),
        ),
      );
    }

    // ── LAYOUT DESKTOP/WEB (SIDEBAR TRADITIONNELLE) ──
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AdminTheme.background,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(false),
                Expanded(child: _getDesktopPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── MOBILE VIEWS ───────────────────────────────────────────
  Widget _buildMobileBody() {
    switch (_mobileTab) {
      case 0: // Dashboard
        return Column(
          children: [
            _buildTopBar(true),
            const Expanded(child: DashboardPage()),
          ],
        );
      case 1: // Gestion (Grid)
        return Column(
          children: [
            // ── HEADER PREMIUM ──
            Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AdminTheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: AdminTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AdminTheme.accent.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 18),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Espace Gestion', style: TextStyle(color: AdminTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                        SizedBox(height: 4),
                        Text('Gérez l\'ensemble de vos données', style: TextStyle(color: AdminTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // ── GRILLE DE GESTION ──
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.05,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _menuItems.length - 1, // On exclut Dashboard
                itemBuilder: (ctx, i) {
                  final itemIndex = i + 1; // Index réel dans _menuItems
                  final item = _menuItems[itemIndex];
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: AdminTheme.radiusLg,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: AdminTheme.radiusLg,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Image de fond
                          if (item.imageUrl != null)
                            Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(color: AdminTheme.surfaceLight),
                            )
                          else
                            Container(color: AdminTheme.surfaceLight),

                          // Dégradé pour la lisibilité
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.1),
                                  Colors.black.withOpacity(0.75),
                                ],
                                stops: const [0.4, 1.0],
                              ),
                            ),
                          ),

                          // Contenu
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (routeCtx) => Scaffold(
                                      backgroundColor: AdminTheme.background,
                                      appBar: AppBar(
                                        backgroundColor: AdminTheme.surface,
                                        elevation: 0,
                                        iconTheme: const IconThemeData(color: AdminTheme.textPrimary),
                                        title: Text(item.label, style: const TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.bold)),
                                        centerTitle: true,
                                      ),
                                      body: SafeArea(
                                        child: _getMobileSubPage(itemIndex),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(item.icon, color: Colors.white, size: 20),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      item.label,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      case 2: // Compte / Settings
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // ── EN-TÊTE PROFIL ──
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  // Bannière (Cover)
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: AdminTheme.primaryGradient,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AdminTheme.accent.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                  
                  // Avatar flottant
                  Positioned(
                    bottom: -50,
                    child: Container(
                      padding: const EdgeInsets.all(4), // Bordure blanche autour de l'avatar
                      decoration: BoxDecoration(
                        color: AdminTheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: AdminTheme.surfaceLight,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (widget.adminData['nom'] ?? 'A')[0].toUpperCase(),
                            style: const TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 40),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 60), // Espace pour l'avatar flottant
              
              // ── INFORMATIONS UTILISATEUR ──
              Text(
                widget.adminData['nom'] ?? 'Administrateur',
                style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AdminTheme.accentSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.adminData['email'] ?? 'admin@voyage.app',
                  style: const TextStyle(color: AdminTheme.accent, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // ── LISTE DES PARAMÈTRES ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Paramètres', style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    const SizedBox(height: 16),
                    
                    _buildSettingsTile(icon: Icons.person_outline_rounded, title: 'Modifier le profil', onTap: () {}),
                    _buildSettingsTile(icon: Icons.notifications_none_rounded, title: 'Notifications', onTap: () {}),
                    _buildSettingsTile(icon: Icons.security_rounded, title: 'Sécurité et connexion', onTap: () {}),
                    
                    const SizedBox(height: 40),
                    
                    // ── BOUTON DÉCONNEXION ──
                    ElevatedButton(
                      onPressed: _handleLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.surface,
                        foregroundColor: AdminTheme.danger,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AdminTheme.danger, width: 1.5),
                        ),
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, size: 22),
                          SizedBox(width: 10),
                          Text('Déconnexion sécurisée', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }

  // Composant réutilisable pour les lignes de paramètres
  Widget _buildSettingsTile({required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.surfaceBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AdminTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AdminTheme.textSecondary, size: 22),
        ),
        title: Text(title, style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: AdminTheme.textMuted, fontSize: 13)) : null,
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AdminTheme.textMuted, size: 14),
      ),
    );
  }

  // ── SIDEBAR ─────────────────────────────────────────────────
  Widget _buildSidebar() {
    final width = _sidebarCollapsed ? 72.0 : 260.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: width,
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        border: Border(
          right: BorderSide(color: AdminTheme.surfaceBorder),
        ),
      ),
      child: Column(
        children: [
          // Logo
          Container(
            height: 72,
            padding: EdgeInsets.symmetric(
              horizontal: _sidebarCollapsed ? 12 : 20,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AdminTheme.primaryGradient,
                    borderRadius: AdminTheme.radiusMd,
                  ),
                  child: const Icon(Icons.flight_takeoff_rounded,
                      color: Colors.white, size: 20),
                ),
                if (!_sidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Voyage Admin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AdminTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),

          Container(height: 1, color: AdminTheme.surfaceBorder),
          const SizedBox(height: 8),

          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: List.generate(_menuItems.length, (i) {
                final item = _menuItems[i];
                final isSelected = i == _selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: AdminTheme.radiusMd,
                    child: InkWell(
                      borderRadius: AdminTheme.radiusMd,
                      onTap: () => setState(() => _selectedIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(
                          horizontal: _sidebarCollapsed ? 12 : 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AdminTheme.accentSoft
                              : Colors.transparent,
                          borderRadius: AdminTheme.radiusMd,
                          border: isSelected
                              ? Border.all(
                                  color: AdminTheme.accent.withOpacity(0.3))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color: isSelected
                                  ? AdminTheme.accent
                                  : AdminTheme.textMuted,
                            ),
                            if (!_sidebarCollapsed) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? AdminTheme.accent
                                        : AdminTheme.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          Container(height: 1, color: AdminTheme.surfaceBorder),

          // Collapse toggle
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              borderRadius: AdminTheme.radiusMd,
              onTap: () =>
                  setState(() => _sidebarCollapsed = !_sidebarCollapsed),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AdminTheme.surfaceLight,
                  borderRadius: AdminTheme.radiusMd,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _sidebarCollapsed
                          ? Icons.chevron_right_rounded
                          : Icons.chevron_left_rounded,
                      color: AdminTheme.textMuted,
                      size: 20,
                    ),
                    if (!_sidebarCollapsed) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'Réduire',
                        style: TextStyle(
                          color: AdminTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  // ── TOP BAR ─────────────────────────────────────────────────
  Widget _buildTopBar(bool isSmallScreen) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        border: Border(
          bottom: BorderSide(color: AdminTheme.surfaceBorder),
        ),
      ),
      child: Row(
        children: [
          // If on mobile (isSmallScreen), show a welcome text
          if (isSmallScreen)
            const Expanded(
              child: Text(
                'Administration',
                style: TextStyle(color: AdminTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),

          if (!isSmallScreen)
            Expanded(
              child: Text(
                _menuItems[_selectedIndex].label,
                style: AdminTheme.headingMd,
              ),
            ),

          // Admin info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AdminTheme.surfaceLight,
              borderRadius: AdminTheme.radiusMd,
              border: Border.all(color: AdminTheme.surfaceBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AdminTheme.primaryGradient,
                    borderRadius: AdminTheme.radiusSm,
                  ),
                  child: Center(
                    child: Text(
                      (widget.adminData['nom'] ?? 'A')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                if (!isSmallScreen) ...[
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.adminData['nom'] ?? 'Admin',
                        style: const TextStyle(
                          color: AdminTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(
                        'Administrateur',
                        style: TextStyle(
                          color: AdminTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Logout
          IconButton(
            onPressed: _handleLogout,
            tooltip: 'Déconnexion',
            icon: const Icon(Icons.logout_rounded,
                color: AdminTheme.danger, size: 20),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem {
  final IconData icon;
  final String label;
  final String? imageUrl;

  _SidebarItem({required this.icon, required this.label, this.imageUrl});
}
