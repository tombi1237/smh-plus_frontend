enum CommandeStatut { nonTraitee, enCours, completee }

class Commande {
  final String numero;
  final String client;
  final String montant;
  final int produits;
  final String heure;
  final String livraison;
  final CommandeStatut statut;

  Commande({
    required this.numero,
    required this.client,
    required this.montant,
    required this.produits,
    required this.heure,
    required this.livraison,
    required this.statut,
  });
}
