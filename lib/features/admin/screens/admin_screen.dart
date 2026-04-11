import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  // Stats
  int _nbUsers = 0;
  int _nbVilles = 0;
  int _nbVoyages = 0;
  int _nbPays = 0;
  bool _loadingStats = true;

  // Listes
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _pays = [];
  List<Map<String, dynamic>> _villes = [];

  // Controllers
  final _nomPaysController = TextEditingController();
  final _continentController = TextEditingController();
  final _langueController = TextEditingController();
  final _monnaieController = TextEditingController();
  final _climatController = TextEditingController();
  final _descPaysController = TextEditingController();

  final _nomVilleController = TextEditingController();
  final _descVilleController = TextEditingController();
  final _tempController = TextEditingController();
  final _imageController = TextEditingController();
  final _budgetController = TextEditingController();
  String? _selectedPaysId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomPaysController.dispose();
    _continentController.dispose();
    _langueController.dispose();
    _monnaieController.dispose();
    _climatController.dispose();
    _descPaysController.dispose();
    _nomVilleController.dispose();
    _descVilleController.dispose();
    _tempController.dispose();
    _imageController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loadingStats = true);
    try {
      final users = await _supabase.from('utilisateurs').select();
      final villes = await _supabase
          .from('villes')
          .select('*, pays(nom)')
          .order('nom');
      final voyages = await _supabase.from('plans_voyage').select();
      final pays = await _supabase.from('pays').select().order('nom');

      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(users);
          _villes = List<Map<String, dynamic>>.from(villes);
          _pays = List<Map<String, dynamic>>.from(pays);
          _nbUsers = _users.length;
          _nbVilles = _villes.length;
          _nbVoyages = voyages.length;
          _nbPays = _pays.length;
          _loadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur admin: $e');
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _ajouterPays() async {
    if (_nomPaysController.text.isEmpty) return;
    try {
      await _supabase.from('pays').insert({
        'nom': _nomPaysController.text.trim(),
        'continent': _continentController.text.trim(),
        'langue': _langueController.text.trim(),
        'monnaie': _monnaieController.text.trim(),
        'climat': _climatController.text.trim(),
        'description': _descPaysController.text.trim(),
      });
      _nomPaysController.clear();
      _continentController.clear();
      _langueController.clear();
      _monnaieController.clear();
      _climatController.clear();
      _descPaysController.clear();
      _showSnack('✅ Pays ajouté !', AppTheme.primary);
      _loadAll();
    } catch (e) {
      _showSnack('Erreur: $e', AppTheme.coral);
    }
  }

  Future<void> _ajouterVille() async {
    if (_nomVilleController.text.isEmpty || _selectedPaysId == null) return;
    try {
      await _supabase.from('villes').insert({
        'nom': _nomVilleController.text.trim(),
        'id_pays': _selectedPaysId,
        'description': _descVilleController.text.trim(),
        'temperature': _tempController.text.trim(),
        'image_url': _imageController.text.trim(),
        'niveau_budget': _budgetController.text.trim(),
        'popularite': 4.0,
      });
      _nomVilleController.clear();
      _descVilleController.clear();
      _tempController.clear();
      _imageController.clear();
      _budgetController.clear();
      _selectedPaysId = null;
      _showSnack('✅ Ville ajoutée !', AppTheme.primary);
      _loadAll();
    } catch (e) {
      _showSnack('Erreur: $e', AppTheme.coral);
    }
  }

  Future<void> _supprimerPays(String id) async {
    final confirm = await _showConfirm('Supprimer ce pays ?');
    if (confirm == true) {
      await _supabase.from('pays').delete().eq('id', id);
      _showSnack('🗑️ Pays supprimé', AppTheme.coral);
      _loadAll();
    }
  }

  Future<void> _supprimerVille(String id) async {
    final confirm = await _showConfirm('Supprimer cette ville ?');
    if (confirm == true) {
      await _supabase.from('villes').delete().eq('id', id);
      _showSnack('🗑️ Ville supprimée', AppTheme.coral);
      _loadAll();
    }
  }

  Future<void> _bloquerUser(String id, bool bloquer) async {
    await _supabase
        .from('utilisateurs')
        .update({'role': bloquer ? 'bloque' : 'voyageur'})
        .eq('id', id);
    _showSnack(
      bloquer ? '🚫 Utilisateur bloqué' : '✅ Utilisateur débloqué',
      bloquer ? AppTheme.coral : AppTheme.primary,
    );
    _loadAll();
  }

  Future<void> _supprimerUser(String id) async {
    final confirm = await _showConfirm('Supprimer cet utilisateur ?');
    if (confirm == true) {
      await _supabase.from('utilisateurs').delete().eq('id', id);
      _showSnack('🗑️ Utilisateur supprimé', AppTheme.coral);
      _loadAll();
    }
  }

  Future<bool?> _showConfirm(String msg) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(msg),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFDC2626), Color(0xFF7C3AED)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚙️ Administration',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Gestion de l\'application',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats
                if (!_loadingStats)
                  Row(
                    children: [
                      _buildStat('$_nbUsers', 'Utilisateurs', '👥'),
                      _buildStat('$_nbPays', 'Pays', '🌍'),
                      _buildStat('$_nbVilles', 'Villes', '🏙️'),
                      _buildStat('$_nbVoyages', 'Voyages', '✈️'),
                    ],
                  ),
                const SizedBox(height: 16),
                // Tabs
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: '📊 Dashboard'),
                    Tab(text: '🌍 Pays'),
                    Tab(text: '🏙️ Villes'),
                    Tab(text: '👥 Utilisateurs'),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboard(),
                _buildGererPays(),
                _buildGererVilles(),
                _buildGererUsers(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── DASHBOARD ──────────────────────────────────────────────
  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vue d\'ensemble',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.dark,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildDashCard(
                '👥',
                'Utilisateurs',
                '$_nbUsers',
                const Color(0xFF0093E9),
              ),
              _buildDashCard('🌍', 'Pays', '$_nbPays', const Color(0xFF00C9B1)),
              _buildDashCard(
                '🏙️',
                'Villes',
                '$_nbVilles',
                const Color(0xFF7C3AED),
              ),
              _buildDashCard(
                '✈️',
                'Voyages',
                '$_nbVoyages',
                const Color(0xFFFF6B6B),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Derniers utilisateurs',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.dark,
            ),
          ),
          const SizedBox(height: 12),
          ..._users.take(5).map((u) => _buildUserTile(u, dashboard: true)),
        ],
      ),
    );
  }

  // ── GERER PAYS ─────────────────────────────────────────────
  Widget _buildGererPays() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Formulaire ajout
          _buildFormCard(
            title: '➕ Ajouter un pays',
            child: Column(
              children: [
                _buildField(_nomPaysController, 'Nom du pays', Icons.flag),
                _buildField(_continentController, 'Continent', Icons.public),
                _buildField(_langueController, 'Langue', Icons.language),
                _buildField(
                  _monnaieController,
                  'Monnaie',
                  Icons.monetization_on,
                ),
                _buildField(_climatController, 'Climat', Icons.wb_sunny),
                _buildField(
                  _descPaysController,
                  'Description',
                  Icons.description,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _ajouterPays,
                  child: const Text('✅ Ajouter le pays'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${_pays.length} pays enregistrés',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: 12),
          ..._pays.map((p) => _buildPaysCard(p)),
        ],
      ),
    );
  }

  // ── GERER VILLES ───────────────────────────────────────────
  Widget _buildGererVilles() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormCard(
            title: '➕ Ajouter une ville',
            child: Column(
              children: [
                _buildField(
                  _nomVilleController,
                  'Nom de la ville',
                  Icons.location_city,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedPaysId,
                  decoration: const InputDecoration(
                    labelText: 'Pays',
                    prefixIcon: Icon(Icons.flag, color: AppTheme.primary),
                  ),
                  items: _pays.map((p) {
                    return DropdownMenuItem<String>(
                      value: p['id'].toString(),
                      child: Text(p['nom'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedPaysId = v),
                ),
                _buildField(
                  _descVilleController,
                  'Description',
                  Icons.description,
                  maxLines: 3,
                ),
                _buildField(
                  _tempController,
                  'Température (ex: 25°C)',
                  Icons.thermostat,
                ),
                _buildField(_imageController, 'URL de l\'image', Icons.image),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Niveau budget',
                    prefixIcon: Icon(Icons.euro, color: AppTheme.primary),
                  ),
                  items: ['Faible', 'Moyen', 'Élevé'].map((b) {
                    return DropdownMenuItem(value: b, child: Text(b));
                  }).toList(),
                  onChanged: (v) => _budgetController.text = v ?? '',
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _ajouterVille,
                  child: const Text('✅ Ajouter la ville'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${_villes.length} villes enregistrées',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: 12),
          ..._villes.map((v) => _buildVilleCard(v)),
        ],
      ),
    );
  }

  // ── GERER USERS ────────────────────────────────────────────
  Widget _buildGererUsers() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_users.length} utilisateurs',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: 12),
          ..._users.map((u) => _buildUserTile(u)),
        ],
      ),
    );
  }

  // ── WIDGETS ────────────────────────────────────────────────
  Widget _buildStat(String val, String label, String emoji) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            Text(
              val,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashCard(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.dark,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: AppTheme.dark),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
        ),
      ),
    );
  }

  Widget _buildPaysCard(Map<String, dynamic> pays) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          const Text('🌍', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pays['nom'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.dark,
                  ),
                ),
                Text(
                  pays['continent'] ?? '',
                  style: TextStyle(fontSize: 12, color: AppTheme.muted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _supprimerPays(pays['id'].toString()),
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildVilleCard(Map<String, dynamic> ville) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          const Text('🏙️', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ville['nom'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.dark,
                  ),
                ),
                Text(
                  ville['pays']?['nom'] ?? '',
                  style: TextStyle(fontSize: 12, color: AppTheme.muted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _supprimerVille(ville['id'].toString()),
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, {bool dashboard = false}) {
    final isBloque = user['role'] == 'bloque';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBloque
              ? AppTheme.coral.withValues(alpha: 0.3)
              : Colors.grey.shade100,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isBloque
                  ? AppTheme.coral.withValues(alpha: 0.1)
                  : AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                (user['nom'] ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isBloque ? AppTheme.coral : AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['nom'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.dark,
                  ),
                ),
                Text(
                  user['email'] ?? '',
                  style: TextStyle(fontSize: 11, color: AppTheme.muted),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isBloque)
                  const Text(
                    '🚫 Bloqué',
                    style: TextStyle(fontSize: 11, color: Colors.red),
                  ),
              ],
            ),
          ),
          if (!dashboard) ...[
            IconButton(
              onPressed: () => _bloquerUser(user['id'].toString(), !isBloque),
              icon: Icon(
                isBloque ? Icons.lock_open : Icons.block,
                color: isBloque ? AppTheme.primary : AppTheme.coral,
                size: 20,
              ),
            ),
            IconButton(
              onPressed: () => _supprimerUser(user['id'].toString()),
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
