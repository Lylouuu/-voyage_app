import 'package:flutter/material.dart';
import 'package:voyage_app/features/admin/theme/admin_theme.dart';
import 'package:voyage_app/features/admin/services/admin_service.dart';
import 'package:voyage_app/features/admin/widgets/admin_widgets.dart';

/// Page CRUD complète pour la gestion des monuments
class MonumentsPage extends StatefulWidget {
  const MonumentsPage({super.key});

  @override
  State<MonumentsPage> createState() => _MonumentsPageState();
}

class _MonumentsPageState extends State<MonumentsPage> {
  List<Map<String, dynamic>> _monuments = [];
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
      final monuments = await AdminService.getMonuments(search: search);
      final villes = await AdminService.getVilles();
      if (mounted) setState(() { _monuments = monuments; _villes = villes; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); showAdminSnack(context, 'Erreur: $e', isError: true); }
    }
  }

  void _showFormDialog({Map<String, dynamic>? existing}) {
    final nomC = TextEditingController(text: existing?['nom'] ?? '');
    final typeC = TextEditingController(text: existing?['type'] ?? '');
    final descC = TextEditingController(text: existing?['description'] ?? '');
    final imageC = TextEditingController(text: existing?['image_url'] ?? '');
    String? selectedVilleId = existing?['id_ville']?.toString();
    bool saving = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AdminFormModal(
          title: existing != null ? 'Modifier le monument' : 'Ajouter un monument',
          isLoading: saving,
          submitLabel: existing != null ? 'Mettre à jour' : 'Ajouter',
          fields: [
            TextField(
              controller: nomC,
              style: const TextStyle(color: AdminTheme.textPrimary),
              decoration: AdminTheme.inputDecoration(label: 'Nom du monument', icon: Icons.account_balance_rounded),
            ),
            TextField(
              controller: typeC,
              style: const TextStyle(color: AdminTheme.textPrimary),
              decoration: AdminTheme.inputDecoration(label: 'Type (ex: Historique, Religieux...)', icon: Icons.label_rounded),
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
                'type': typeC.text.trim(),
                'id_ville': selectedVilleId,
                'description': descC.text.trim(),
                'image_url': imageC.text.trim(),
              };
              if (existing != null) {
                await AdminService.updateMonument(existing['id'].toString(), data);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) showAdminSnack(context, 'Monument modifié avec succès');
              } else {
                await AdminService.addMonument(data);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) showAdminSnack(context, 'Monument ajouté avec succès');
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

  Future<void> _deleteMonument(Map<String, dynamic> mon) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AdminConfirmDialog(
        title: 'Supprimer ce monument ?',
        message: '"${mon['nom']}" sera supprimé de manière irréversible.',
      ),
    );
    if (confirm == true) {
      try {
        await AdminService.deleteMonument(mon['id'].toString());
        if (mounted) showAdminSnack(context, 'Monument supprimé');
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
        title: 'Gestion des monuments',
        subtitle: '${_monuments.length} monuments enregistrés',
        addLabel: 'Ajouter un monument',
        onAdd: () => _showFormDialog(),
        searchController: _searchController,
        onSearch: (v) => _loadData(search: v),
        isLoading: _loading,
        columns: const ['Nom', 'Type', 'Ville', 'Actions'],
        rows: _monuments.map((m) => DataRow(cells: [
          DataCell(Row(children: [
            if (m['image_url'] != null && (m['image_url'] as String).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(m['image_url'], width: 36, height: 36, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 36, height: 36, color: AdminTheme.surfaceLight, child: const Icon(Icons.image, size: 16, color: AdminTheme.textMuted))),
                ),
              ),
            Text(m['nom'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
          ])),
          DataCell(Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0x1AE040FB), borderRadius: AdminTheme.radiusSm),
            child: Text(m['type'] ?? '-', style: const TextStyle(color: Color(0xFFE040FB), fontSize: 12, fontWeight: FontWeight.w500)),
          )),
          DataCell(Text(m['villes']?['nom'] ?? '-')),
          DataCell(AdminActionButtons(
            onEdit: () => _showFormDialog(existing: m),
            onDelete: () => _deleteMonument(m),
          )),
        ])).toList(),
      ),
    );
  }
}
