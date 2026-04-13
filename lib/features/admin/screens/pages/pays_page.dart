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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AdminDataTable(
          title: 'Gestion des pays',
          subtitle: '${_pays.length} pays enregistrés',
          addLabel: 'Ajouter un pays',
          onAdd: () => _showFormDialog(),
          searchController: _searchController,
          onSearch: (v) => _loadPays(search: v),
          isLoading: _loading,
          columns: const ['Nom', 'Continent', 'Langue', 'Monnaie', 'Climat', 'Actions'],
          rows: _pays.map((p) => DataRow(cells: [
            DataCell(Row(children: [
              if (p['image_url'] != null && (p['image_url'] as String).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(p['image_url'], width: 36, height: 36, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 36, height: 36, color: AdminTheme.surfaceLight, child: const Icon(Icons.image, size: 16, color: AdminTheme.textMuted))),
                  ),
                ),
              Text(p['nom'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
            ])),
            DataCell(Text(p['continent'] ?? '-')),
            DataCell(Text(p['langue'] ?? '-')),
            DataCell(Text(p['monnaie'] ?? '-')),
            DataCell(Text(p['climat'] ?? '-')),
            DataCell(AdminActionButtons(
              onEdit: () => _showFormDialog(existing: p),
              onDelete: () => _deletePays(p),
            )),
          ])).toList(),
        ),
      ],
    );
  }
}
