enum ArtisanTrade {
  plumber('plumber', 'Plombier'),
  electrician('electrician', 'Électricien'),
  airConditioningTechnician('air_conditioning_technician', 'Climaticien'),
  applianceRepairer('appliance_repairer', 'Réparateur d’électroménager'),
  locksmith('locksmith', 'Serrurier'),
  painter('painter', 'Peintre'),
  carpenter('carpenter', 'Menuisier');

  const ArtisanTrade(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static ArtisanTrade fromStorageValue(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'plomberie' || 'plombier' => ArtisanTrade.plumber,
      'électricité' ||
      'electricite' ||
      'électricien' ||
      'electricien' => ArtisanTrade.electrician,
      _ => ArtisanTrade.values.firstWhere(
        (trade) => trade.storageValue == normalized,
        orElse: () =>
            throw FormatException('Métier artisan non pris en charge.'),
      ),
    };
  }
}

enum InterventionArea {
  tunis('tunis', 'Tunis'),
  ariana('ariana', 'Ariana'),
  benArous('ben_arous', 'Ben Arous'),
  manouba('manouba', 'Manouba');

  const InterventionArea(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static InterventionArea fromStorageValue(String value) {
    final normalized = value.trim().toLowerCase();
    return InterventionArea.values.firstWhere(
      (area) =>
          area.storageValue == normalized ||
          area.label.toLowerCase() == normalized,
      orElse: () =>
          throw FormatException('Zone d’intervention non prise en charge.'),
    );
  }
}
