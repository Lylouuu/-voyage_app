import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as dev;

class FavorisService {
  static final _supabase = Supabase.instance.client;

  /// Ajoute une ville aux favoris
  static Future<void> ajouterFavoris(String idVille, String nomVille) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('favoris').insert({
        'id_user': user.id,
        'id_ville': idVille, // Supabase cast généralement le String en Int si nécessaire
        'nom_ville': nomVille,
      });
    } catch (e) {
      dev.log('Erreur ajouterFavoris: $e');
    }
  }

  /// Retire une ville des favoris
  static Future<void> supprimerFavoris(String idVille) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('favoris')
          .delete()
          .eq('id_user', user.id)
          .eq('id_ville', idVille);
    } catch (e) {
      dev.log('Erreur supprimerFavoris: $e');
    }
  }

  /// Vérifie si une ville est en favoris
  static Future<bool> estFavoris(String idVille) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final data = await _supabase
          .from('favoris')
          .select()
          .eq('id_user', user.id)
          .eq('id_ville', idVille)
          .maybeSingle();

      return data != null;
    } catch (e) {
      dev.log('Erreur estFavoris: $e');
      return false;
    }
  }

  /// Récupère toutes les villes favorites de l'utilisateur
  static Future<List<Map<String, dynamic>>> getFavoris() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      // On tente la jointure standard. Si la FK est bien nommée 'villes' dans Supabase, ça marche.
      final data = await _supabase
          .from('favoris')
          .select('*, villes(*, pays(*))')
          .eq('id_user', user.id);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      dev.log('Erreur getFavoris: $e');
      return [];
    }
  }

  /// Récupère la liste des IDs des villes favorites (pour l'UI rapide)
  static Future<List<String>> getFavorisIds() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final data = await _supabase
          .from('favoris')
          .select('id_ville')
          .eq('id_user', user.id);

      return List<String>.from(data.map((f) => f['id_ville'].toString()));
    } catch (e) {
      dev.log('Erreur getFavorisIds: $e');
      return [];
    }
  }
}
