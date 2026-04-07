import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';

class AvisForm extends StatefulWidget {
  final String villeId; // doit être un UUID de la table villes
  const AvisForm({super.key, required this.villeId});

  @override
  State<AvisForm> createState() => _AvisFormState();
}

class _AvisFormState extends State<AvisForm> {
  final _supabase = Supabase.instance.client;
  final _commentController = TextEditingController();
  double _note = 3;

  Future<void> _submitAvis() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Aucun utilisateur connecté')),
      );
      return;
    }

    try {
      // 👉 Vérification des valeurs envoyées
      print('id_user (auth): ${user.id}');
      print('id_ville: ${widget.villeId}');

      // Récupérer l'UUID depuis la table utilisateurs (car avis.id_user référence utilisateurs.id)
      final utilisateur = await _supabase
          .from('utilisateurs')
          .select('id')
          .eq('id', user.id) // doit correspondre à l'UUID auth
          .maybeSingle();

      if (utilisateur == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ Utilisateur introuvable dans la table utilisateurs',
            ),
          ),
        );
        return;
      }

      final utilisateurId = utilisateur['id'];

      // Insertion dans la table avis
      await _supabase.from('avis').insert({
        'id_user': utilisateurId,
        'id_ville': widget.villeId,
        'commentaire': _commentController.text.trim(),
        'note': _note.toInt(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Avis ajouté avec succès !')),
      );

      _commentController.clear();
      setState(() => _note = 3);
      Navigator.pop(context); // fermer le bottom sheet
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: AppTheme.coral),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '📝 Laisser un avis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Votre commentaire...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Note :'),
              Expanded(
                child: Slider(
                  value: _note,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '$_note',
                  activeColor: AppTheme.primary,
                  onChanged: (val) => setState(() => _note = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitAvis,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Envoyer mon avis'),
          ),
        ],
      ),
    );
  }
}
