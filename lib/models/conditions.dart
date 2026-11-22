const Map<String, String> conditionDescriptions = {
  'ec': 'Encoberto com chuvas isoladas',
  'ci': 'Chuvas isoladas',
  'c': 'Chuva',
  'in': 'Instável',
  'pp': 'Possibilidade de pancadas de chuva',
  'cm': 'Chuva pela manhã',
  'cn': 'Chuva à noite',
  'pt': 'Pancadas de chuva à tarde',
  'pm': 'Pancadas de chuva pela manhã',
  'np': 'Nublado e pancadas de chuva',
  'pc': 'Pancadas de chuva',
  'pn': 'Parcialmente nublado',
  'cv': 'Chuvisco',
  'ch': 'Chuvoso',
  't': 'Tempestade',
  'ps': 'Predomínio de sol',
  'e': 'Encoberto',
  'n': 'Nublado',
  'cl': 'Céu claro',
  'nv': 'Nevoeiro',
  'g': 'Geada',
  'ne': 'Neve',
  'nd': 'Não definido',
  'pnt': 'Pancadas de chuva à noite',
  'psc': 'Possibilidade de chuva',
  'pcm': 'Possibilidade de chuva pela manhã',
  'pct': 'Possibilidade de chuva à tarde',
  'pcn': 'Possibilidade de chuva à noite',
  'npt': 'Nublado com pancadas à tarde',
  'npn': 'Nublado com pancadas à noite',
  'ncn': 'Nublado com possibilidade de chuva à noite',
  'nct': 'Nublado com possibilidade de chuva à tarde',
  'ncm': 'Nublado com possibilidade de chuva pela manhã',
  'npm': 'Nublado com pancadas pela manhã',
  'npp': 'Nublado com possibilidade de chuva',
  'vn': 'Variação de nebulosidade',
  'ct': 'Chuva à tarde',
  'ppn': 'Possibilidade de pancadas de chuva à noite',
  'ppt': 'Possibilidade de pancadas de chuva à tarde',
  'ppm': 'Possibilidade de pancadas de chuva pela manhã',
  'nppc': 'Nublado com possibilidade de chuva e trovoadas',
  'nppcm': 'Nublado com possibilidade de chuva e trovoadas pela manhã',
  'nppct': 'Nublado com possibilidade de chuva e trovoadas à tarde',
  'nppcn': 'Nublado com possibilidade de chuva e trovoadas à noite',
};

String conditionDescription(String? code) {
  final key = code?.trim().toLowerCase();
  if (key == null || key.isEmpty) return 'Condição não informada';
  return conditionDescriptions[key] ?? 'Condição não definida ($key)';
}

String? conditionIconUrl(String? code) {
  final key = code?.trim().toLowerCase();
  if (key == null || !conditionDescriptions.containsKey(key)) return null;
  return 'https://s1.cptec.inpe.br/webcptec/common/assets/images/icones/tempo/icones-grandes/$key.png';
}

String uvLevel(double uv) {
  if (uv < 3) return 'Baixo';
  if (uv < 6) return 'Moderado';
  if (uv < 8) return 'Alto';
  if (uv < 11) return 'Muito alto';
  return 'Extremo';
}
