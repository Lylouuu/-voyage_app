import 'package:supabase_flutter/supabase_flutter.dart';

class FavorisService {
  static final _supabase = Supabase.instance.client;

  /// Ajoute une ville aux favoris
  static Future<void> ajouterFavoris(String idVille, String nomVille) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('favoris').insert({
      'id_user': user.id,
      'id_ville': idVille,
      'nom_ville': nomVille,
    });
  }

  /// Retire une ville des favoris
  static Future<void> supprimerFavoris(String idVille) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('favoris')
        .delete()
        .eq('id_user', user.id)
        .eq('id_ville', idVille);
  }

  /// Vérifie si une ville est en favoris
  static Future<bool> estFavoris(String idVille) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final data = await _supabase
        .from('favoris')
        .select()
        .eq('id_user', user.id)
        .eq('id_ville', idVille)
        .maybeSingle();

    return data != null;
  }

  /// Récupère toutes les villes favorites de l'utilisateur
  static Future<List<Map<String, dynamic>>> getFavoris() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final data = await _supabase
        .from('favoris')
        .select('*, villes(*, pays(*))')
        .eq('id_user', user.id);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Récupère la liste des IDs des villes favorites (pour l'UI rapide)
  static Future<List<String>> getFavorisIds() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final data = await _supabase
        .from('favoris')
        .select('id_ville')
        .eq('id_user', user.id);

    return List<String>.from(data.map((f) => f['id_ville'].toString()));
  }
}
