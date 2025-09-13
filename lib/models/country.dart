class Country {
  final String code;
  final String name;
  final String phonePrefix;
  final String flag;

  const Country({
    required this.code,
    required this.name,
    required this.phonePrefix,
    required this.flag,
  });

  static const List<Country> countries = [
    Country(code: 'US', name: 'United States', phonePrefix: '+1', flag: '🇺🇸'),
    Country(code: 'CA', name: 'Canada', phonePrefix: '+1', flag: '🇨🇦'),
    Country(
        code: 'GB', name: 'United Kingdom', phonePrefix: '+44', flag: '🇬🇧'),
    Country(code: 'AU', name: 'Australia', phonePrefix: '+61', flag: '🇦🇺'),
    Country(code: 'DE', name: 'Germany', phonePrefix: '+49', flag: '🇩🇪'),
    Country(code: 'FR', name: 'France', phonePrefix: '+33', flag: '🇫🇷'),
    Country(code: 'IT', name: 'Italy', phonePrefix: '+39', flag: '🇮🇹'),
    Country(code: 'ES', name: 'Spain', phonePrefix: '+34', flag: '🇪🇸'),
    Country(code: 'NL', name: 'Netherlands', phonePrefix: '+31', flag: '🇳🇱'),
    Country(code: 'SE', name: 'Sweden', phonePrefix: '+46', flag: '🇸🇪'),
    Country(code: 'NO', name: 'Norway', phonePrefix: '+47', flag: '🇳🇴'),
    Country(code: 'DK', name: 'Denmark', phonePrefix: '+45', flag: '🇩🇰'),
    Country(code: 'FI', name: 'Finland', phonePrefix: '+358', flag: '🇫🇮'),
    Country(code: 'CH', name: 'Switzerland', phonePrefix: '+41', flag: '🇨🇭'),
    Country(code: 'AT', name: 'Austria', phonePrefix: '+43', flag: '🇦🇹'),
    Country(code: 'BE', name: 'Belgium', phonePrefix: '+32', flag: '🇧🇪'),
    Country(code: 'IE', name: 'Ireland', phonePrefix: '+353', flag: '🇮🇪'),
    Country(code: 'PT', name: 'Portugal', phonePrefix: '+351', flag: '🇵🇹'),
    Country(code: 'GR', name: 'Greece', phonePrefix: '+30', flag: '🇬🇷'),
    Country(code: 'PL', name: 'Poland', phonePrefix: '+48', flag: '🇵🇱'),
    Country(
        code: 'CZ', name: 'Czech Republic', phonePrefix: '+420', flag: '🇨🇿'),
    Country(code: 'HU', name: 'Hungary', phonePrefix: '+36', flag: '🇭🇺'),
    Country(code: 'SK', name: 'Slovakia', phonePrefix: '+421', flag: '🇸🇰'),
    Country(code: 'SI', name: 'Slovenia', phonePrefix: '+386', flag: '🇸🇮'),
    Country(code: 'HR', name: 'Croatia', phonePrefix: '+385', flag: '🇭🇷'),
    Country(code: 'RO', name: 'Romania', phonePrefix: '+40', flag: '🇷🇴'),
    Country(code: 'BG', name: 'Bulgaria', phonePrefix: '+359', flag: '🇧🇬'),
    Country(code: 'LT', name: 'Lithuania', phonePrefix: '+370', flag: '🇱🇹'),
    Country(code: 'LV', name: 'Latvia', phonePrefix: '+371', flag: '🇱🇻'),
    Country(code: 'EE', name: 'Estonia', phonePrefix: '+372', flag: '🇪🇪'),
    Country(code: 'JP', name: 'Japan', phonePrefix: '+81', flag: '🇯🇵'),
    Country(code: 'KR', name: 'South Korea', phonePrefix: '+82', flag: '🇰🇷'),
    Country(code: 'CN', name: 'China', phonePrefix: '+86', flag: '🇨🇳'),
    Country(code: 'IN', name: 'India', phonePrefix: '+91', flag: '🇮🇳'),
    Country(code: 'SG', name: 'Singapore', phonePrefix: '+65', flag: '🇸🇬'),
    Country(code: 'HK', name: 'Hong Kong', phonePrefix: '+852', flag: '🇭🇰'),
    Country(code: 'TW', name: 'Taiwan', phonePrefix: '+886', flag: '🇹🇼'),
    Country(code: 'TH', name: 'Thailand', phonePrefix: '+66', flag: '🇹🇭'),
    Country(code: 'MY', name: 'Malaysia', phonePrefix: '+60', flag: '🇲🇾'),
    Country(code: 'ID', name: 'Indonesia', phonePrefix: '+62', flag: '🇮🇩'),
    Country(code: 'PH', name: 'Philippines', phonePrefix: '+63', flag: '🇵🇭'),
    Country(code: 'VN', name: 'Vietnam', phonePrefix: '+84', flag: '🇻🇳'),
    Country(code: 'BR', name: 'Brazil', phonePrefix: '+55', flag: '🇧🇷'),
    Country(code: 'AR', name: 'Argentina', phonePrefix: '+54', flag: '🇦🇷'),
    Country(code: 'MX', name: 'Mexico', phonePrefix: '+52', flag: '🇲🇽'),
    Country(code: 'CL', name: 'Chile', phonePrefix: '+56', flag: '🇨🇱'),
    Country(code: 'CO', name: 'Colombia', phonePrefix: '+57', flag: '🇨🇴'),
    Country(code: 'PE', name: 'Peru', phonePrefix: '+51', flag: '🇵🇪'),
    Country(code: 'ZA', name: 'South Africa', phonePrefix: '+27', flag: '🇿🇦'),
    Country(code: 'EG', name: 'Egypt', phonePrefix: '+20', flag: '🇪🇬'),
    Country(code: 'NG', name: 'Nigeria', phonePrefix: '+234', flag: '🇳🇬'),
    Country(code: 'KE', name: 'Kenya', phonePrefix: '+254', flag: '🇰🇪'),
    Country(code: 'MA', name: 'Morocco', phonePrefix: '+212', flag: '🇲🇦'),
    Country(code: 'TN', name: 'Tunisia', phonePrefix: '+216', flag: '🇹🇳'),
    Country(code: 'DZ', name: 'Algeria', phonePrefix: '+213', flag: '🇩🇿'),
    Country(code: 'RU', name: 'Russia', phonePrefix: '+7', flag: '🇷🇺'),
    Country(code: 'UA', name: 'Ukraine', phonePrefix: '+380', flag: '🇺🇦'),
    Country(code: 'TR', name: 'Turkey', phonePrefix: '+90', flag: '🇹🇷'),
    Country(code: 'IL', name: 'Israel', phonePrefix: '+972', flag: '🇮🇱'),
    Country(
        code: 'AE',
        name: 'United Arab Emirates',
        phonePrefix: '+971',
        flag: '🇦🇪'),
    Country(
        code: 'SA', name: 'Saudi Arabia', phonePrefix: '+966', flag: '🇸🇦'),
    Country(code: 'KW', name: 'Kuwait', phonePrefix: '+965', flag: '🇰🇼'),
    Country(code: 'QA', name: 'Qatar', phonePrefix: '+974', flag: '🇶🇦'),
    Country(code: 'BH', name: 'Bahrain', phonePrefix: '+973', flag: '🇧🇭'),
    Country(code: 'OM', name: 'Oman', phonePrefix: '+968', flag: '🇴🇲'),
    Country(code: 'JO', name: 'Jordan', phonePrefix: '+962', flag: '🇯🇴'),
    Country(code: 'LB', name: 'Lebanon', phonePrefix: '+961', flag: '🇱🇧'),
    Country(code: 'CY', name: 'Cyprus', phonePrefix: '+357', flag: '🇨🇾'),
    Country(code: 'MT', name: 'Malta', phonePrefix: '+356', flag: '🇲🇹'),
    Country(code: 'IS', name: 'Iceland', phonePrefix: '+354', flag: '🇮🇸'),
    Country(code: 'LU', name: 'Luxembourg', phonePrefix: '+352', flag: '🇱🇺'),
  ];

  static Country? getCountryByCode(String code) {
    try {
      return countries.firstWhere((country) => country.code == code);
    } catch (e) {
      return null;
    }
  }

  static Country? getCountryByPhonePrefix(String phoneNumber) {
    try {
      return countries
          .firstWhere((country) => phoneNumber.startsWith(country.phonePrefix));
    } catch (e) {
      return null;
    }
  }

  String formatPhoneNumber(String phoneNumber) {
    // Remove any non-digit characters except +
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // If it already starts with our prefix, return as is
    if (cleaned.startsWith(phonePrefix)) {
      return cleaned;
    }

    // If it starts with +, check if it's a different country prefix
    if (cleaned.startsWith('+')) {
      // Check if it's already a complete international number
      String withoutPlus = cleaned.substring(1);

      // If it starts with our country's prefix (without +), add the + back
      if (withoutPlus.startsWith(phonePrefix.substring(1))) {
        return cleaned; // Return as is with the +
      }

      // If it's a different country's number, return as is
      return cleaned;
    }

    // For local numbers without +, add our prefix
    return '$phonePrefix$cleaned';
  }

  String formatLocalPhoneNumber(String phoneNumber) {
    // Remove any non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // If it starts with our country code (without +), remove it
    String countryCode = phonePrefix.substring(1); // Remove the + from prefix
    if (cleaned.startsWith(countryCode)) {
      cleaned = cleaned.substring(countryCode.length);
    }

    // Return just the local number part
    return cleaned;
  }

  String getPhonePlaceholder() {
    switch (code) {
      case 'US':
      case 'CA':
        return '(555) 123-4567';
      case 'GB':
        return '20 7946 0958';
      case 'AU':
        return '2 1234 5678';
      case 'DE':
        return '30 12345678';
      case 'FR':
        return '1 23 45 67 89';
      case 'IT':
        return '3 1234 5678';
      case 'ES':
        return '91 123 45 67';
      case 'NL':
        return '6 12345678';
      case 'SE':
        return '70 123 45 67';
      case 'NO':
        return '40 12 34 56';
      case 'DK':
        return '20 12 34 56';
      case 'FI':
        return '40 123 4567';
      case 'CH':
        return '44 123 45 67';
      case 'AT':
        return '1 234 5678';
      case 'BE':
        return '4 123 45 67';
      case 'IE':
        return '1 234 5678';
      case 'PT':
        return '91 234 5678';
      case 'GR':
        return '21 1234 5678';
      case 'PL':
        return '12 345 67 89';
      case 'CZ':
        return '123 456 789';
      case 'HU':
        return '1 234 5678';
      case 'SK':
        return '123 456 789';
      case 'SI':
        return '1 234 5678';
      case 'HR':
        return '1 234 5678';
      case 'RO':
        return '21 123 4567';
      case 'BG':
        return '2 123 4567';
      case 'LT':
        return '612 34567';
      case 'LV':
        return '2123 4567';
      case 'EE':
        return '123 4567';
      case 'JP':
        return '90-1234-5678';
      case 'KR':
        return '10-1234-5678';
      case 'CN':
        return '138 0013 8000';
      case 'IN':
        return '98765 43210';
      case 'IS': // Iceland
        return '123 4567';
      case 'BR':
        return '11 91234-5678';
      case 'MX':
        return '55 1234 5678';
      case 'AR':
        return '11 1234-5678';
      case 'CL':
        return '2 1234 5678';
      case 'CO':
        return '1 234 5678';
      case 'PE':
        return '1 234 5678';
      case 'VE':
        return '212 123-4567';
      case 'RU':
        return '912 123-45-67';
      case 'UA':
        return '50 123 45 67';
      case 'BY':
        return '29 123-45-67';
      case 'KZ':
        return '701 123 45 67';
      case 'UZ':
        return '90 123 45 67';
      case 'KG':
        return '700 123 456';
      case 'TJ':
        return '90 123 45 67';
      case 'TM':
        return '60 12 34 56';
      case 'AF':
        return '70 123 4567';
      case 'PK':
        return '300 1234567';
      case 'BD':
        return '1712 345678';
      case 'LK':
        return '77 123 4567';
      case 'NP':
        return '980 123 4567';
      case 'BT':
        return '17 12 34 56';
      case 'MV':
        return '790 1234';
      case 'TH':
        return '81 234 5678';
      case 'VN':
        return '90 123 45 67';
      case 'KH':
        return '12 345 678';
      case 'LA':
        return '20 1234 5678';
      case 'MM':
        return '9 123 456 789';
      case 'MY':
        return '12-345 6789';
      case 'SG':
        return '8123 4567';
      case 'ID':
        return '812-3456-7890';
      case 'PH':
        return '917 123 4567';
      case 'TW':
        return '912 345 678';
      case 'HK':
        return '9123 4567';
      case 'MO':
        return '6123 4567';
      case 'NZ':
        return '21 123 4567';
      case 'FJ':
        return '123 4567';
      case 'PG':
        return '123 4567';
      case 'SB':
        return '12345';
      case 'VU':
        return '12345';
      case 'NC':
        return '12 34 56';
      case 'PF':
        return '12 34 56';
      case 'WS':
        return '12345';
      case 'TO':
        return '12345';
      case 'KI':
        return '12345';
      case 'TV':
        return '12345';
      case 'NR':
        return '12345';
      case 'PW':
        return '123 4567';
      case 'FM':
        return '123 4567';
      case 'MH':
        return '123 4567';
      case 'SB':
        return '12345';
      default:
        return '123 456 7890';
    }
  }

  String getLocalPhonePlaceholder() {
    switch (code) {
      case 'US':
      case 'CA':
        return '(555) 123-4567';
      case 'GB':
        return '20 7946 0958';
      case 'AU':
        return '2 1234 5678';
      case 'DE':
        return '30 12345678';
      case 'FR':
        return '1 23 45 67 89';
      case 'IT':
        return '3 1234 5678';
      case 'ES':
        return '91 123 45 67';
      case 'NL':
        return '6 12345678';
      case 'SE':
        return '70 123 45 67';
      case 'NO':
        return '40 12 34 56';
      case 'DK':
        return '20 12 34 56';
      case 'FI':
        return '40 123 4567';
      case 'CH':
        return '44 123 45 67';
      case 'AT':
        return '1 234 5678';
      case 'BE':
        return '4 123 45 67';
      case 'IE':
        return '1 234 5678';
      case 'PT':
        return '91 234 5678';
      case 'GR':
        return '21 1234 5678';
      case 'PL':
        return '12 345 67 89';
      case 'CZ':
        return '123 456 789';
      case 'HU':
        return '1 234 5678';
      case 'SK':
        return '123 456 789';
      case 'SI':
        return '1 234 5678';
      case 'HR':
        return '1 234 5678';
      case 'RO':
        return '21 123 4567';
      case 'BG':
        return '2 123 4567';
      case 'LT':
        return '612 34567';
      case 'LV':
        return '2123 4567';
      case 'EE':
        return '123 4567';
      case 'JP':
        return '90-1234-5678';
      case 'KR':
        return '10-1234-5678';
      case 'CN':
        return '138 0013 8000';
      case 'IN':
        return '98765 43210';
      case 'IS': // Iceland
        return '123 4567';
      case 'BR':
        return '11 91234-5678';
      case 'MX':
        return '55 1234 5678';
      case 'AR':
        return '11 1234-5678';
      case 'CL':
        return '2 1234 5678';
      case 'CO':
        return '1 234 5678';
      case 'PE':
        return '1 234 5678';
      case 'VE':
        return '212 123-4567';
      case 'RU':
        return '912 123-45-67';
      case 'UA':
        return '50 123 45 67';
      case 'BY':
        return '29 123-45-67';
      case 'KZ':
        return '701 123 45 67';
      case 'UZ':
        return '90 123 45 67';
      case 'KG':
        return '700 123 456';
      case 'TJ':
        return '90 123 45 67';
      case 'TM':
        return '60 12 34 56';
      case 'AF':
        return '70 123 4567';
      case 'PK':
        return '300 1234567';
      case 'BD':
        return '1712 345678';
      case 'LK':
        return '77 123 4567';
      case 'NP':
        return '980 123 4567';
      case 'BT':
        return '17 12 34 56';
      case 'MV':
        return '790 1234';
      case 'TH':
        return '81 234 5678';
      case 'VN':
        return '90 123 45 67';
      case 'KH':
        return '12 345 678';
      case 'LA':
        return '20 1234 5678';
      case 'MM':
        return '9 123 456 789';
      case 'MY':
        return '12-345 6789';
      case 'SG':
        return '8123 4567';
      case 'ID':
        return '812-3456-7890';
      case 'PH':
        return '917 123 4567';
      case 'TW':
        return '912 345 678';
      case 'HK':
        return '9123 4567';
      case 'MO':
        return '6123 4567';
      case 'NZ':
        return '21 123 4567';
      case 'FJ':
        return '123 4567';
      case 'PG':
        return '123 4567';
      case 'SB':
        return '12345';
      case 'VU':
        return '12345';
      case 'NC':
        return '12 34 56';
      case 'PF':
        return '12 34 56';
      case 'WS':
        return '12345';
      case 'TO':
        return '12345';
      case 'KI':
        return '12345';
      case 'TV':
        return '12345';
      case 'NR':
        return '12345';
      case 'PW':
        return '123 4567';
      case 'FM':
        return '123 4567';
      case 'MH':
        return '123 4567';
      case 'SB':
        return '12345';
      default:
        return '123 456 7890';
    }
  }

  @override
  String toString() => '$flag $name ($phonePrefix)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}
