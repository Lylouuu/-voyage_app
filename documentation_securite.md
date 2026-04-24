# Documentation Technique : Module de Sécurité & Gestion des Visiteurs
**Projet : Cevital Access**

Ce document récapitule l'implémentation du système de contrôle d'accès numérique pour les visiteurs.

## 1. Architecture du Système
Le système repose sur un flux de validation en trois étapes :
1. **Émission** : Le visiteur reçoit un badge QR Code dynamique (via `visiteur/badge.php`).
2. **Identification** : L'agent scanne le badge (`agent/scan.php`) ou effectue une recherche manuelle sur son tableau de bord (`agent/dashboard.php`).
3. **Validation** : L'agent vérifie les informations sur une fiche de sécurité dédiée (`agent/verify_badge.php`) avant d'autoriser l'entrée ou la sortie.

## 2. Structure de la Base de Données (Table `demandes`)
De nouveaux champs ont été ajoutés pour assurer la traçabilité :
- `token_valid` : Jeton de sécurité encodé dans le QR Code.
- `heure_entree` : Timestamp enregistré lors de la validation de l'arrivée.
- `heure_sortie` : Timestamp enregistré lors de la validation du départ.
- **Statut `en_cours`** : Indique que le visiteur est actuellement à l'intérieur des locaux.

## 3. Détails des Fichiers Implémentés

| Fichier | Fonctionnalité |
| :--- | :--- |
| `agent/dashboard.php` | Poste de contrôle principal avec statistiques dynamiques et filtres interactifs par catégorie (Attendus, Sur site, Terminés, Alertes). |
| `agent/scan.php` | Lecteur de QR Code intégré utilisant la bibliothèque `html5-qrcode`. Supporte la caméra et le téléchargement d'image. |
| `agent/verify_badge.php` | Fiche de contrôle d'identité. Vérifie la validité du badge, la date de visite et permet le pointage. |
| `agent/historique.php` | Registre journalier (Log) avec calcul automatique de la durée de présence sur site. |
| `visiteur/badge.php` | Interface mobile-first de génération de badge avec option de téléchargement en image PNG. |
| `includes/agent_sidebar.php` | Menu de navigation latéral spécifique à l'agent de sécurité. |

## 4. Fonctionnalités Avancées & Temps Réel
### A. Chrono et Alertes Dynamiques
Le tableau de bord de l'agent intègre un moteur JavaScript qui :
- Calcule les minutes écoulées depuis l'entrée sans recharger la page.
- Compare le temps écoulé avec la durée prévue.
- Déclenche visuellement une **Alerte Rouge** dès que le temps est dépassé.

### B. Synchronisation Temporelle
- **Timezone** : L'ensemble de la plateforme (PHP et MySQL) est configuré sur `Africa/Algiers`.
- **Horloge Header** : Une horloge numérique temps réel est affichée dans la barre de navigation supérieure pour l'agent.

## 5. Guide de Maintenance
- **Filtres** : La fonction `filtrerTableau(statut)` en JS permet de manipuler l'affichage des lignes sans appels AJAX supplémentaires.
- **Chemins QR Code** : L'URL encodée dans le badge est détectée dynamiquement pour fonctionner aussi bien en local qu'en production sur un sous-répertoire.

---
*Documentation générée le 20 Avril 2026.*
