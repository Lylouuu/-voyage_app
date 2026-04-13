import 'package:flutter/material.dart';
import 'package:voyage_app/features/admin/theme/admin_theme.dart';
import 'package:voyage_app/features/admin/services/admin_service.dart';
import 'package:voyage_app/features/admin/widgets/admin_widgets.dart';

/// Page CRUD complète pour la gestion des hôtels
class HotelsPage extends StatefulWidget {
  const HotelsPage({super.key});

  @override
  State<HotelsPage> createState() => _HotelsPageState();
}

class _HotelsPageState extends State<HotelsPage> {
  List<Map<String, dynamic>> _hotels = [];
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
      final hotels = await AdminService.getHotels(search: search);
      final villes = await AdminService.getVilles();
      if (mounted) setState(() { _hotels = hotels; _villes = villes; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); showAdminSnack(context, 'Erreur: $e', isError: true); }
    }
  }

  void _showFormDialog({Map<String, dynamic>? existing}) {
    final nomC = TextEditingController(text: existing?['nom'] ?? '');
    final etoilesC = TextEditingController(text: existing?['etoiles']?.toString() ?? '');
    final prixC = TextEditingController(text: existing?['prix']?.toString() ?? '');
    final descC = TextEditingController(text: existing?['description'] ?? '');
    final imageC = TextEditingController(text: existing?['image_url'] ?? '');
    String? selectedVilleId = existing?['id_ville']?.toString();
    bool saving = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AdminFormModal(
          title: existing != null ? 'Modifier l\'hôtel' : 'Ajouter un hôtel',
          isLoading: saving,
          submitLabel: existing != null ? 'Mettre à jour' : 'Ajouter',
          fields: [
            TextField(
              controller: nomC,
              style: const TextStyle(color: AdminTheme.textPrimary),
              decoration: AdminTheme.inputDecoration(label: 'Nom de l\'hôtel', icon: Icons.hotel_rounded),
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
            DropdownButtonFormField<int>(
              value: existing?['etoiles'] != null ? int.tryParse(existing!['etoiles'].toString()) : null,
              dropdownColor: AdminTheme.surfaceLight,
              style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 14),
              decoration: AdminTheme.inputDecoration(label: 'Étoiles', icon: Icons.star_rounded),
              items: [1, 2, 3, 4, 5].map((e) => DropdownMenuItem(
                value: e,
                child: Text('${'⭐' * e} ($e étoile${e > 1 ? 's' : ''})'),
              )).toList(),
              onChanged: (v) => etoilesC.text = v?.toString() ?? '',
            ),
            TextField(
              controller: prixC,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AdminTheme.textPrimary),
              decoration: AdminTheme.inputDecoration(label: 'Prix par nuit (€)', icon: Icons.euro_rounded),
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
                'id_ville': selectedVilleId,
                'etoiles': int.tryParse(etoilesC.text) ?? 3,
                'prix': double.tryParse(prixC.text) ?? 0,
                'description': descC.text.trim(),
                'image_url': imageC.text.trim(),
              };
              if (existing != null) {
                await AdminService.updateHotel(existing['id'].toString(), data);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) showAdminSnack(context, 'Hôtel modifié avec succès');
              } else {
                await AdminService.addHotel(data);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) showAdminSnack(context, 'Hôtel ajouté avec succès');
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

  Future<void> _deleteHotel(Map<String, dynamic> hotel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AdminConfirmDialog(
        title: 'Supprimer cet hôtel ?',
        message: '"${hotel['nom']}" sera supprimé de manière irréversible.',
      ),
    );
    if (confirm == true) {
      try {
        await AdminService.deleteHotel(hotel['id'].toString());
        if (mounted) showAdminSnack(context, 'Hôtel supprimé');
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
        title: 'Gestion des hôtels',
        subtitle: '${_hotels.length} hôtels enregistrés',
        addLabel: 'Ajouter un hôtel',
        onAdd: () => _showFormDialog(),
        searchController: _searchController,
        onSearch: (v) => _loadData(search: v),
        isLoading: _loading,
        columns: const ['Nom', 'Ville', 'Étoiles', 'Prix/nuit', 'Actions'],
        rows: _hotels.map((h) => DataRow(cells: [
          DataCell(Row(children: [
            if (h['image_url'] != null && (h['image_url'] as String).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(h['image_url'], width: 36, height: 36, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 36, height: 36, color: AdminTheme.surfaceLight, child: const Icon(Icons.image, size: 16, color: AdminTheme.textMuted))),
                ),
              ),
            Text(h['nom'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
          ])),
          DataCell(Text(h['villes']?['nom'] ?? '-')),
          DataCell(Row(
            children: List.generate(
              (h['etoiles'] is int ? h['etoiles'] : int.tryParse(h['etoiles']?.toString() ?? '0') ?? 0).clamp(0, 5),
              (_) => const Icon(Icons.star_rounded, color: AdminTheme.warning, size: 16),
            ),
          )),
          DataCell(Text(h['prix'] != null ? '${h['prix']}€' : '-')),
          DataCell(AdminActionButtons(
            onEdit: () => _showFormDialog(existing: h),
            onDelete: () => _deleteHotel(h),
          )),
        ])).toList(),
      ),
    );
  }
}
