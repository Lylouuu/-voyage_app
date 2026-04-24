# 📋 Plan du Rapport — Méthode Agile XP appliquée à Retro Market

---

## 🧠 D'abord : C'est quoi XP (Extreme Programming) ?

**XP = Extreme Programming** est une méthode Agile créée par Kent Beck en 1999.
L'idée principale : **livrer du logiciel de qualité rapidement**, en travaillant en équipe courte,
par petites étapes appelées **itérations** (2 semaines en général).

### Les valeurs fondamentales de XP (à retenir)
| Valeur | Ce que ça veut dire |
|--------|---------------------|
| **Communication** | L'équipe se parle constamment (pas d'emails froids) |
| **Simplicité** | On code seulement ce dont on a besoin maintenant |
| **Feedback** | Le client voit le résultat rapidement et donne son avis |
| **Courage** | On refactorise, on dit la vérité, on change si nécessaire |
| **Respect** | Chaque membre de l'équipe a de la valeur |

### Les pratiques clés de XP (les 12 pratiques)
1. **Planning Game** → définir les User Stories avec le client
2. **Small Releases** → livrer souvent, par petites versions
3. **Metaphor** → avoir une vision commune du système
4. **Simple Design** → la conception la plus simple possible
5. **Testing** → tester avant/pendant le développement (TDD)
6. **Refactoring** → améliorer le code sans changer son comportement
7. **Pair Programming** → 2 devs sur 1 clavier
8. **Collective Ownership** → tout le code appartient à toute l'équipe
9. **Continuous Integration** → intégrer et tester souvent
10. **40-hour Week** → pas de surcharge, qualité > quantité
11. **On-site Customer** → le client est disponible pour répondre
12. **Coding Standards** → conventions de code partagées

---

## 📄 Structure du rapport (10–12 pages)

---

### PAGE DE GARDE
- Titre : *Application de la méthode Agile XP au projet Retro Market*
- Membres du groupe
- Module, filière, année
- Date

---

## PARTIE 1 — Présentation de l'approche Agile et XP (≤ 3 pages)

### 1.1 L'approche Agile (½ page)
> Le développement logiciel traditionnel (méthode en cascade/Waterfall) impose de tout planifier à l'avance. Si les besoins changent, tout est à refaire.
> L'Agile répond à ce problème : on livre par **petites itérations**, on s'adapte en continu.
>
> Le **Manifeste Agile (2001)** pose 4 valeurs :
> - Les individus et leurs interactions > les processus et les outils
> - Un logiciel fonctionnel > une documentation exhaustive
> - La collaboration avec le client > la négociation contractuelle
> - Répondre au changement > suivre un plan
>
> Il existe plusieurs méthodes Agile : **Scrum, Kanban, XP, DSDM...**

### 1.2 Présentation de XP — Extreme Programming (1,5 pages)
> XP (Extreme Programming) est une méthode Agile adaptée aux équipes de petite taille (2–10 personnes).
> Elle pousse les bonnes pratiques de développement à l'**extrême**.
>
> **Principe de fonctionnement :**
> Le travail est découpé en **User Stories** (récits utilisateurs) rédigées par le client.
> Ces stories sont priorisées, estimées, puis développées durant des **itérations** de 1 à 3 semaines.
> À chaque fin d'itération, une version fonctionnelle est livrée.
>
> **Rôles dans XP :**
> | Rôle | Responsabilité |
> |------|----------------|
> | Client | Rédige les User Stories, priorise, valide |
> | Développeur | Conçoit, code, teste, intègre |
> | Coach | Guide l'équipe sur la méthode XP |
> | Tracker | Suit l'avancement, mesure les vélocités |
> | Manager | Coordonne les ressources |
>
> **Les 12 pratiques clés** (voir tableau ci-dessus dans la section explication)
>
> **Cycle de vie d'un projet XP :**
> ```
> Exploration → Planification → Itérations → Production → Maintenance
> ```

### 1.3 Comparaison Agile vs Traditionnel (½ page)
| Critère | Méthode Traditionnelle | XP (Agile) |
|---------|----------------------|------------|
| Planification | Complète dès le début | Progressive |
| Livraison | Une seule à la fin | Fréquente (chaque itération) |
| Changement | Difficile et coûteux | Bienvenu |
| Documentation | Lourde | Légère |
| Tests | En fin de projet | Continus |
| Client | Impliqué au début | Impliqué tout au long |

---

## PARTIE 2 — Application de XP au projet Retro Market

### 2.1 Présentation du projet (½ page)
> **Retro Market** est une marketplace web de musique vintage permettant :
> - Aux **acheteurs** : parcourir un catalogue, ajouter au panier, passer commande
> - Aux **vendeurs** : gérer leur boutique, publier des produits, suivre leurs ventes
> - Aux **administrateurs** : modérer les produits, gérer les utilisateurs
>
> **Technologies utilisées :**
> - Frontend : HTML5, CSS3, JavaScript
> - Backend : Laravel (PHP) — API REST
> - Base de données : MySQL
>
> **Équipe :** [Vos noms] — [Nombre] développeurs + 1 client (simulé par le chef de projet)

---

### 2.2 Phase d'Exploration (½ page)
> Avant de commencer, l'équipe a **exploré** le besoin avec le client.
> On a identifié les grands thèmes fonctionnels du projet :
> - Authentification et gestion des comptes
> - Catalogue et recherche de produits
> - Panier et commande
> - Espace vendeur (gestion boutique)
> - Administration et modération
>
> **Métaphore système** : *"Retro Market fonctionne comme un vide-grenier musical en ligne,
> où chaque vendeur tient sa propre table d'exposition, validée par un commissaire."*

---

### 2.3 Planification (1 page)

#### User Stories identifiées

| ID | User Story | Priorité | Estimation |
|----|-----------|----------|------------|
| US01 | En tant qu'utilisateur, je veux créer un compte (acheteur ou vendeur) | Haute | 3 pts |
| US02 | En tant qu'utilisateur, je veux me connecter et être redirigé vers mon espace | Haute | 2 pts |
| US03 | En tant que visiteur, je veux voir le catalogue sans être connecté | Haute | 3 pts |
| US04 | En tant qu'acheteur, je veux filtrer les produits par catégorie | Haute | 2 pts |
| US05 | En tant qu'acheteur, je veux ajouter un produit au panier | Haute | 3 pts |
| US06 | En tant qu'acheteur, je veux passer une commande depuis mon panier | Haute | 4 pts |
| US07 | En tant que vendeur, je veux publier un nouveau produit avec photos | Haute | 5 pts |
| US08 | En tant que vendeur, je veux voir les statistiques de ma boutique | Moyenne | 3 pts |
| US09 | En tant que vendeur, je veux gérer les commandes que je reçois | Moyenne | 4 pts |
| US10 | En tant qu'admin, je veux valider ou refuser un produit soumis | Haute | 3 pts |
| US11 | En tant qu'acheteur, je veux ajouter un produit à mes favoris | Basse | 2 pts |
| US12 | En tant qu'acheteur, je veux suivre l'état de ma commande | Moyenne | 3 pts |
| US13 | En tant que vendeur, je veux modifier ou supprimer un produit | Moyenne | 2 pts |
| US14 | En tant qu'admin, je veux voir la liste de tous les utilisateurs | Basse | 2 pts |

#### Plan des itérations

| Itération | Durée | User Stories | Objectif |
|-----------|-------|-------------|----------|
| **Itération 1** | 2 semaines | US01, US02, US03, US04 | Authentification + Catalogue de base |
| **Itération 2** | 2 semaines | US05, US06, US07, US10 | Panier, Commande, Publication vendeur |
| *(Itération 3)* | 2 semaines | US08, US09, US11, US12, US13, US14 | Fonctionnalités avancées |

---

### 2.4 Itération 1 — Authentification & Catalogue (2 pages)

#### Objectif
Permettre à n'importe quel utilisateur de créer un compte, se connecter,
et consulter le catalogue de produits vintage.

#### User Stories de cette itération
- **US01** : Inscription (acheteur ou vendeur)
- **US02** : Connexion avec redirection par rôle
- **US03** : Consultation du catalogue sans connexion
- **US04** : Filtrage par catégorie

#### Conception technique

**Modèle de données impliqué :**
```
users (id, nom, prenom, email, password, role, created_at)
categorie (id_categorie, nom, type_categorie)
produits (id_produit, titre, prix, description, statut, id_categorie, id_vendeur)
```

**Endpoints API développés :**
```
POST /api/inscription   → Créer un compte
POST /api/login         → Authentification
GET  /api/produits      → Liste des produits
GET  /api/categories    → Liste des catégories
```

**Pages Frontend développées :**
```
index.html              → Page d'accueil avec hero, carrousel, catégories
auth-entry.html         → Portail d'entrée (choix du rôle)
authentification/sign-in.html  → Formulaire de connexion
authentification/sign-up.html  → Formulaire d'inscription
catalogue-visiteur.html        → Catalogue en lecture seule
catalogue.html                 → Catalogue complet (connecté)
```

#### Tests réalisés (XP Test-First)
| Test | Résultat |
|------|----------|
| Inscription avec email déjà utilisé → message d'erreur | ✅ |
| Connexion avec mauvais mot de passe → rejet | ✅ |
| Vendeur redirigé vers `seller/dashboard.html` | ✅ |
| Acheteur redirigé vers `acheteur/profile.html` | ✅ |
| Catalogue chargé depuis l'API `/api/produits` | ✅ |
| Filtre par catégorie "Vinyles" fonctionnel | ✅ |

#### Livrable de l'itération 1
✅ Pages d'authentification opérationnelles
✅ Catalogue public accessible aux visiteurs
✅ Filtrage par catégorie (CDs, Cassettes, Vinyles, Posters, Instruments)
✅ Système `GoldAuth` (gestion de session localStorage)

#### Revue d'itération (feedback client)
> Le client valide l'authentification et le catalogue. Il demande d'améliorer
> la barre de recherche pour qu'elle filtre en temps réel → pris en compte en itération 2.

---

### 2.5 Itération 2 — Panier, Commandes & Espace Vendeur (2 pages)

#### Objectif
Permettre aux acheteurs de commander et aux vendeurs de publier des produits,
avec validation par l'administrateur.

#### User Stories de cette itération
- **US05** : Ajouter un produit au panier
- **US06** : Passer une commande
- **US07** : Publier un produit avec photos (vendeur)
- **US10** : Modérer un produit (admin)

#### Conception technique

**Nouveaux modèles de données :**
```
panier (id_panier, id_acheteur, created_at)
panier_produit (id_panier, id_produit, quantite, prix_unitaire)
commandes (id_commande, id_acheteur, total, statut, created_at)
commande_produit (id_commande, id_produit, quantite, prix, statut)
produit_photo (id_photo, id_produit, chemin)
```

**Endpoints API développés :**
```
GET    /api/panier/{id}              → Voir son panier
POST   /api/panier                   → Ajouter au panier
PUT    /api/panier/ligne/{p}/{prod}  → Modifier quantité
DELETE /api/panier/clear/{id}        → Vider le panier
POST   /api/commandes                → Passer commande
POST   /api/produits                 → Créer un produit
POST   /api/admin/produits/{id}/moderer → Approuver/Refuser
```

**Pages Frontend développées :**
```
cart.html                        → Page panier
acheteur/checkout commande.html  → Confirmation de commande
acheteur/orders.html             → Historique des commandes
acheteur/order-details.html      → Détail d'une commande
seller/create-product.html       → Formulaire de création de produit
seller/products.html             → Liste des produits du vendeur
seller/dashboard.html            → Tableau de bord vendeur
admin/dashboard.html             → Dashboard admin + modération
```

#### Tests réalisés
| Test | Résultat |
|------|----------|
| Ajout au panier → badge mis à jour | ✅ |
| Quantité modifiée → total recalculé | ✅ |
| Commande passée → stock mis à jour | ✅ |
| Produit soumis → statut "en_attente" | ✅ |
| Admin approuve → produit visible dans catalogue | ✅ |
| Admin refuse → produit retiré avec raison | ✅ |
| Upload de photo produit (multipart) | ✅ |

#### Livrable de l'itération 2
✅ Panier fonctionnel avec persistence
✅ Tunnel de commande complet (panier → checkout → confirmation)
✅ Formulaire de création produit pour les vendeurs (avec upload photos)
✅ Dashboard admin avec liste des produits en attente de modération
✅ Workflow de modération (approuver / refuser avec motif)

#### Revue d'itération (feedback client)
> Le client est satisfait du flux d'achat. Il demande d'ajouter un suivi d'état
> des commandes pour l'acheteur et une vue financière pour les vendeurs → planifiés en itération 3.

---

### 2.6 Rétrospective et bilan (½ page)

#### Ce qui a bien fonctionné ✅
- Les User Stories courtes ont permis de livrer rapidement
- Le feedback client rapide a évité de partir dans la mauvaise direction
- La séparation frontend/backend claire a facilité le travail en parallèle

#### Ce qui a été amélioré entre les itérations 🔄
- Refactoring du système d'authentification (ajout de `GoldAuth.isSeller()`)
- Standardisation des appels API dans un fichier `api-config.js` partagé
- Ajout de la gestion des erreurs réseau dans tous les formulaires

#### Vélocité de l'équipe
| Itération | Points estimés | Points réalisés | Vélocité |
|-----------|---------------|----------------|----------|
| Itération 1 | 10 pts | 10 pts | 100% |
| Itération 2 | 15 pts | 15 pts | 100% |

---

### 2.7 Conclusion (¼ page)
> La méthode XP s'est révélée parfaitement adaptée au projet Retro Market.
> Grâce aux User Stories et aux itérations courtes, l'équipe a pu livrer
> rapidement des fonctionnalités testées et validées par le client.
> Les pratiques XP comme le refactoring continu et les tests systématiques
> ont garanti la qualité du code tout au long du développement.
> Le projet reste évolutif : de nouvelles User Stories peuvent être intégrées
> dans des itérations futures (notifications en temps réel, système d'avis, etc.)

---

## ✅ Checklist du rapport

- [ ] Page de garde complète
- [ ] Sommaire
- [ ] Partie 1 : Agile + XP (≤ 3 pages) → sections 1.1, 1.2, 1.3
- [ ] Partie 2 : Application
  - [ ] Présentation projet (2.1)
  - [ ] Phase d'exploration (2.2)
  - [ ] Planification avec tableau User Stories (2.3)
  - [ ] Itération 1 complète (2.4)
  - [ ] Itération 2 complète (2.5)
  - [ ] Rétrospective + bilan (2.6)
  - [ ] Conclusion (2.7)
- [ ] Police : Times New Roman 12 ou Calibri/Arial 11
- [ ] Entre 10 et 12 pages
- [ ] Bibliographie (optionnel mais bien vu)

---

## 📚 Sources à citer si besoin

- Beck, K. (1999). *Extreme Programming Explained: Embrace Change*. Addison-Wesley.
- Manifeste Agile : https://agilemanifesto.org/iso/fr/manifesto.html
- Wells, D. (2013). *Extreme Programming: A gentle introduction*. http://www.extremeprogramming.org
