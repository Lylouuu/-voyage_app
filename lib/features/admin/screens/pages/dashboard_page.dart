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
            const Text('Vue d\'ensemble Analytique', style: AdminTheme.headingLg),
            const SizedBox(height: 4),
            const Text('Statistiques détaillées et évolution de l\'application', style: AdminTheme.bodyMd),
            const SizedBox(height: 24),

            // ── TOP KPIS ──
            LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth.isInfinite ? MediaQuery.of(context).size.width - 48 : constraints.maxWidth;
              final spacing = 16.0;
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
                    ),
                  ),
                ],
              );
            }),

            const SizedBox(height: 24),

            // ── GRAPHIQUES ET ANALYSES ──
            LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth.isInfinite ? MediaQuery.of(context).size.width - 48 : constraints.maxWidth;
              final isDesktop = width > 900;
              
              Widget content = isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildEvolutionChart()),
                        const SizedBox(width: 24),
                        Expanded(flex: 1, child: _buildPieChart()),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildEvolutionChart(),
                        const SizedBox(height: 24),
                        _buildPieChart(),
                      ],
                    );
                    
              return content;
            }),

            const SizedBox(height: 24),

            // ── CLASSEMENTS ──
            LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth.isInfinite ? MediaQuery.of(context).size.width - 48 : constraints.maxWidth;
              final isDesktop = width > 900;
              
              Widget content = isDesktop
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
                    
              return content;
            }),

            const SizedBox(height: 24),
            
            // ── PAYS PLANIFIES ──
            _buildRecentSection(
              title: 'Pays les plus planifiés',
              icon: Icons.public_rounded,
              items: _topPays,
              builder: (p) => _RecentTile(
                title: p['nom'] ?? '',
                subtitle: p['continent'] ?? 'Continent inconnu',
                leading: Icons.flag_rounded,
                color: AdminTheme.success,
                trailing: '${p['count']} plans',
              ),
            ),
            
            const SizedBox(height: 24),

            // ── DERNIERS UTILISATEURS ──
            _buildRecentSection(
              title: 'Derniers utilisateurs',
              icon: Icons.people_rounded,
              items: _derniersUsers,
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
              items: _derniersPays,
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
              items: _dernieresVilles,
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

  Widget _buildEvolutionChart() {
    List<FlSpot> spots = [];
    if (_voyagesParJour.isNotEmpty) {
      for (int i = 0; i < _voyagesParJour.length; i++) {
        spots.add(FlSpot(i.toDouble(), (_voyagesParJour[i]['count'] as int).toDouble()));
      }
    } else {
      spots = [const FlSpot(0, 0)];
    }

    double maxY = spots.fold<double>(0, (m, s) => s.y > m ? s.y : m) + 1;
    if (maxY < 5) maxY = 5;

    return Container(
      decoration: AdminTheme.cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Évolution des voyages', style: AdminTheme.headingSm),
          const SizedBox(height: 4),
          const Text('Création de plans de voyages au fil du temps', style: AdminTheme.bodySm),
          const SizedBox(height: 32),
          SizedBox(
            height: 220,
            child: _voyagesParJour.isEmpty 
              ? const Center(child: Text('Peu de données temporelles', style: AdminTheme.bodyMd))
              : LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(color: AdminTheme.surfaceBorder, strokeWidth: 1),
                    ),
                    titlesData: const FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (spots.length - 1).toDouble() > 0 ? (spots.length - 1).toDouble() : 1,
                    minY: 0,
                    maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AdminTheme.accent,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AdminTheme.accent.withOpacity(0.1),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) => LineTooltipItem(
                            '${spot.y.toInt()} voyages',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                          )).toList();
                        }
                      )
                    )
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    return Container(
      decoration: AdminTheme.cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Répartition', style: AdminTheme.headingSm),
          const SizedBox(height: 4),
          const Text('Types de voyage', style: AdminTheme.bodySm),
          const SizedBox(height: 32),
          SizedBox(
            height: 220,
            child: _typeVoyageStats.isEmpty
              ? const Center(child: Text('Aucune donnée', style: AdminTheme.bodyMd))
              : PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: _typeVoyageStats.asMap().entries.map((e) {
                      final i = e.key;
                      final val = (e.value['count'] as int).toDouble();
                      return PieChartSectionData(
                        color: _getChartColor(i),
                        value: val,
                        title: '${e.value['type']}\n${val.toInt()}',
                        radius: 60,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopVilles() {
    return Container(
      decoration: AdminTheme.cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_city_rounded, color: AdminTheme.info, size: 20),
              SizedBox(width: 10),
              Text('Top Villes Planifiées', style: AdminTheme.headingSm),
            ],
          ),
          const SizedBox(height: 24),
          if (_topVilles.isEmpty)
            const Text('Aucune donnée', style: AdminTheme.bodyMd)
          else
            ..._topVilles.map((v) {
              final count = v['count'] as int;
              final maxCount = _topVilles.first['count'] as int;
              final pct = maxCount > 0 ? (count / maxCount) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(v['nom'] ?? 'Inconnu', style: const TextStyle(fontWeight: FontWeight.w600, color: AdminTheme.textPrimary)),
                        Text('$count plans', style: const TextStyle(fontWeight: FontWeight.w500, color: AdminTheme.info)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: AdminTheme.infoSoft,
                        color: AdminTheme.info,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTopActivites() {
    return Container(
      decoration: AdminTheme.cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_activity_rounded, color: AdminTheme.warning, size: 20),
              SizedBox(width: 10),
              Text('Activités Populaires', style: AdminTheme.headingSm),
            ],
          ),
          const SizedBox(height: 24),
          if (_topActivites.isEmpty)
            const Text('Aucune donnée', style: AdminTheme.bodyMd)
          else
            ..._topActivites.map((a) {
              final count = a['count'] as int;
              final maxCount = _topActivites.first['count'] as int;
              final pct = maxCount > 0 ? (count / maxCount) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(a['nom'] ?? 'Inconnu', maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AdminTheme.textPrimary)),
                        ),
                        Text('$count ajouts', style: const TextStyle(fontWeight: FontWeight.w500, color: AdminTheme.warning)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: AdminTheme.warningSoft,
                        color: AdminTheme.warning,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

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
