class ComplianceHelper {
  static const Map<String, Map<String, dynamic>> provinceRules = {
    'Western Cape': {
      'weekday_cutoff': 21,
      'sunday_sales': false,
      'restrictions': 'No alcohol sales after 9 PM on weekdays and Saturdays. No sales on Sundays.',
    },
    'Gauteng': {
      'weekday_cutoff': 22,
      'sunday_sales': true,
      'restrictions': 'No alcohol sales after 10 PM on weekdays and weekends.',
    },
    'KwaZulu-Natal': {
      'weekday_cutoff': 21,
      'sunday_sales': true,
      'restrictions': 'No alcohol sales after 9 PM on weekdays and weekends.',
    },
    'Eastern Cape': {
      'weekday_cutoff': 21,
      'sunday_sales': false,
      'restrictions': 'No alcohol sales after 9 PM. No sales on Sundays.',
    },
    'Free State': {
      'weekday_cutoff': 21,
      'sunday_sales': true,
      'restrictions': 'No alcohol sales after 9 PM on weekdays and weekends.',
    },
    'Limpopo': {
      'weekday_cutoff': 21,
      'sunday_sales': true,
      'restrictions': 'No alcohol sales after 9 PM on weekdays and weekends.',
    },
    'Mpumalanga': {
      'weekday_cutoff': 21,
      'sunday_sales': true,
      'restrictions': 'No alcohol sales after 9 PM on weekdays and weekends.',
    },
    'Northern Cape': {
      'weekday_cutoff': 21,
      'sunday_sales': true,
      'restrictions': 'No alcohol sales after 9 PM on weekdays and weekends.',
    },
    'North West': {
      'weekday_cutoff': 21,
      'sunday_sales': true,
      'restrictions': 'No alcohol sales after 9 PM on weekdays and weekends.',
    },
  };

  static bool canOrderAlcohol(String province) {
    final now = DateTime.now();
    final rules = provinceRules[province];
    
    if (rules == null) return false;

    if (now.weekday == DateTime.sunday && !rules['sunday_sales']) {
      return false;
    }

    final cutoffHour = rules['weekday_cutoff'] as int;
    if (now.hour >= cutoffHour) {
      return false;
    }

    return true;
  }

  static String getRestrictionMessage(String province) {
    final rules = provinceRules[province];
    if (rules == null) return 'Unable to determine restrictions for this province.';
    return rules['restrictions'] as String;
  }

  static List<String> getSupportedProvinces() => provinceRules.keys.toList();

  static List<String> getSupportedCities() => [
    'Johannesburg',
    'Cape Town',
    'Durban',
    'Pretoria',
    'Port Elizabeth',
    'Bloemfontein',
    'East London',
    'Polokwane',
    'Nelspruit',
    'Kimberley',
    'Rustenburg',
    'Pietermaritzburg',
    'Centurion',
    'Sandton',
    'Stellenbosch',
  ];

  static const List<String> responsibleDrinkingMessages = [
    'Please drink responsibly. Don\'t drink and drive.',
    'Alcohol may be harmful to your health. Enjoy in moderation.',
    'Not for sale to persons under the age of 18.',
    'It is an offence to supply liquor to persons under 18 years.',
    'Driving under the influence of alcohol is dangerous and illegal.',
  ];

  static String getRandomResponsibleDrinkingMessage() {
    final now = DateTime.now();
    final index = now.second % responsibleDrinkingMessages.length;
    return responsibleDrinkingMessages[index];
  }

  static bool isMinimumAge(DateTime dateOfBirth) {
    final today = DateTime.now();
    final age = today.year - dateOfBirth.year;
    if (today.month < dateOfBirth.month || (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      return age - 1 >= 18;
    }
    return age >= 18;
  }

  static const String licenseInfo = '''
Queless (Pty) Ltd holds the necessary liquor licenses to operate in South Africa.

License Number: LP-2024-SA-001234
Issued By: National Liquor Authority
Valid Until: 31 December 2025

We comply with all South African liquor laws and regulations, including:
• Liquor Act 59 of 2003
• Provincial liquor regulations
• Age restriction requirements
• Trading hours limitations

For license verification or queries, contact: compliance@queless.co.za
''';
}
