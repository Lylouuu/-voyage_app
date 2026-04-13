import 'package:flutter/material.dart';
import 'package:voyage_app/features/admin/theme/admin_theme.dart';
import 'package:voyage_app/features/admin/services/admin_service.dart';
import 'package:voyage_app/features/admin/widgets/admin_widgets.dart';

/// Page d'affichage et suppression des avis
class AvisPage extends StatefulWidget {
  const AvisPage({super.key});

  @override
  State<AvisPage> createState() => _AvisPageState();
}

class _AvisPageState extends State<AvisPage> {
  List<Map<String, dynamic>> _avis = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAvis();
  }

  Future<void> _loadAvis() async {
    setState(() => _loading = true);
    try {
      final data = await AdminService.getAvis();
      if (mounted) setState(() { _avis = data; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); showAdminSnack(context, 'Erreur: $e', isError: true); }
    }
  }

  Future<void> _deleteAvis(Map<String, dynamic> avis) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const AdminConfirmDialog(
        title: 'Supprimer cet avis ?',
        message: 'Cette action est irréversible.',
      ),
    );
    if (confirm == true) {
      try {
        await AdminService.deleteAvis(avis['id'].toString());
        if (mounted) showAdminSnack(context, 'Avis supprimé');
        _loadAvis();
      } catch (e) {
        if (mounted) showAdminSnack(context, 'Erreur: $e', isError: true);
      }
    }
  }

  Widget _buildStars(dynamic note) {
    final rating = (note is int ? note : int.tryParse(note?.toString() ?? '0') ?? 0).clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => Icon(
        i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
        color: i < rating ? AdminTheme.warning : AdminTheme.textMuted,
        size: 16,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AdminDataTable(
        title: 'Gestion des avis',
        subtitle: '${_avis.length} avis au total',
        isLoading: _loading,
        columns: const ['Utilisateur', 'Ville', 'Note', 'Commentaire', 'Actions'],
        rows: _avis.map((a) => DataRow(cells: [
          DataCell(Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AdminTheme.accentSoft,
                borderRadius: AdminTheme.radiusSm,
              ),
              child: Center(
                child: Text(
                  (a['utilisateurs']?['nom'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    color: AdminTheme.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(a['utilisateurs']?['nom'] ?? 'Inconnu', style: const TextStyle(fontWeight: FontWeight.w500)),
          ])),
          DataCell(Text(a['villes']?['nom'] ?? '-')),
          DataCell(_buildStars(a['note'])),
          DataCell(
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                a['commentaire'] ?? '-',
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
          DataCell(AdminActionButtons(
            onDelete: () => _deleteAvis(a),
          )),
        ])).toList(),
      ),
    );
  }
}
