import 'package:flutter/material.dart';

enum TransactionStatut { traite, enAttente, annule }

class Transaction {
  final String number;
  final String category;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String montant;
  final String client;
  final String livreur;
  final String heure;
  final TransactionStatut statut;

  Transaction({
    required this.number,
    required this.category,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.montant,
    required this.client,
    required this.livreur,
    required this.heure,
    required this.statut,
  });
}
