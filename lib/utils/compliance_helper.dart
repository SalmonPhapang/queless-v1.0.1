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

  static const String privacyPolicy = '''
PRIVACY POLICY
Last Updated: 13 March 2026

1. INTRODUCTION
Queless ("we," "us," or "our") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and disclose your personal information.

2. INFORMATION WE COLLECT
• Personal Information: Name, email address, phone number, and delivery address.
• Age Verification: We collect identification documents to verify you are 18+.
• Location Data: We use your location to provide delivery services and enforce provincial trading hours.
• Payment Information: We process payments through secure third-party gateways (Ozow, PayFast).

3. HOW WE USE YOUR INFORMATION
• To process and deliver your orders.
• To verify your age for alcohol purchases.
• To communicate with you about your orders.
• To comply with South African liquor laws and regulations.

4. DATA SECURITY
We implement industry-standard security measures to protect your data. Your identification documents are stored securely and only accessible to authorized personnel.

5. DATA DELETION
You have the right to request the deletion of your account and personal data at any time through the app settings.

6. CONTACT US
If you have any questions, contact us at privacy@queless.co.za
''';

  static const String termsOfService = '''
TERMS OF SERVICE
Last Updated: 13 March 2026

1. ACCEPTANCE OF TERMS
By using Queless, you agree to these Terms of Service and all applicable South African laws.

2. AGE RESTRICTION
You must be at least 18 years of age to use this app and purchase alcohol. We strictly enforce age verification through identification document uploads.

3. TRADING HOURS
Alcohol sales are subject to provincial trading hours and restrictions. We do not process orders outside of legal trading hours for your province.

4. RESPONSIBLE DRINKING
We support responsible drinking. We reserve the right to refuse service to anyone appearing intoxicated or attempting to purchase alcohol for minors.

5. DELIVERY
Delivery is only available within supported areas in South Africa. You must be present to receive the order and provide proof of age if requested.

6. CANCELLATIONS AND REFUNDS
Orders can be cancelled before they are dispatched. Refunds are subject to our refund policy and provincial regulations.

7. LIMITATION OF LIABILITY
Queless is not liable for any misuse of alcohol or failure to comply with local laws by the user.
''';
}
