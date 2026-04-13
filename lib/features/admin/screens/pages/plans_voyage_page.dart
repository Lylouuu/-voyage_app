import 'package:flutter/material.dart';
import 'package:voyage_app/features/admin/theme/admin_theme.dart';
import 'package:voyage_app/features/admin/services/admin_service.dart';
import 'package:voyage_app/features/admin/widgets/admin_widgets.dart';

/// Page d'affichage et suppression des plans de voyage
class PlansVoyagePage extends StatefulWidget {
  const PlansVoyagePage({super.key});

  @override
  State<PlansVoyagePage> createState() => _PlansVoyagePageState();
}

class _PlansVoyagePageState extends State<PlansVoyagePage> {
  List<Map<String, dynamic>> _plans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _loading = true);
    try {
      final data = await AdminService.getPlansVoyage();
      if (mounted) setState(() { _plans = data; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); showAdminSnack(context, 'Erreur: $e', isError: true); }
    }
  }

  Future<void> _deletePlan(Map<String, dynamic> plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AdminConfirmDialog(
        title: 'Supprimer ce plan ?',
        message: '"${plan['titre'] ?? 'Ce plan'}" sera supprimé de manière irréversible.',
      ),
    );
    if (confirm == true) {
      try {
        await AdminService.deletePlanVoyage(plan['id'].toString());
        if (mounted) showAdminSnack(context, 'Plan supprimé');
        _loadPlans();
      } catch (e) {
        if (mounted) showAdminSnack(context, 'Erreur: $e', isError: true);
      }
    }
  }

  Widget _buildStatutBadge(String? statut) {
    Color color;
    Color bgColor;
    IconData icon;

    switch (statut) {
      case 'en_cours':
        color = AdminTheme.info;
        bgColor = AdminTheme.infoSoft;
        icon = Icons.play_circle_rounded;
        break;
      case 'termine':
        color = AdminTheme.success;
        bgColor = AdminTheme.successSoft;
        icon = Icons.check_circle_rounded;
        break;
      case 'annule':
        color = AdminTheme.danger;
        bgColor = AdminTheme.dangerSoft;
        icon = Icons.cancel_rounded;
        break;
      default:
        color = AdminTheme.warning;
        bgColor = AdminTheme.warningSoft;
        icon = Icons.pending_rounded;
    }

    final label = statut?.replaceAll('_', ' ') ?? 'brouillon';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AdminTheme.radiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label[0].toUpperCase() + label.substring(1),
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '-';
    try {
      final d = DateTime.parse(date);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AdminDataTable(
        title: 'Plans de voyage',
        subtitle: '${_plans.length} plans enregistrés',
        isLoading: _loading,
        columns: const ['Titre', 'Utilisateur', 'Date début', 'Date fin', 'Budget', 'Statut', 'Actions'],
        rows: _plans.map((p) => DataRow(cells: [
          DataCell(Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0x1AFF7043),
                borderRadius: AdminTheme.radiusSm,
              ),
              child: const Icon(Icons.flight_rounded, color: Color(0xFFFF7043), size: 16),
            ),
            const SizedBox(width: 10),
            Text(p['titre'] ?? 'Sans titre', style: const TextStyle(fontWeight: FontWeight.w500)),
          ])),
          DataCell(Text(p['utilisateurs']?['nom'] ?? '-')),
          DataCell(Text(_formatDate(p['date_debut']?.toString()))),
          DataCell(Text(_formatDate(p['date_fin']?.toString()))),
          DataCell(Text(p['budget_total'] != null ? '${p['budget_total']}€' : '-')),
          DataCell(_buildStatutBadge(p['statut']?.toString())),
          DataCell(AdminActionButtons(
            onDelete: () => _deletePlan(p),
          )),
        ])).toList(),
      ),
    );
  }
}
