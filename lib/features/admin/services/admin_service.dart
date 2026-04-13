import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service centralisé pour toutes les opérations CRUD admin avec Supabase
class AdminService {
  static final _supabase = Supabase.instance.client;

  // ════════════════════════════════════════════════════════════
  //  AUTH & RÔLE
  // ════════════════════════════════════════════════════════════

  /// Connexion admin : authentifie + vérifie le rôle "admin"
  static Future<Map<String, dynamic>?> signInAdmin(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) return null;

    // Vérifier le rôle dans la table utilisateurs
    final userData = await _supabase
        .from('utilisateurs')
        .select()
        .eq('id', response.user!.id)
        .maybeSingle();

    if (userData == null || userData['role'] != 'admin') {
      await _supabase.auth.signOut();
      return null;
    }

    return userData;
  }

  /// Déconnexion
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Vérifie si l'utilisateur courant est admin
  static Future<bool> isCurrentUserAdmin() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final data = await _supabase
        .from('utilisateurs')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    return data != null && data['role'] == 'admin';
  }

  /// Récupère le profil admin courant
  static Future<Map<String, dynamic>?> getCurrentAdmin() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    return await _supabase
        .from('utilisateurs')
        .select()
        .eq('id', user.id)
        .maybeSingle();
  }

  // ════════════════════════════════════════════════════════════
  //  STATISTIQUES DASHBOARD
  // ════════════════════════════════════════════════════════════

  static Future<Map<String, int>> getDashboardStats() async {
    try {
      final users = await _supabase.from('utilisateurs').select('id');
      final pays = await _supabase.from('pays').select('id');
      final villes = await _supabase.from('villes').select('id');
      final activites = await _supabase.from('activites').select('id');
      final monuments = await _supabase.from('monuments').select('id');
      final restaurants = await _supabase.from('restaurants').select('id');
      final hotels = await _supabase.from('hotels').select('id');
      final avis = await _supabase.from('avis').select('id');
      final plans = await _supabase.from('plans_voyage').select('id');

      return {
        'utilisateurs': users.length,
        'pays': pays.length,
        'villes': villes.length,
        'activites': activites.length,
        'monuments': monuments.length,
        'restaurants': restaurants.length,
        'hotels': hotels.length,
        'avis': avis.length,
        'plans_voyage': plans.length,
      };
    } catch (e) {
      debugPrint('Erreur stats: $e');
      return {};
    }
  }

  // ════════════════════════════════════════════════════════════
  //  PAYS – CRUD
  // ════════════════════════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> getPays({String? search}) async {
    var query = _supabase.from('pays').select();
    if (search != null && search.isNotEmpty) {
      query = query.ilike('nom', '%$search%');
    }
    final data = await query.order('nom');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> addPays(Map<String, dynamic> paysData) async {
    await _supabase.from('pays').insert(paysData);
  }

  static Future<void> updatePays(String id, Map<String, dynamic> paysData) async {
    await _supabase.from('pays').update(paysData).eq('id', id);
  }

  static Future<void> deletePays(String id) async {
    await _supabase.from('pays').delete().eq('id', id);
  }

  // ════════════════════════════════════════════════════════════
  //  VILLES – CRUD
  // ════════════════════════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> getVilles({String? search}) async {
    var query = _supabase.from('villes').select('*, pays(nom)');
    if (search != null && search.isNotEmpty) {
      query = query.ilike('nom', '%$search%');
    }
    final data = await query.order('nom');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> addVille(Map<String, dynamic> villeData) async {
    await _supabase.from('villes').insert(villeData);
  }

  static Future<void> updateVille(String id, Map<String, dynamic> villeData) async {
    await _supabase.from('villes').update(villeData).eq('id', id);
  }

  static Future<void> deleteVille(String id) async {
    await _supabase.from('villes').delete().eq('id', id);
  }

  // ════════════════════════════════════════════════════════════
  //  ACTIVITÉS – CRUD
  // ════════════════════════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> getActivites({String? search}) async {
    var query = _supabase.from('activites').select('*, villes(nom)');
    if (search != null && search.isNotEmpty) {
      query = query.ilike('nom', '%$search%');
    }
    final data = await query.order('nom');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> addActivite(Map<String, dynamic> data) async {
    await _supabase.from('activites').insert(data);
  }

  static Future<void> updateActivite(String id, Map<String, dynamic> data) async {
    await _supabase.from('activites').update(data).eq('id', id);
  }

  static Future<void> deleteActivite(String id) async {
    await _supabase.from('activites').delete().eq('id', id);
  }

  // ════════════════════════════════════════════════════════════
  //  MONUMENTS – CRUD
  // ════════════════════════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> getMonuments({String? search}) async {
    var query = _supabase.from('monuments').select('*, villes(nom)');
    if (search != null && search.isNotEmpty) {
      query = query.ilike('nom', '%$search%');
    }
    final data = await query.order('nom');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> addMonument(Map<String, dynamic> data) async {
    await _supabase.from('monuments').insert(data);
  }

  static Future<void> updateMonument(String id, Map<String, dynamic> data) async {
    await _supabase.from('monuments').update(data).eq('id', id);
  }

  static Future<void> deleteMonument(String id) async {
    await _supabase.from('monuments').delete().eq('id', id);
  }

  // ════════════════════════════════════════════════════════════
  //  RESTAURANTS – CRUD
  // ════════════════════════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> getRestaurants({String? search}) async {
    var query = _supabase.from('restaurants').select('*, villes(nom)');
    if (search != null && search.isNotEmpty) {
      query = query.ilike('nom', '%$search%');
    }
    final data = await query.order('nom');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> addRestaurant(Map<String, dynamic> data) async {
    await _supabase.from('restaurants').insert(data);
  }

  static Future<void> updateRestaurant(String id, Map<String, dynamic> data) async {
    await _supabase.from('restaurants').update(data).eq('id', id);
  }

  static Future<void> deleteRestaurant(String id) async {
    await _supabase.from('restaurants').delete().eq('id', id);
  }

  // ════════════════════════════════════════════════════════════
  //  HÔTELS – CRUD
  // ════════════════════════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> getHotels({String? search}) async {
    var query = _supabase.from('hotels').select('*, villes(nom)');
    if (search != null && search.isNotEmpty) {
      query = query.ilike('nom', '%$search%');
    }
    final data = await query.order('nom');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> addHotel(Map<String, dynamic> data) async {
    await _supabase.from('hotels').insert(data);
  }

  static Future<void> updateHotel(String id, Map<String, dynamic> data) async {
    await _supabase.from('hotels').update(data).eq('id', id);
  }

  static Future<void> deleteHotel(String id) async {
    await _supabase.from('hotels').delete().eq('id', id);
  }

  // ════════════════════════════════════════════════════════════
  //  UTILISATEURS – CRUD
  // ════════════════════════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> getUtilisateurs({String? search}) async {
    var query = _supabase.from('utilisateurs').select();
    if (search != null && search.isNotEmpty) {
      query = query.ilike('nom', '%$search%');
    }
    final data = await query.order('nom');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> updateUtilisateur(String id, Map<String, dynamic> data) async {
    await _supabase.from('utilisateurs').update(data).eq('id', id);
  }

  static Future<void> deleteUtilisateur(String id) async {
    await _supabase.from('utilisateurs').delete().eq('id', id);
  }

  // ════════════════════════════════════════════════════════════
  //  AVIS – CRUD
  // ════════════════════════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> getAvis({String? search}) async {
    // FK: avis.id_user → utilisateurs.id, avis.id_ville → villes.id
    var query = _supabase.from('avis').select('*, utilisateurs!avis_id_user_fkey(nom), villes(nom)');
    final data = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> deleteAvis(String id) async {
    await _supabase.from('avis').delete().eq('id', id);
  }

  // ════════════════════════════════════════════════════════════
  //  PLANS DE VOYAGE – CRUD
  // ════════════════════════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> getPlansVoyage({String? search}) async {
    // FK: plans_voyage.id_user → utilisateurs.id
    var query = _supabase.from('plans_voyage').select('*, utilisateurs!plans_voyage_id_user_fkey(nom)');
    final data = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> deletePlanVoyage(String id) async {
    await _supabase.from('plans_voyage').delete().eq('id', id);
  }

  // ════════════════════════════════════════════════════════════
  //  DERNIERS AJOUTS (DASHBOARD)
  // ════════════════════════════════════════════════════════════

  // ════════════════════════════════════════════════════════════
  //  STATISTIQUES AVANCEES (DASHBOARD)
  // ════════════════════════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> getVoyagesParJour() async {
    try {
      final data = await _supabase
          .from('plans_voyage')
          .select('created_at')
          .order('created_at');

      final Map<String, int> counts = {};
      for (var row in data) {
        if (row['created_at'] == null) continue;
        final date = DateTime.parse(row['created_at']).toIso8601String().split('T')[0];
        counts[date] = (counts[date] ?? 0) + 1;
      }

      return counts.entries.map((e) => {'date': e.key, 'count': e.value}).toList();
    } catch (e) {
      debugPrint('Erreur getVoyagesParJour: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getTopVilles() async {
    try {
      final data = await _supabase
          .from('plan_villes')
          .select('villes(nom)');

      final Map<String, int> counts = {};
      for (var row in data) {
        final nomVille = row['villes']?['nom'];
        if (nomVille == null) continue;
        counts[nomVille] = (counts[nomVille] ?? 0) + 1;
      }

      final result = counts.entries.map((e) => {'nom': e.key, 'count': e.value}).toList();
      result.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      return result.take(5).toList();
    } catch (e) {
      debugPrint('Erreur getTopVilles: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getTypeVoyageStats() async {
    try {
      final data = await _supabase
          .from('plans_voyage')
          .select('type_voyage');

      final Map<String, int> counts = {};
      for (var row in data) {
        final type = row['type_voyage'] ?? 'Inconnu';
        counts[type] = (counts[type] ?? 0) + 1;
      }

      return counts.entries.map((e) => {'type': e.key, 'count': e.value}).toList();
    } catch (e) {
      debugPrint('Erreur getTypeVoyageStats: $e');
      return [];
    }
  }

  static Future<double> getBudgetMoyen() async {
    try {
      final data = await _supabase
          .from('plans_voyage')
          .select('budget_total');

      if (data.isEmpty) return 0.0;

      double total = 0;
      int count = 0;
      for (var row in data) {
        final budget = row['budget_total'];
        if (budget != null && budget is num && budget > 0) {
          total += budget;
          count++;
        }
      }

      return count > 0 ? (total / count) : 0.0;
    } catch (e) {
      debugPrint('Erreur getBudgetMoyen: $e');
      return 0.0;
    }
  }

  static Future<List<Map<String, dynamic>>> getTopActivites() async {
    try {
      final data = await _supabase
          .from('itineraire_jours')
          .select('activites(nom, categorie)');

      final Map<String, int> counts = {};
      final Map<String, String> cats = {};

      for (var row in data) {
        final nomActivite = row['activites']?['nom'];
        if (nomActivite == null) continue;

        counts[nomActivite] = (counts[nomActivite] ?? 0) + 1;
        if (!cats.containsKey(nomActivite)) {
          cats[nomActivite] = row['activites']?['categorie'] ?? 'Divers';
        }
      }

      final result = counts.entries.map((e) => {
        'nom': e.key,
        'count': e.value,
        'categorie': cats[e.key]
      }).toList();

      result.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      return result.take(5).toList();
    } catch (e) {
      debugPrint('Erreur getTopActivites: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getDerniersUtilisateurs() async {
    final data = await _supabase
        .from('utilisateurs')
        .select()
        .order('created_at', ascending: false)
        .limit(5);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getDerniersPays() async {
    // pays n'a pas de created_at → on récupère simplement les 5 premiers par nom
    final data = await _supabase
        .from('pays')
        .select()
        .order('nom')
        .limit(5);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getTopPaysPlanifies() async {
    try {
      final data = await _supabase
          .from('plan_villes')
          .select('villes(pays(nom, continent))');

      final Map<String, int> counts = {};
      final Map<String, String> continents = {};

      for (var row in data) {
        final ville = row['villes'];
        if (ville == null) continue;
        final pays = ville['pays'];
        if (pays == null) continue;

        final nomPays = pays['nom'];
        if (nomPays == null) continue;

        counts[nomPays] = (counts[nomPays] ?? 0) + 1;
        if (!continents.containsKey(nomPays) && pays['continent'] != null) {
          continents[nomPays] = pays['continent'];
        }
      }

      final List<Map<String, dynamic>> result = counts.entries.map((e) {
        return {
          'nom': e.key,
          'count': e.value,
          'continent': continents[e.key] ?? '',
        };
      }).toList();

      result.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      return result.take(5).toList();
    } catch (e) {
      debugPrint('Erreur top pays planifiés: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getDernieresVilles() async {
    // villes n'a pas de created_at → on récupère simplement les 5 premiers par nom
    final data = await _supabase
        .from('villes')
        .select('*, pays(nom)')
        .order('nom')
        .limit(5);
    return List<Map<String, dynamic>>.from(data);
  }
}
