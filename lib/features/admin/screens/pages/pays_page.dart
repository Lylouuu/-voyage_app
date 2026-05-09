import 'package:flutter/material.dart';
import 'package:voyage_app/features/admin/theme/admin_theme.dart';
import 'package:voyage_app/features/admin/services/admin_service.dart';
import 'package:voyage_app/features/admin/widgets/admin_widgets.dart';

/// Page CRUD complète pour la gestion des pays
class PaysPage extends StatefulWidget {
  const PaysPage({super.key});

  @override
  State<PaysPage> createState() => _PaysPageState();
}

class _PaysPageState extends State<PaysPage> {
  List<Map<String, dynamic>> _pays = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPays();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPays({String? search}) async {
    setState(() => _loading = true);
    try {
      final data = await AdminService.getPays(search: search);
      if (mounted) setState(() { _pays = data; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); showAdminSnack(context, 'Erreur: $e', isError: true); }
    }
  }

  void _showFormDialog({Map<String, dynamic>? existing}) {
    final nomC = TextEditingController(text: existing?['nom'] ?? '');
    final continentC = TextEditingController(text: existing?['continent'] ?? '');
    final langueC = TextEditingController(text: existing?['langue'] ?? '');
    final monnaieC = TextEditingController(text: existing?['monnaie'] ?? '');
    final climatC = TextEditingController(text: existing?['climat'] ?? '');
    final descC = TextEditingController(text: existing?['description'] ?? '');
    final imageC = TextEditingController(text: existing?['image_url'] ?? '');
    bool saving = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AdminFormModal(
          title: existing != null ? 'Modifier le pays' : 'Ajouter un pays',
          isLoading: saving,
          submitLabel: existing != null ? 'Mettre à jour' : 'Ajouter',
          fields: [
            TextField(
              controller: nomC,
              style: const TextStyle(color: AdminTheme.textPrimary),
              decoration: AdminTheme.inputDecoration(label: 'Nom du pays', icon: Icons.flag_rounded),
            ),
            TextField(
              controller: continentC,
              style: const TextStyle(color: AdminTheme.textPrimary),
              decoration: AdminTheme.inputDecoration(label: 'Continent', icon: Icons.public_rounded),
            ),
            TextField(
              controller: langueC,
              style: const TextStyle(color: AdminTheme.textPrimary),
              decoration: AdminTheme.inputDecoration(label: 'Langue', icon: Icons.language_rounded),
            ),
            TextField(
              controller: monnaieC,
              style: const TextStyle(color: AdminTheme.textPrimary),
              decoration: AdminTheme.inputDecoration(label: 'Monnaie', icon: Icons.monetization_on_rounded),
            ),
            TextField(
              controller: climatC,
              style: const TextStyle(color: AdminTheme.textPrimary),
              decoration: AdminTheme.inputDecoration(label: 'Climat', icon: Icons.wb_sunny_rounded),
            ),
            TextField(
              controller: descC,
              maxLines: 3,
              style: const TextStyle(color: AdminTheme.textPrimary),
              decoration: AdminTheme.inputDecoration(label: 'Description', icon: Icons.description_rounded),
            ),
            TextField(
              controller: imageC,
              style: const TextStyle(color: AdminTheme.textPrimary),
              decoration: AdminTheme.inputDecoration(label: 'URL de l\'image', icon: Icons.image_rounded),
            ),
          ],
          onSubmit: () async {
            if (nomC.text.isEmpty) return;
            setStateDialog(() => saving = true);
            try {
              final data = {
                'nom': nomC.text.trim(),
                'continent': continentC.text.trim(),
                'langue': langueC.text.trim(),
                'monnaie': monnaieC.text.trim(),
                'climat': climatC.text.trim(),
                'description': descC.text.trim(),
                'image_url': imageC.text.trim(),
              };
              if (existing != null) {
                await AdminService.updatePays(existing['id'].toString(), data);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) showAdminSnack(context, 'Pays modifié avec succès');
              } else {
                await AdminService.addPays(data);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) showAdminSnack(context, 'Pays ajouté avec succès');
              }
              _loadPays();
            } catch (e) {
              setStateDialog(() => saving = false);
              if (mounted) showAdminSnack(context, 'Erreur: $e', isError: true);
            }
          },
        ),
      ),
    );
  }

  Future<void> _deletePays(Map<String, dynamic> pays) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AdminConfirmDialog(
        title: 'Supprimer ce pays ?',
        message: '"${pays['nom']}" et toutes ses villes associées seront supprimés de manière irréversible.',
      ),
    );
    if (confirm == true) {
      try {
        await AdminService.deletePays(pays['id'].toString());
        if (mounted) showAdminSnack(context, 'Pays supprimé');
        _loadPays();
      } catch (e) {
        if (mounted) showAdminSnack(context, 'Erreur: $e', isError: true);
      }
    }
  }

  String _getFlagOrImage(Map<String, dynamic> p) {
    if (p['image_url'] != null && (p['image_url'] as String).isNotEmpty) {
      return p['image_url'];
    }
    
    final nom = (p['nom'] ?? '').toLowerCase().trim();
    
    // Traductions anglaises pour loremflickr
    final traductions = {
      'espagne': 'spain',
      'france': 'france',
      'algérie': 'algeria',
      'japon': 'japan',
      'thaïlande': 'thailand',
      'indonésie': 'indonesia',
      'maroc': 'morocco',
      'turquie': 'turkey',
      'maldives': 'maldives',
      'italie': 'italy',
    };
    
    final query = traductions[nom] ?? nom;
    // On utilise le tag 'city' ou 'landmark' pour que ce soit comme les villes
    return 'https://loremflickr.com/800/600/$query,landmark?lock=1';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── EN-TÊTE ET RECHERCHE ──
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AdminTheme.surface,
            border: Border(bottom: BorderSide(color: AdminTheme.surfaceBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => _loadPays(search: v),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un pays...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AdminTheme.textMuted),
                    filled: true,
                    fillColor: AdminTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showFormDialog(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nouveau Pays'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
        
        // ── GRILLE DE PAYS ──
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AdminTheme.accent))
              : _pays.isEmpty
                  ? const Center(child: Text('Aucun pays trouvé', style: AdminTheme.headingMd))
                  : GridView.builder(
                      padding: const EdgeInsets.all(24),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 350,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: _pays.length,
                      itemBuilder: (context, index) {
                        final p = _pays[index];
                        final imageUrl = _getFlagOrImage(p);
                        
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
                                Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(color: AdminTheme.surfaceLight),
                                ),
                                
                                // Dégradé sombre
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.1),
                                        Colors.black.withOpacity(0.85),
                                      ],
                                      stops: const [0.3, 1.0],
                                    ),
                                  ),
                                ),
                                
                                // Contenu de la carte
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Boutons d'action (haut)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          _buildGlassIconButton(Icons.edit_rounded, () => _showFormDialog(existing: p)),
                                          const SizedBox(width: 8),
                                          _buildGlassIconButton(Icons.delete_rounded, () => _deletePays(p), isDanger: true),
                                        ],
                                      ),
                                      
                                      const Spacer(),
                                      
                                      // Badges
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          if (p['continent'] != null && p['continent'].toString().isNotEmpty)
                                            _buildBadge(p['continent'], Icons.public_rounded, AdminTheme.info),
                                          if (p['monnaie'] != null && p['monnaie'].toString().isNotEmpty)
                                            _buildBadge(p['monnaie'], Icons.monetization_on_rounded, AdminTheme.warning),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 12),
                                      
                                      // Titre
                                      Text(
                                        p['nom'] ?? 'Inconnu',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          height: 1.1,
                                        ),
                                      ),
                                      
                                      if (p['langue'] != null && p['langue'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          'Langue : ${p['langue']}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
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
  }

  Widget _buildGlassIconButton(IconData icon, VoidCallback onTap, {bool isDanger = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDanger ? AdminTheme.danger.withOpacity(0.8) : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
