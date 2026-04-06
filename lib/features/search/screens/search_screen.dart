import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';
import 'package:voyage_app/features/detail/screens/detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>> _allVilles = [];
  bool _loading = false;
  String _selectedBudget = '';
  String _selectedContinent = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final villes = await _supabase
        .from('villes')
        .select('*, pays(nom, continent, langue, monnaie, climat)')
        .order('popularite', ascending: false);
    if (mounted) {
      setState(() {
        _allVilles = List<Map<String, dynamic>>.from(villes);
        _results = _allVilles;
        _loading = false;
      });
    }
  }

  void _filter() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _results = _allVilles.where((v) {
        final matchQ =
            q.isEmpty ||
            (v['nom'] ?? '').toLowerCase().contains(q) ||
            (v['pays']?['nom'] ?? '').toLowerCase().contains(q);
        final matchB =
            _selectedBudget.isEmpty || v['niveau_budget'] == _selectedBudget;
        final matchC =
            _selectedContinent.isEmpty ||
            v['pays']?['continent'] == _selectedContinent;
        return matchQ && matchB && matchC;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔍 Explorer',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Trouvez votre prochaine aventure',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  // Barre de recherche
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _filter(),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.dark,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ville, pays...',
                        hintStyle: TextStyle(
                          color: AppTheme.muted,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.coral,
                          size: 22,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: AppTheme.muted,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _filter();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filtres
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                children: [
                  // Budget
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text('💰 ', style: TextStyle(fontSize: 14)),
                        ...['', 'Faible', 'Moyen', 'Élevé'].map((b) {
                          final selected = _selectedBudget == b;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedBudget = b);
                              _filter();
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: selected ? AppTheme.coral : Colors.white,
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: selected
                                      ? AppTheme.coral
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Text(
                                b.isEmpty ? 'Tous' : b,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : AppTheme.dark,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Continent
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text('🌍 ', style: TextStyle(fontSize: 14)),
                        ...['', 'Afrique', 'Asie', 'Europe', 'Amérique'].map((
                          c,
                        ) {
                          final selected = _selectedContinent == c;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedContinent = c);
                              _filter();
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppTheme.primary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: selected
                                      ? AppTheme.primary
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Text(
                                c.isEmpty ? 'Tous' : c,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : AppTheme.dark,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Résultats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${_results.length} destination${_results.length > 1 ? 's' : ''} trouvée${_results.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Liste
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🔍', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            'Aucune destination trouvée',
                            style: TextStyle(
                              color: AppTheme.muted,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _results.length,
                      itemBuilder: (_, i) => _buildResultCard(_results[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> ville) {
    final budget = ville['niveau_budget'] ?? '';
    final budgetColor = budget == 'Faible'
        ? const Color(0xFF4CAF50)
        : budget == 'Élevé'
        ? const Color(0xFFFF6B6B)
        : const Color(0xFFFFD97D);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailScreen(ville: ville)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              child: CachedNetworkImage(
                imageUrl: ville['image_url'] ?? '',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppTheme.primary.withOpacity(0.15),
                  width: 100,
                  height: 100,
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppTheme.primary.withOpacity(0.15),
                  width: 100,
                  height: 100,
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
            // Infos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ville['nom'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.dark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppTheme.muted,
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${ville['pays']?['nom'] ?? ''} · ${ville['pays']?['continent'] ?? ''}',
                          style: TextStyle(fontSize: 12, color: AppTheme.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: budgetColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            budget,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: budgetColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFFD97D),
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${ville['popularite'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.dark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: AppTheme.muted, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
