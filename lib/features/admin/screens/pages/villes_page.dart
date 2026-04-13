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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AdminDataTable(
          title: 'Gestion des villes',
          subtitle: '${_villes.length} villes enregistrées',
          addLabel: 'Ajouter une ville',
          onAdd: () => _showFormDialog(),
          searchController: _searchController,
          onSearch: (v) => _loadData(search: v),
          isLoading: _loading,
          columns: const ['Nom', 'Pays', 'Budget', 'Popularité', 'Température', 'Actions'],
          rows: _villes.map((v) => DataRow(cells: [
            DataCell(Row(children: [
              if (v['image_url'] != null && (v['image_url'] as String).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(v['image_url'], width: 36, height: 36, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 36, height: 36, color: AdminTheme.surfaceLight, child: const Icon(Icons.image, size: 16, color: AdminTheme.textMuted))),
                  ),
                ),
              Text(v['nom'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
            ])),
            DataCell(Text(v['pays']?['nom'] ?? '-')),
            DataCell(_BudgetBadge(level: v['niveau_budget'] ?? '-')),
            DataCell(Row(children: [
              const Icon(Icons.star_rounded, color: AdminTheme.warning, size: 16),
              const SizedBox(width: 4),
              Text('${v['popularite'] ?? '-'}'),
            ])),
            DataCell(Text(v['temperature'] ?? '-')),
            DataCell(AdminActionButtons(
              onEdit: () => _showFormDialog(existing: v),
              onDelete: () => _deleteVille(v),
            )),
          ])).toList(),
        ),
      ],
    );
  }
}

class _BudgetBadge extends StatelessWidget {
  final String level;
  const _BudgetBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (level) {
      case 'Faible': color = AdminTheme.success; break;
      case 'Moyen': color = AdminTheme.warning; break;
      case 'Élevé': color = AdminTheme.danger; break;
      default: color = AdminTheme.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AdminTheme.radiusSm,
      ),
      child: Text(level, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}
