import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:voyage_app/features/admin/theme/admin_theme.dart';

// ════════════════════════════════════════════════════════════════
//  STAT CARD — Dashboard KPI cards (Enhanced with sparkline)
// ════════════════════════════════════════════════════════════════

class AdminStatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String? variation; // e.g. "+12%"
  final bool isPositive;
  final int animationDelay; // ms delay for staggered animation

  const AdminStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.variation,
    this.isPositive = true,
    this.animationDelay = 0,
  });

  @override
  State<AdminStatCard> createState() => _AdminStatCardState();
}

class _AdminStatCardState extends State<AdminStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AdminTheme.surface,
                widget.color.withOpacity(0.05),
              ],
            ),
            borderRadius: AdminTheme.radiusLg,
            border: Border.all(color: AdminTheme.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.bgColor,
                      borderRadius: AdminTheme.radiusMd,
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 22),
                  ),
                  // Mini sparkline
                  SizedBox(
                    width: 50,
                    height: 24,
                    child: CustomPaint(
                      painter: _SparklinePainter(
                        color: widget.isPositive
                            ? AdminTheme.success
                            : AdminTheme.danger,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: widget.color,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(widget.title, style: AdminTheme.bodyMd),
                  ),
                  if (widget.variation != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (widget.isPositive
                                ? AdminTheme.success
                                : AdminTheme.danger)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isPositive
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color: widget.isPositive
                                ? AdminTheme.success
                                : AdminTheme.danger,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            widget.variation!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: widget.isPositive
                                  ? AdminTheme.success
                                  : AdminTheme.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiny sparkline painter for KPI cards
class _SparklinePainter extends CustomPainter {
  final Color color;
  _SparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final points = List.generate(8, (i) {
      final x = (i / 7) * size.width;
      final y = size.height * (0.2 + rng.nextDouble() * 0.6);
      return Offset(x, y);
    });
    // Sort to make a rising trend feel
    points.sort((a, b) => (b.dy).compareTo(a.dy));
    final sortedPoints = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      sortedPoints.add(Offset(
        (i / (points.length - 1)) * size.width,
        points[i].dy,
      ));
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(sortedPoints.first.dx, sortedPoints.first.dy);
    for (int i = 1; i < sortedPoints.length; i++) {
      final prev = sortedPoints[i - 1];
      final curr = sortedPoints[i];
      final cpX = (prev.dx + curr.dx) / 2;
      path.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(path, paint);

    // Gradient fill below
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ════════════════════════════════════════════════════════════════
//  PLATFORM STAT BADGE — Compact horizontal stat chips
// ════════════════════════════════════════════════════════════════

class PlatformStatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const PlatformStatBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: AdminTheme.radiusMd,
        border: Border.all(color: AdminTheme.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AdminTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  RANKED LIST ITEM — Top items with medal ranks
// ════════════════════════════════════════════════════════════════

class RankedListItem extends StatelessWidget {
  final int rank;
  final String name;
  final String countLabel;
  final double progress;
  final Color color;
  final Color bgColor;

  const RankedListItem({
    super.key,
    required this.rank,
    required this.name,
    required this.countLabel,
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: rank <= 3
                  ? LinearGradient(
                      colors: _getMedalColors(),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: rank > 3 ? AdminTheme.surfaceLight : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: rank <= 3 ? Colors.white : AdminTheme.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AdminTheme.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      countLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: bgColor,
                    color: color,
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getMedalColors() {
    switch (rank) {
      case 1:
        return [const Color(0xFFFFD700), const Color(0xFFFFA000)]; // Gold
      case 2:
        return [const Color(0xFFC0C0C0), const Color(0xFF9E9E9E)]; // Silver
      case 3:
        return [const Color(0xFFCD7F32), const Color(0xFFA0522D)]; // Bronze
      default:
        return [AdminTheme.surfaceLight, AdminTheme.surfaceLight];
    }
  }
}

// ════════════════════════════════════════════════════════════════
//  DATA TABLE WRAPPER — Stylized table with search
// ════════════════════════════════════════════════════════════════

class AdminDataTable extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String> columns;
  final List<DataRow> rows;
  final VoidCallback? onAdd;
  final String? addLabel;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearch;
  final bool isLoading;

  const AdminDataTable({
    super.key,
    required this.title,
    this.subtitle,
    required this.columns,
    required this.rows,
    this.onAdd,
    this.addLabel,
    this.searchController,
    this.onSearch,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header Card ───────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AdminTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: AdminTheme.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AdminTheme.headingMd),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(subtitle!, style: AdminTheme.bodySm),
                        ],
                      ],
                    ),
                  ),
                  if (onAdd != null)
                    IconButton.filled(
                      onPressed: onAdd,
                      style: IconButton.styleFrom(backgroundColor: AdminTheme.accent),
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                    ),
                ],
              ),
              if (searchController != null) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: searchController,
                  onChanged: onSearch,
                  decoration: AdminTheme.inputDecoration(
                    label: 'Rechercher...',
                    icon: Icons.search_rounded,
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Content Section ───────────────────────────────────
        if (isLoading)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AdminTheme.surface,
              border: Border.all(color: AdminTheme.surfaceBorder),
            ),
            child: const Center(child: CircularProgressIndicator(color: AdminTheme.accent)),
          )
        else if (rows.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
            decoration: BoxDecoration(
              color: AdminTheme.surface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              border: Border.all(color: AdminTheme.surfaceBorder),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_rounded, size: 64, color: AdminTheme.textMuted.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text('Aucune donnée trouvée', style: AdminTheme.bodyMd),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AdminTheme.surface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              border: Border.all(color: AdminTheme.surfaceBorder),
            ),
            child: Column(
              children: rows.map((row) => _buildMobileDataCard(context, row)).toList(),
            ),
          ),
      ],
    );
  }

  // Helper pour transformer une DataRow (interdit) en une Card (stable)
  Widget _buildMobileDataCard(BuildContext context, DataRow row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.background,
        borderRadius: AdminTheme.radiusMd,
        border: Border.all(color: AdminTheme.surfaceBorder.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // On affiche les 2 premières colonnes comme titre/sous-titre
          if (row.cells.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: row.cells[0].child),
                if (row.cells.length > 1) 
                  const SizedBox(width: 8),
              ],
            ),
          
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // On affiche le reste comme des labels
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: List.generate(row.cells.length - 1, (index) {
              final cellIndex = index + 1;
              if (cellIndex == row.cells.length - 1) return const SizedBox(); // On saute les actions
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(columns[cellIndex].toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminTheme.textMuted)),
                  const SizedBox(height: 4),
                  row.cells[cellIndex].child,
                ],
              );
            }),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Actions à la fin
          Align(
            alignment: Alignment.centerRight,
            child: row.cells.last.child,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  FORM MODAL — Réutilisable pour Add/Edit
// ════════════════════════════════════════════════════════════════

class AdminFormModal extends StatelessWidget {
  final String title;
  final List<Widget> fields;
  final VoidCallback onSubmit;
  final bool isLoading;
  final String submitLabel;

  const AdminFormModal({
    super.key,
    required this.title,
    required this.fields,
    required this.onSubmit,
    this.isLoading = false,
    this.submitLabel = 'Enregistrer',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: AdminTheme.radiusXl),
      child: Container(
        width: 480,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: AdminTheme.primaryGradient,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // Fields
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    ...fields.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: f,
                    )),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AdminTheme.surfaceBorder),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: AdminTheme.outlineButton,
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : onSubmit,
                      style: AdminTheme.primaryButton,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(submitLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  CONFIRMATION DIALOG
// ════════════════════════════════════════════════════════════════

class AdminConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;

  const AdminConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Supprimer',
    this.confirmColor = AdminTheme.danger,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: AdminTheme.radiusLg),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AdminTheme.dangerSoft,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AdminTheme.danger, size: 32),
            ),
            const SizedBox(height: 20),
            Text(title, style: AdminTheme.headingMd, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: AdminTheme.bodyMd, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: AdminTheme.outlineButton,
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: AdminTheme.radiusMd),
                      elevation: 0,
                    ),
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  SNACKBAR HELPER
// ════════════════════════════════════════════════════════════════

void showAdminSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
        ],
      ),
      backgroundColor: isError ? AdminTheme.danger : AdminTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AdminTheme.radiusMd),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ),
  );
}

// ════════════════════════════════════════════════════════════════
//  ACTION BUTTONS (edit/delete inline)
// ════════════════════════════════════════════════════════════════

class AdminActionButtons extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AdminActionButtons({super.key, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          _ActionBtn(
            icon: Icons.edit_outlined,
            color: AdminTheme.accent,
            bgColor: AdminTheme.accentSoft,
            onTap: onEdit!,
          ),
        if (onEdit != null && onDelete != null) const SizedBox(width: 8),
        if (onDelete != null)
          _ActionBtn(
            icon: Icons.delete_outline,
            color: AdminTheme.danger,
            bgColor: AdminTheme.dangerSoft,
            onTap: onDelete!,
          ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AdminTheme.radiusSm,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AdminTheme.radiusSm,
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
