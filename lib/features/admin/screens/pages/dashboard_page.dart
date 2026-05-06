import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:voyage_app/features/admin/theme/admin_theme.dart';
import 'package:voyage_app/features/admin/services/admin_service.dart';
import 'package:voyage_app/features/admin/widgets/admin_widgets.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, int> _stats = {};
  List<Map<String, dynamic>> _voyagesParJour = [];
  List<Map<String, dynamic>> _topVilles = [];
  List<Map<String, dynamic>> _topPays = [];
  List<Map<String, dynamic>> _topActivites = [];
  List<Map<String, dynamic>> _typeVoyageStats = [];
  List<Map<String, dynamic>> _derniersUsers = [];
  List<Map<String, dynamic>> _derniersPays = [];
  List<Map<String, dynamic>> _dernieresVilles = [];
  double _budgetMoyen = 0.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        AdminService.getDashboardStats(),
        AdminService.getVoyagesParJour(),
        AdminService.getTopVilles(),
        AdminService.getTypeVoyageStats(),
        AdminService.getBudgetMoyen(),
        AdminService.getTopActivites(),
        AdminService.getTopPaysPlanifies(),
        AdminService.getDerniersUtilisateurs(),
        AdminService.getDerniersPays(),
        AdminService.getDernieresVilles(),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, int>;
          _voyagesParJour = results[1] as List<Map<String, dynamic>>;
          _topVilles = results[2] as List<Map<String, dynamic>>;
          _typeVoyageStats = results[3] as List<Map<String, dynamic>>;
          _budgetMoyen = results[4] as double;
          _topActivites = results[5] as List<Map<String, dynamic>>;
          _topPays = results[6] as List<Map<String, dynamic>>;
          _derniersUsers = results[7] as List<Map<String, dynamic>>;
          _derniersPays = results[8] as List<Map<String, dynamic>>;
          _dernieresVilles = results[9] as List<Map<String, dynamic>>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _getChartColor(int index) {
    const colors = [
      AdminTheme.accent,
      AdminTheme.success,
      AdminTheme.warning,
      AdminTheme.info,
      AdminTheme.danger,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AdminTheme.accent),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AdminTheme.accent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── HEADER ──
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vue d\'ensemble Analytique', style: AdminTheme.headingLg),
                      SizedBox(height: 4),
                      Text('Statistiques détaillées et évolution de l\'application', style: AdminTheme.bodyMd),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadData,
                  tooltip: 'Actualiser',
                  style: IconButton.styleFrom(
                    backgroundColor: AdminTheme.accentSoft,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, color: AdminTheme.accent, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── TOP KPIS (Enhanced) ──
            _buildKpiSection(),
            const SizedBox(height: 20),

            // ── PLATFORM STATS BADGES ──
            _buildPlatformStatsBadges(),
            const SizedBox(height: 24),

            // ── TIMELINE + DONUT ──
            _buildTimelineAndDonutSection(),
            const SizedBox(height: 24),

            // ── CLASSEMENTS ──
            _buildRankingsSection(),
            const SizedBox(height: 24),



            // ── DERNIERS UTILISATEURS ──
            _buildRecentSection(
              title: 'Derniers utilisateurs',
              icon: Icons.people_rounded,
              items: _derniersUsers.take(3).toList(),
              builder: (u) => _RecentTile(
                title: u['nom'] ?? 'Inconnu',
                subtitle: u['email'] ?? '',
                leading: Icons.person_rounded,
                color: AdminTheme.accent,
                trailing: u['role'] ?? 'voyageur',
              ),
            ),
            const SizedBox(height: 24),

            // ── DERNIERS PAYS ──
            _buildRecentSection(
              title: 'Derniers pays ajoutés',
              icon: Icons.public_rounded,
              items: _derniersPays.take(3).toList(),
              builder: (p) => _RecentTile(
                title: p['nom'] ?? '',
                subtitle: p['continent'] ?? '',
                leading: Icons.flag_rounded,
                color: AdminTheme.success,
              ),
            ),
            const SizedBox(height: 24),

            // ── DERNIERES VILLES ──
            _buildRecentSection(
              title: 'Dernières villes ajoutées',
              icon: Icons.location_city_rounded,
              items: _dernieresVilles.take(3).toList(),
              builder: (v) => _RecentTile(
                title: v['nom'] ?? '',
                subtitle: v['pays']?['nom'] ?? '',
                leading: Icons.location_on_rounded,
                color: AdminTheme.info,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  KPI SECTION — 4 enhanced cards with sparklines & animations
  // ═══════════════════════════════════════════════════════════════

  Widget _buildKpiSection() {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth.isInfinite
          ? MediaQuery.of(context).size.width - 48
          : constraints.maxWidth;
      const spacing = 16.0;
      final itemWidth = width > 900 ? (width - (spacing * 3)) / 4 : (width - spacing) / 2;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          SizedBox(
            width: itemWidth,
            child: AdminStatCard(
              title: 'Budget Moyen',
              value: '${_budgetMoyen.toStringAsFixed(0)} €',
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFF6C63FF),
              bgColor: AdminTheme.accentSoft,
              variation: '+8%',
              isPositive: true,
              animationDelay: 0,
            ),
          ),
          SizedBox(
            width: itemWidth,
            child: AdminStatCard(
              title: 'Plans Créés',
              value: '${_stats['plans_voyage'] ?? 0}',
              icon: Icons.flight_rounded,
              color: AdminTheme.success,
              bgColor: AdminTheme.successSoft,
              variation: '+15%',
              isPositive: true,
              animationDelay: 100,
            ),
          ),
          SizedBox(
            width: itemWidth,
            child: AdminStatCard(
              title: 'Utilisateurs',
              value: '${_stats['utilisateurs'] ?? 0}',
              icon: Icons.people_rounded,
              color: AdminTheme.info,
              bgColor: AdminTheme.infoSoft,
              variation: '+12%',
              isPositive: true,
              animationDelay: 200,
            ),
          ),
          SizedBox(
            width: itemWidth,
            child: AdminStatCard(
              title: 'Activités',
              value: '${_stats['activites'] ?? 0}',
              icon: Icons.local_activity_rounded,
              color: AdminTheme.warning,
              bgColor: AdminTheme.warningSoft,
              variation: '+5%',
              isPositive: true,
              animationDelay: 300,
            ),
          ),
        ],
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════
  //  PLATFORM STATS — Horizontal scrollable badges
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPlatformStatsBadges() {
    return Container(
      decoration: AdminTheme.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AdminTheme.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.grid_view_rounded, color: AdminTheme.accent, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Contenu de la plateforme', style: AdminTheme.headingSm),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                PlatformStatBadge(
                  icon: Icons.public_rounded,
                  label: 'Pays',
                  value: '${_stats['pays'] ?? 0}',
                  color: AdminTheme.success,
                ),
                const SizedBox(width: 10),
                PlatformStatBadge(
                  icon: Icons.location_city_rounded,
                  label: 'Villes',
                  value: '${_stats['villes'] ?? 0}',
                  color: AdminTheme.info,
                ),
                const SizedBox(width: 10),
                PlatformStatBadge(
                  icon: Icons.account_balance_rounded,
                  label: 'Monuments',
                  value: '${_stats['monuments'] ?? 0}',
                  color: const Color(0xFF6C63FF),
                ),
                const SizedBox(width: 10),
                PlatformStatBadge(
                  icon: Icons.restaurant_rounded,
                  label: 'Restaurants',
                  value: '${_stats['restaurants'] ?? 0}',
                  color: AdminTheme.warning,
                ),
                const SizedBox(width: 10),
                PlatformStatBadge(
                  icon: Icons.hotel_rounded,
                  label: 'Hôtels',
                  value: '${_stats['hotels'] ?? 0}',
                  color: AdminTheme.accent,
                ),
                const SizedBox(width: 10),
                PlatformStatBadge(
                  icon: Icons.star_rounded,
                  label: 'Avis',
                  value: '${_stats['avis'] ?? 0}',
                  color: AdminTheme.danger,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TIMELINE + DONUT SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTimelineAndDonutSection() {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth.isInfinite
          ? MediaQuery.of(context).size.width - 48
          : constraints.maxWidth;
      final isDesktop = width > 900;

      return isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildActivityTimeline()),
                const SizedBox(width: 24),
                Expanded(flex: 1, child: _buildDonutChart()),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildActivityTimeline(),
                const SizedBox(height: 24),
                _buildDonutChart(),
              ],
            );
    });
  }

  // ═══════════════════════════════════════════════════════════════
  //  RANKINGS SECTION — Top Villes + Top Activités with medals
  // ═══════════════════════════════════════════════════════════════

  Widget _buildRankingsSection() {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth.isInfinite
          ? MediaQuery.of(context).size.width - 48
          : constraints.maxWidth;
      final isDesktop = width > 900;

      return isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildTopVilles()),
                const SizedBox(width: 24),
                Expanded(child: _buildTopActivites()),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopVilles(),
                const SizedBox(height: 24),
                _buildTopActivites(),
              ],
            );
    });
  }

  // ── ACTIVITY TIMELINE (replaces line chart) ────────────────

  Widget _buildActivityTimeline() {
    // Take last 7 entries for a readable bar chart
    final recentDays = _voyagesParJour.length > 7
        ? _voyagesParJour.sublist(_voyagesParJour.length - 7)
        : _voyagesParJour;

    double maxY = 1;
    for (var d in recentDays) {
      final c = (d['count'] as int).toDouble();
      if (c > maxY) maxY = c;
    }
    maxY = maxY + 1;

    // Format short date labels
    final List<String> dateLabels = recentDays.map<String>((d) {
      final date = d['date'] ?? '';
      try {
        final parsed = DateTime.parse(date);
        const mois = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
        return '${parsed.day}/${parsed.month < 10 ? '0' : ''}${parsed.month}';
      } catch (_) {
        return date;
      }
    }).toList();

    return Container(
      decoration: AdminTheme.cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AdminTheme.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: AdminTheme.accent, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Plans de voyage par jour', style: AdminTheme.headingSm),
                    SizedBox(height: 2),
                    Text('Nombre de plans créés par date', style: AdminTheme.bodySm),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            child: recentDays.isEmpty
              ? const Center(child: Text('Aucune donnée disponible', style: AdminTheme.bodyMd))
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    minY: 0,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: AdminTheme.surfaceBorder,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            if (value == value.roundToDouble() && value >= 0) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Text(
                                  '${value.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AdminTheme.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx >= 0 && idx < dateLabels.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  dateLabels[idx],
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AdminTheme.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                    ),
                    barGroups: recentDays.asMap().entries.map((entry) {
                      final i = entry.key;
                      final count = (entry.value['count'] as int).toDouble();
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: count,
                            width: recentDays.length <= 4 ? 28 : 18,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                            gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Color(0xFFA5D13B), AdminTheme.accent],
                            ),
                          ),
                        ],
                        showingTooltipIndicators: [0],
                      );
                    }).toList(),
                    barTouchData: BarTouchData(
                      enabled: false,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipMargin: 4,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toInt()}',
                            const TextStyle(
                              color: AdminTheme.accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  // ── DONUT CHART (replaces Pie Chart) ──────────────────────

  Widget _buildDonutChart() {
    final total = _typeVoyageStats.fold<int>(0, (sum, e) => sum + (e['count'] as int));

    return Container(
      decoration: AdminTheme.cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AdminTheme.infoSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.donut_large_rounded, color: AdminTheme.info, size: 18),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Répartition', style: AdminTheme.headingSm),
                  SizedBox(height: 2),
                  Text('Types de voyage', style: AdminTheme.bodySm),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 180,
            child: _typeVoyageStats.isEmpty
              ? const Center(child: Text('Aucune donnée', style: AdminTheme.bodyMd))
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 45,
                        sections: _typeVoyageStats.asMap().entries.map((e) {
                          final i = e.key;
                          final val = (e.value['count'] as int).toDouble();
                          return PieChartSectionData(
                            color: _getChartColor(i),
                            value: val,
                            title: '',
                            radius: 35,
                          );
                        }).toList(),
                      ),
                    ),
                    // Total in center
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AdminTheme.textPrimary,
                          ),
                        ),
                        const Text(
                          'total',
                          style: TextStyle(
                            fontSize: 11,
                            color: AdminTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          ),
          // Legend
          if (_typeVoyageStats.isNotEmpty) ...[
            const SizedBox(height: 20),
            ..._typeVoyageStats.asMap().entries.map((e) {
              final i = e.key;
              final type = e.value['type'] ?? 'Inconnu';
              final count = e.value['count'] as int;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _getChartColor(i),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        type,
                        style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _getChartColor(i),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ── TOP VILLES (with medals) ──────────────────────────────

  Widget _buildTopVilles() {
    return Container(
      decoration: AdminTheme.cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AdminTheme.infoSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_city_rounded, color: AdminTheme.info, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Top Villes Planifiées', style: AdminTheme.headingSm),
            ],
          ),
          const SizedBox(height: 20),
          if (_topVilles.isEmpty)
            const Text('Aucune donnée', style: AdminTheme.bodyMd)
          else
            ..._topVilles.asMap().entries.map((entry) {
              final i = entry.key;
              final v = entry.value;
              final count = v['count'] as int;
              final maxCount = _topVilles.first['count'] as int;
              final pct = maxCount > 0 ? (count / maxCount) : 0.0;
              return RankedListItem(
                rank: i + 1,
                name: v['nom'] ?? 'Inconnu',
                countLabel: '$count plans',
                progress: pct,
                color: AdminTheme.info,
                bgColor: AdminTheme.infoSoft,
              );
            }),
        ],
      ),
    );
  }

  // ── TOP ACTIVITÉS (with medals) ───────────────────────────

  Widget _buildTopActivites() {
    return Container(
      decoration: AdminTheme.cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AdminTheme.warningSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_activity_rounded, color: AdminTheme.warning, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Activités Populaires', style: AdminTheme.headingSm),
            ],
          ),
          const SizedBox(height: 20),
          if (_topActivites.isEmpty)
            const Text('Aucune donnée', style: AdminTheme.bodyMd)
          else
            ..._topActivites.asMap().entries.map((entry) {
              final i = entry.key;
              final a = entry.value;
              final count = a['count'] as int;
              final maxCount = _topActivites.first['count'] as int;
              final pct = maxCount > 0 ? (count / maxCount) : 0.0;
              return RankedListItem(
                rank: i + 1,
                name: a['nom'] ?? 'Inconnu',
                countLabel: '$count ajouts',
                progress: pct,
                color: AdminTheme.warning,
                bgColor: AdminTheme.warningSoft,
              );
            }),
        ],
      ),
    );
  }

  // ── RECENT SECTION (unchanged) ────────────────────────────

  Widget _buildRecentSection({
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required Widget Function(Map<String, dynamic>) builder,
  }) {
    return Container(
      decoration: AdminTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(icon, color: AdminTheme.accent, size: 20),
                const SizedBox(width: 10),
                Text(title, style: AdminTheme.headingSm),
              ],
            ),
          ),
          Container(height: 1, color: AdminTheme.surfaceBorder),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Aucune donnée disponible', style: AdminTheme.bodyMd),
            )
          else
            ...items.map((item) => builder(item)),
        ],
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData leading;
  final Color color;
  final String? trailing;

  const _RecentTile({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AdminTheme.surfaceBorder.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: AdminTheme.radiusSm,
            ),
            child: Icon(leading, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AdminTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(subtitle, style: AdminTheme.bodySm),
              ],
            ),
          ),
          if (trailing != null)
            Container(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
               decoration: BoxDecoration(
                 color: color.withOpacity(0.1),
                 borderRadius: AdminTheme.radiusSm,
               ),
               child: Text(
                 trailing!,
                 style: TextStyle(
                   fontSize: 12,
                   fontWeight: FontWeight.w600,
                   color: color,
                 ),
               ),
             ),
        ],
      ),
    );
  }
}
