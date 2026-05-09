import 'package:flutter/material.dart';
import 'package:voyage_app/features/admin/theme/admin_theme.dart';
import 'package:voyage_app/features/admin/services/admin_service.dart';
import 'package:voyage_app/features/admin/widgets/admin_widgets.dart';

/// Page CRUD complète pour la gestion des villes
class VillesPage extends StatefulWidget {
  const VillesPage({super.key});

  @override
  State<VillesPage> createState() => _VillesPageState();
}

class _VillesPageState extends State<VillesPage> {
  List<Map<String, dynamic>> _villes = [];
  List<Map<String, dynamic>> _pays = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({String? search}) async {
    setState(() => _loading = true);
    try {
      final villes = await AdminService.getVilles(search: search);
      final pays = await AdminService.getPays();
      if (mounted) setState(() { _villes = villes; _pays = pays; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); showAdminSnack(context, 'Erreur: $e', isError: true); }
    }
  }

  void _showFormDialog({Map<String, dynamic>? existing}) {
    final nomC = TextEditingController(text: existing?['nom'] ?? '');
    final descC = TextEditingController(text: existing?['description'] ?? '');
    final budgetC = TextEditingController(text: existing?['niveau_budget'] ?? '');
    final popC = TextEditingController(text: existing?['popularite']?.toString() ?? '');
    final tempC = TextEditingController(text: existing?['temperature'] ?? '');
    final imageC = TextEditingController(text: existing?['image_url'] ?? '');
    String? selectedPaysId = existing?['id_pays']?.toString();
    bool saving = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AdminFormModal(
          title: existing != null ? 'Modifier la ville' : 'Ajouter une ville',
          isLoading: saving,
          submitLabel: existing != null ? 'Mettre à jour' : 'Ajouter',
          fields: [
            TextField(
              controller: nomC,
              style: const TextStyle(color: AdminTheme.textPrimary),
              decoration: AdminTheme.inputDecoration(label: 'Nom de la ville', icon: Icons.location_city_rounded),
            ),
            DropdownButtonFormField<String>(
              value: selectedPaysId,
              dropdownColor: AdminTheme.surfaceLight,
              style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 14),
              decoration: AdminTheme.inputDecoration(label: 'Pays', icon: Icons.flag_rounded),
              items: _pays.map((p) => DropdownMenuItem(
                value: p['id'].toString(),
                child: Text(p['nom'] ?? ''),
              )).toList(),
              onChanged: (v) => setStateDialog(() => selectedPaysId = v),
            ),
            TextField(
              controller: descC,
              maxLines: 3,
              style: const TextStyle(color: AdminTheme.textPrimary),
              decoration: AdminTheme.inputDecoration(label: 'Description', icon: Icons.description_rounded),
            ),
            DropdownButtonFormField<String>(
              value: budgetC.text.isNotEmpty ? budgetC.text : null,
              dropdownColor: AdminTheme.surfaceLight,
              style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 14),
              decoration: AdminTheme.inputDecoration(label: 'Niveau budget', icon: Icons.euro_rounded),
              items: ['Faible', 'Moyen', 'Élevé'].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (v) => budgetC.text = v ?? '',
            ),
            TextField(
              controller: popC,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AdminTheme.textPrimary),
              decoration: AdminTheme.inputDecoration(label: 'Popularité (0-5)', icon: Icons.star_rounded),
            ),
            TextField(
              controller: tempC,
              style: const TextStyle(color: AdminTheme.textPrimary),
              decoration: AdminTheme.inputDecoration(label: 'Température (ex: 25°C)', icon: Icons.thermostat_rounded),
            ),
            TextField(
              controller: imageC,
              style: const TextStyle(color: AdminTheme.textPrimary),
              decoration: AdminTheme.inputDecoration(label: 'URL de l\'image', icon: Icons.image_rounded),
            ),
          ],
          onSubmit: () async {
            if (nomC.text.isEmpty || selectedPaysId == null) return;
            setStateDialog(() => saving = true);
            try {
              final data = {
                'nom': nomC.text.trim(),
                'id_pays': selectedPaysId,
                'description': descC.text.trim(),
                'niveau_budget': budgetC.text.trim(),
                'popularite': double.tryParse(popC.text) ?? 4.0,
                'temperature': tempC.text.trim(),
                'image_url': imageC.text.trim(),
              };
              if (existing != null) {
                await AdminService.updateVille(existing['id'].toString(), data);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) showAdminSnack(context, 'Ville modifiée avec succès');
              } else {
                await AdminService.addVille(data);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) showAdminSnack(context, 'Ville ajoutée avec succès');
              }
              _loadData();
            } catch (e) {
              setStateDialog(() => saving = false);
              if (mounted) showAdminSnack(context, 'Erreur: $e', isError: true);
            }
          },
        ),
      ),
    );
  }

  Future<void> _deleteVille(Map<String, dynamic> ville) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AdminConfirmDialog(
        title: 'Supprimer cette ville ?',
        message: '"${ville['nom']}" sera supprimée de manière irréversible.',
      ),
    );
    if (confirm == true) {
      try {
        await AdminService.deleteVille(ville['id'].toString());
        if (mounted) showAdminSnack(context, 'Ville supprimée');
        _loadData();
      } catch (e) {
        if (mounted) showAdminSnack(context, 'Erreur: $e', isError: true);
      }
    }
  }

  String _getImageForCity(Map<String, dynamic> v) {
    if (v['image_url'] != null && (v['image_url'] as String).isNotEmpty) {
      return v['image_url'];
    }
    
    final nom = (v['nom'] ?? '').toLowerCase().trim();
    
    // Mapping pour les traductions anglaises
    final traductions = {
      'valence': 'valencia,spain',
      'grenade': 'granada,spain',
      'alger': 'algiers,algeria',
      'lyon': 'lyon,france',
      'bangkok': 'bangkok,thailand',
      'madrid': 'madrid,spain',
      'mont saint-michel': 'mont-saint-michel,france',
      'mont saint michel': 'mont-saint-michel,france',
      'tlemcen': 'tlemcen,algeria',
      'bali': 'bali,indonesia',
      'seville': 'seville,spain',
      'séville': 'seville,spain',
      'nice': 'nice,france',
      'bejaia': 'bejaia,algeria',
      'béjaïa': 'bejaia,algeria',
      'rome': 'rome,italy',
      'tokyo': 'tokyo,japan',
      'marrakech': 'marrakech,morocco',
      'bordeaux': 'bordeaux,france',
      'constantine': 'constantine,algeria',
      'oran': 'oran,algeria',
      'kyoto': 'kyoto,japan',
      'istanbul': 'istanbul,turkey',
      'bilbao': 'bilbao,spain',
      'malé': 'male,maldives',
      'male': 'male,maldives',
      'paris': 'paris,france',
      'tamanrasset': 'tamanrasset,algeria',
      'marseille': 'marseille,france',
    };
    
    final query = traductions[nom] ?? nom;
    return 'https://loremflickr.com/800/600/$query,city?lock=1';
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
                  onChanged: (v) => _loadData(search: v),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une ville...',
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
                label: const Text('Nouvelle Ville'),
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
        
        // ── GRILLE DE VILLES ──
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AdminTheme.accent))
              : _villes.isEmpty
                  ? const Center(child: Text('Aucune ville trouvée', style: AdminTheme.headingMd))
                  : GridView.builder(
                      padding: const EdgeInsets.all(24),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 350,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: _villes.length,
                      itemBuilder: (context, index) {
                        final v = _villes[index];
                        final imageUrl = _getImageForCity(v);
                        
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
                                          _buildGlassIconButton(Icons.edit_rounded, () => _showFormDialog(existing: v)),
                                          const SizedBox(width: 8),
                                          _buildGlassIconButton(Icons.delete_rounded, () => _deleteVille(v), isDanger: true),
                                        ],
                                      ),
                                      
                                      const Spacer(),
                                      
                                      // Badges
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          _buildBadge(v['pays']?['nom'] ?? 'Inconnu', Icons.public_rounded, AdminTheme.accent),
                                          _buildBudgetBadge(v['niveau_budget'] ?? 'Moyen'),
                                          _buildBadge('${v['popularite'] ?? '4.0'}/5', Icons.star_rounded, AdminTheme.warning),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 12),
                                      
                                      // Titre
                                      Text(
                                        v['nom'] ?? 'Inconnue',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          height: 1.1,
                                        ),
                                      ),
                                      
                                      if (v['temperature'] != null && v['temperature'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          'Climat : ${v['temperature']}',
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

  Widget _buildBudgetBadge(String level) {
    Color color;
    switch (level) {
      case 'Faible': color = AdminTheme.success; break;
      case 'Moyen': color = AdminTheme.warning; break;
      case 'Élevé': color = AdminTheme.danger; break;
      default: color = AdminTheme.textMuted;
    }
    return _buildBadge(level, Icons.euro_rounded, color);
  }
}
