import 'package:flutter/material.dart';
import 'package:voyage_app/features/admin/theme/admin_theme.dart';
import 'package:voyage_app/features/admin/services/admin_service.dart';
import 'package:voyage_app/features/admin/widgets/admin_widgets.dart';

/// Page CRUD complète pour la gestion des activités
class ActivitesPage extends StatefulWidget {
  const ActivitesPage({super.key});

  @override
  State<ActivitesPage> createState() => _ActivitesPageState();
}

class _ActivitesPageState extends State<ActivitesPage> {
  List<Map<String, dynamic>> _activites = [];
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
      final activites = await AdminService.getActivites(search: search);
      final villes = await AdminService.getVilles();
      if (mounted) setState(() { _activites = activites; _villes = villes; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); showAdminSnack(context, 'Erreur: $e', isError: true); }
    }
  }

  void _showFormDialog({Map<String, dynamic>? existing}) {
    final nomC = TextEditingController(text: existing?['nom'] ?? '');
    final catC = TextEditingController(text: existing?['categorie'] ?? '');
    final prixC = TextEditingController(text: existing?['prix']?.toString() ?? '');
    final dureeC = TextEditingController(text: existing?['duree'] ?? '');
    final descC = TextEditingController(text: existing?['description'] ?? '');
    final imageC = TextEditingController(text: existing?['image_url'] ?? '');
    String? selectedVilleId = existing?['id_ville']?.toString();
    bool saving = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AdminFormModal(
          title: existing != null ? 'Modifier l\'activité' : 'Ajouter une activité',
          isLoading: saving,
          submitLabel: existing != null ? 'Mettre à jour' : 'Ajouter',
          fields: [
            TextField(
              controller: nomC,
              style: const TextStyle(color: AdminTheme.textPrimary),
              decoration: AdminTheme.inputDecoration(label: 'Nom de l\'activité', icon: Icons.local_activity_rounded),
            ),
            TextField(
              controller: catC,
              style: const TextStyle(color: AdminTheme.textPrimary),
              decoration: AdminTheme.inputDecoration(label: 'Catégorie', icon: Icons.category_rounded),
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
              decoration: AdminTheme.inputDecoration(label: 'Prix (€)', icon: Icons.euro_rounded),
            ),
            TextField(
              controller: dureeC,
              style: const TextStyle(color: AdminTheme.textPrimary),
              decoration: AdminTheme.inputDecoration(label: 'Durée (ex: 2h)', icon: Icons.timer_rounded),
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
                'categorie': catC.text.trim(),
                'id_ville': selectedVilleId,
                'prix': double.tryParse(prixC.text) ?? 0,
                'duree': dureeC.text.trim(),
                'description': descC.text.trim(),
                'image_url': imageC.text.trim(),
              };
              if (existing != null) {
                await AdminService.updateActivite(existing['id'].toString(), data);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) showAdminSnack(context, 'Activité modifiée avec succès');
              } else {
                await AdminService.addActivite(data);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) showAdminSnack(context, 'Activité ajoutée avec succès');
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

  Future<void> _deleteActivite(Map<String, dynamic> act) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AdminConfirmDialog(
        title: 'Supprimer cette activité ?',
        message: '"${act['nom']}" sera supprimée de manière irréversible.',
      ),
    );
    if (confirm == true) {
      try {
        await AdminService.deleteActivite(act['id'].toString());
        if (mounted) showAdminSnack(context, 'Activité supprimée');
        _loadData();
      } catch (e) {
        if (mounted) showAdminSnack(context, 'Erreur: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AdminDataTable(
          title: 'Gestion des activités',
          subtitle: '${_activites.length} activités enregistrées',
          addLabel: 'Ajouter une activité',
          onAdd: () => _showFormDialog(),
          searchController: _searchController,
          onSearch: (v) => _loadData(search: v),
          isLoading: _loading,
          columns: const ['Nom', 'Catégorie', 'Ville', 'Prix', 'Durée', 'Actions'],
          rows: _activites.map((a) => DataRow(cells: [
            DataCell(Row(children: [
              if (a['image_url'] != null && (a['image_url'] as String).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(a['image_url'], width: 36, height: 36, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 36, height: 36, color: AdminTheme.surfaceLight, child: const Icon(Icons.image, size: 16, color: AdminTheme.textMuted))),
                  ),
                ),
              Text(a['nom'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
            ])),
            DataCell(Text(a['categorie'] ?? '-')),
            DataCell(Text(a['villes']?['nom'] ?? '-')),
            DataCell(Text(a['prix'] != null ? '${a['prix']}€' : '-')),
            DataCell(Text(a['duree'] ?? '-')),
            DataCell(AdminActionButtons(
              onEdit: () => _showFormDialog(existing: a),
              onDelete: () => _deleteActivite(a),
            )),
          ])).toList(),
        ),
      ],
    );
  }
}
