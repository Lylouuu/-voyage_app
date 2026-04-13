import 'package:flutter/material.dart';
import 'package:voyage_app/features/admin/theme/admin_theme.dart';
import 'package:voyage_app/features/admin/services/admin_service.dart';
import 'package:voyage_app/features/admin/widgets/admin_widgets.dart';

/// Page de gestion des utilisateurs (modifier rôle, supprimer)
class UtilisateursPage extends StatefulWidget {
  const UtilisateursPage({super.key});

  @override
  State<UtilisateursPage> createState() => _UtilisateursPageState();
}

class _UtilisateursPageState extends State<UtilisateursPage> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({String? search}) async {
    setState(() => _loading = true);
    try {
      final data = await AdminService.getUtilisateurs(search: search);
      if (mounted) setState(() { _users = data; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); showAdminSnack(context, 'Erreur: $e', isError: true); }
    }
  }

  void _showEditRoleDialog(Map<String, dynamic> user) {
    String selectedRole = user['role'] ?? 'voyageur';
    bool saving = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AdminFormModal(
          title: 'Modifier le rôle',
          isLoading: saving,
          submitLabel: 'Mettre à jour',
          fields: [
            // Info utilisateur
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AdminTheme.surfaceLight,
                borderRadius: AdminTheme.radiusMd,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AdminTheme.primaryGradient,
                      borderRadius: AdminTheme.radiusMd,
                    ),
                    child: Center(
                      child: Text(
                        (user['nom'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['nom'] ?? 'Inconnu',
                          style: const TextStyle(
                            color: AdminTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          user['email'] ?? '',
                          style: AdminTheme.bodySm,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            DropdownButtonFormField<String>(
              value: selectedRole,
              dropdownColor: AdminTheme.surfaceLight,
              style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 14),
              decoration: AdminTheme.inputDecoration(label: 'Rôle', icon: Icons.shield_rounded),
              items: ['voyageur', 'admin', 'bloque'].map((r) {
                IconData icon;
                Color color;
                switch (r) {
                  case 'admin':
                    icon = Icons.admin_panel_settings_rounded;
                    color = AdminTheme.accent;
                    break;
                  case 'bloque':
                    icon = Icons.block_rounded;
                    color = AdminTheme.danger;
                    break;
                  default:
                    icon = Icons.person_rounded;
                    color = AdminTheme.success;
                }
                return DropdownMenuItem(
                  value: r,
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 10),
                      Text(r[0].toUpperCase() + r.substring(1)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => setStateDialog(() => selectedRole = v ?? 'voyageur'),
            ),
          ],
          onSubmit: () async {
            setStateDialog(() => saving = true);
            try {
              await AdminService.updateUtilisateur(
                user['id'].toString(),
                {'role': selectedRole},
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) showAdminSnack(context, 'Rôle modifié avec succès');
              _loadUsers();
            } catch (e) {
              setStateDialog(() => saving = false);
              if (mounted) showAdminSnack(context, 'Erreur: $e', isError: true);
            }
          },
        ),
      ),
    );
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AdminConfirmDialog(
        title: 'Supprimer cet utilisateur ?',
        message: '"${user['nom']}" sera supprimé. Toutes ses données associées seront perdues.',
      ),
    );
    if (confirm == true) {
      try {
        await AdminService.deleteUtilisateur(user['id'].toString());
        if (mounted) showAdminSnack(context, 'Utilisateur supprimé');
        _loadUsers();
      } catch (e) {
        if (mounted) showAdminSnack(context, 'Erreur: $e', isError: true);
      }
    }
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    Color bgColor;
    IconData icon;

    switch (role) {
      case 'admin':
        color = AdminTheme.accent;
        bgColor = AdminTheme.accentSoft;
        icon = Icons.admin_panel_settings_rounded;
        break;
      case 'bloque':
        color = AdminTheme.danger;
        bgColor = AdminTheme.dangerSoft;
        icon = Icons.block_rounded;
        break;
      default:
        color = AdminTheme.success;
        bgColor = AdminTheme.successSoft;
        icon = Icons.person_rounded;
    }

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
            role[0].toUpperCase() + role.substring(1),
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AdminDataTable(
        title: 'Gestion des utilisateurs',
        subtitle: '${_users.length} utilisateurs enregistrés',
        searchController: _searchController,
        onSearch: (v) => _loadUsers(search: v),
        isLoading: _loading,
        columns: const ['Utilisateur', 'Email', 'Rôle', 'Budget', 'Type voyage', 'Actions'],
        rows: _users.map((u) => DataRow(cells: [
          DataCell(Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: u['role'] == 'admin' ? AdminTheme.primaryGradient : null,
                color: u['role'] == 'admin' ? null : AdminTheme.surfaceLight,
                borderRadius: AdminTheme.radiusSm,
              ),
              child: Center(
                child: Text(
                  (u['nom'] ?? 'U')[0].toUpperCase(),
                  style: TextStyle(
                    color: u['role'] == 'admin' ? Colors.white : AdminTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(u['nom'] ?? 'Inconnu', style: const TextStyle(fontWeight: FontWeight.w500)),
          ])),
          DataCell(Text(u['email'] ?? '-')),
          DataCell(_buildRoleBadge(u['role'] ?? 'voyageur')),
          DataCell(Text(u['budget']?.toString() ?? '-')),
          DataCell(Text(u['type_voyage'] ?? '-')),
          DataCell(AdminActionButtons(
            onEdit: () => _showEditRoleDialog(u),
            onDelete: () => _deleteUser(u),
          )),
        ])).toList(),
      ),
    );
  }
}
