import 'package:flutter/material.dart';
import 'package:voyage_app/features/admin/theme/admin_theme.dart';
import 'package:voyage_app/features/admin/services/admin_service.dart';
import 'package:voyage_app/features/admin/widgets/admin_widgets.dart';

/// Page CRUD complète pour la gestion des restaurants
class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({super.key});

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  List<Map<String, dynamic>> _restaurants = [];
  List<Map<String, dynamic>> _villes = [];
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
      final restaurants = await AdminService.getRestaurants(search: search);
      final villes = await AdminService.getVilles();
      if (mounted) setState(() { _restaurants = restaurants; _villes = villes; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); showAdminSnack(context, 'Erreur: $e', isError: true); }
    }
  }

  void _showFormDialog({Map<String, dynamic>? existing}) {
    final nomC = TextEditingController(text: existing?['nom'] ?? '');
    final typeC = TextEditingController(text: existing?['type_cuisine'] ?? '');
    final prixC = TextEditingController(text: existing?['prix_moyen']?.toString() ?? '');
    final descC = TextEditingController(text: existing?['description'] ?? '');
    final imageC = TextEditingController(text: existing?['image_url'] ?? '');
    String? selectedVilleId = existing?['id_ville']?.toString();
    bool saving = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AdminFormModal(
          title: existing != null ? 'Modifier le restaurant' : 'Ajouter un restaurant',
          isLoading: saving,
          submitLabel: existing != null ? 'Mettre à jour' : 'Ajouter',
          fields: [
            TextField(
              controller: nomC,
              style: const TextStyle(color: AdminTheme.textPrimary),
              decoration: AdminTheme.inputDecoration(label: 'Nom du restaurant', icon: Icons.restaurant_rounded),
            ),
            TextField(
              controller: typeC,
              style: const TextStyle(color: AdminTheme.textPrimary),
              decoration: AdminTheme.inputDecoration(label: 'Type de cuisine', icon: Icons.local_dining_rounded),
            ),
            DropdownButtonFormField<String>(
              value: selectedVilleId,
              dropdownColor: AdminTheme.surfaceLight,
              style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 14),
              decoration: AdminTheme.inputDecoration(label: 'Ville', icon: Icons.location_city_rounded),
              items: _villes.map((v) => DropdownMenuItem(
                value: v['id'].toString(),
                child: Text(v['nom'] ?? ''),
              )).toList(),
              onChanged: (v) => setStateDialog(() => selectedVilleId = v),
            ),
            TextField(
              controller: prixC,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AdminTheme.textPrimary),
              decoration: AdminTheme.inputDecoration(label: 'Prix moyen (€)', icon: Icons.euro_rounded),
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
            if (nomC.text.isEmpty || selectedVilleId == null) return;
            setStateDialog(() => saving = true);
            try {
              final data = {
                'nom': nomC.text.trim(),
                'type_cuisine': typeC.text.trim(),
                'id_ville': selectedVilleId,
                'prix_moyen': double.tryParse(prixC.text) ?? 0,
                'description': descC.text.trim(),
                'image_url': imageC.text.trim(),
              };
              if (existing != null) {
                await AdminService.updateRestaurant(existing['id'].toString(), data);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) showAdminSnack(context, 'Restaurant modifié avec succès');
              } else {
                await AdminService.addRestaurant(data);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) showAdminSnack(context, 'Restaurant ajouté avec succès');
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

  Future<void> _deleteRestaurant(Map<String, dynamic> rest) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AdminConfirmDialog(
        title: 'Supprimer ce restaurant ?',
        message: '"${rest['nom']}" sera supprimé de manière irréversible.',
      ),
    );
    if (confirm == true) {
      try {
        await AdminService.deleteRestaurant(rest['id'].toString());
        if (mounted) showAdminSnack(context, 'Restaurant supprimé');
        _loadData();
      } catch (e) {
        if (mounted) showAdminSnack(context, 'Erreur: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AdminDataTable(
        title: 'Gestion des restaurants',
        subtitle: '${_restaurants.length} restaurants enregistrés',
        addLabel: 'Ajouter un restaurant',
        onAdd: () => _showFormDialog(),
        searchController: _searchController,
        onSearch: (v) => _loadData(search: v),
        isLoading: _loading,
        columns: const ['Nom', 'Cuisine', 'Ville', 'Prix moyen', 'Actions'],
        rows: _restaurants.map((r) => DataRow(cells: [
          DataCell(Row(children: [
            if (r['image_url'] != null && (r['image_url'] as String).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(r['image_url'], width: 36, height: 36, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 36, height: 36, color: AdminTheme.surfaceLight, child: const Icon(Icons.image, size: 16, color: AdminTheme.textMuted))),
                ),
              ),
            Text(r['nom'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
          ])),
          DataCell(Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AdminTheme.dangerSoft, borderRadius: AdminTheme.radiusSm),
            child: Text(r['type_cuisine'] ?? '-', style: const TextStyle(color: AdminTheme.danger, fontSize: 12, fontWeight: FontWeight.w500)),
          )),
          DataCell(Text(r['villes']?['nom'] ?? '-')),
          DataCell(Text(r['prix_moyen'] != null ? '${r['prix_moyen']}€' : '-')),
          DataCell(AdminActionButtons(
            onEdit: () => _showFormDialog(existing: r),
            onDelete: () => _deleteRestaurant(r),
          )),
        ])).toList(),
      ),
    );
  }
}
