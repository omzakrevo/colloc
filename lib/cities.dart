/// Villes universitaires du Burkina Faso proposées dans l'app.
class City {
  const City(
    this.name, {
    this.universities = const [],
    this.neighborhoods = const [],
  });
  final String name;
  final List<String> universities;
  final List<String> neighborhoods;
}

const kCities = <City>[
  City(
    'Ouagadougou',
    universities: ['Université Joseph Ki-Zerbo', 'Université Thomas Sankara'],
    neighborhoods: [
      'Ouaga 2000',
      'Zogona',
      'Gounghin',
      "Patte d'Oie",
      'Tanghin',
      'Cissin',
      'Karpala',
      'Dassasgho',
      'Pissy',
      'Kossodo',
      'Tampouy',
      'Wemtenga',
      'Koulouba',
      'Paspanga',
    ],
  ),
  City(
    'Bobo-Dioulasso',
    universities: ['Université Nazi Boni'],
    neighborhoods: [
      'Accart-Ville',
      'Sarfalao',
      'Colma',
      'Dioulassoba',
      'Bindougousso',
      'Lafiabougou',
      'Secteur 22',
      'Bolmakoté',
    ],
  ),
  City(
    'Banfora',
    neighborhoods: ['Centre-ville', 'Secteur 1', 'Secteur 3', 'Secteur 5'],
  ),
  City(
    'Koudougou',
    universities: ['Université Norbert Zongo'],
    neighborhoods: ['Centre-ville', 'Secteur 1', 'Secteur 4', 'Secteur 7'],
  ),
  City(
    'Ouahigouya',
    universities: ['Université de Ouahigouya'],
    neighborhoods: ['Centre-ville', 'Secteur 2', 'Secteur 5'],
  ),
  City(
    'Fada N\'Gourma',
    universities: ['Université Yembila Abdoulaye Toguyeni'],
    neighborhoods: ['Centre-ville', 'Secteur 1', 'Secteur 3'],
  ),
  City(
    'Dédougou',
    universities: ['Université de Dédougou'],
    neighborhoods: ['Centre-ville', 'Secteur 2', 'Secteur 4'],
  ),
  City('Kaya', neighborhoods: ['Centre-ville', 'Secteur 1', 'Secteur 3']),
  City('Tenkodogo', neighborhoods: ['Centre-ville', 'Secteur 2']),
  City('Dori', neighborhoods: ['Centre-ville']),
];

City? cityByName(String? n) {
  for (final c in kCities) {
    if (c.name == n) return c;
  }
  return null;
}
