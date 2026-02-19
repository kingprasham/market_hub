/// Structured data for the market update
class MarketReport {
  final String title;
  final String subtitle;
  final List<CityRates> cities;
  final String disclaimer;
  final String contact;

  const MarketReport({
    required this.title,
    required this.subtitle,
    required this.cities,
    required this.disclaimer,
    required this.contact,
  });
}

class CityRates {
  final String cityName;
  final String? subtitle;
  final List<RateItem> rates;

  const CityRates({
    required this.cityName,
    this.subtitle,
    required this.rates,
  });
}

class RateItem {
  final String label;
  final String value;

  const RateItem(this.label, this.value);
}

/// Hardcoded data for "ALL INDIA COPPER PRICE UPDATE"
const MarketReport copperReport = MarketReport(
  title: 'ALL INDIA COPPER PRICE UPDATE',
  subtitle: 'Reference Rates Only',
  disclaimer: 'Reference Rates Only',
  contact: 'MARKET HUB : 86240-72648, 0250-2469270',
  cities: [
    CityRates(
      cityName: 'BHIWADI MARKET',
      rates: [
        RateItem('CCR ROD', '1215+'),
        RateItem('SCRAP (ARM)', ''),
        RateItem('CASH', '1130+'),
        RateItem('CREDIT', '1132+'),
      ],
    ),
    CityRates(
      cityName: 'DELHI',
      rates: [
        RateItem('COPPER ROD (8 MM / 1.6MM)', ''),
        RateItem('CC ROD', '1240+/1330/(1.6 MM: 1340)'),
        RateItem('CCR ROD', '1215+/1285/(1.6 MM: 1295)'),
        RateItem('SUPER D', '1193+/1258/(1.6 MM: 1272)'),
        RateItem('ZERO', '1183+/1248/(1.6 MM: 1262)'),
      ],
    ),
    CityRates(
      cityName: 'MUMBAI',
      rates: [
        RateItem('COPPER ARM (CREDIT)', '1155+'),
        RateItem('COPPER UTENSILS SCRAP', '1075+'),
        RateItem('JALI PATTI/HEAVY SCRAP', '1165+'),
        RateItem('LAL PATTI/COPPER CABLE', '1175+'),
      ],
    ),
    CityRates(
      cityName: 'AHMEDABAD',
      subtitle: '(PLUS GST RATE)',
      rates: [
        RateItem('COPPER CCR', '1180'),
        RateItem('COPPER CCR 1.6 MM', '1190'),
        RateItem('BUNCH', '1212'),
        RateItem('TUKADI', '1142'),
        RateItem('SCRAP (ARM)', '1105'),
      ],
    ),
    CityRates(
      cityName: 'PUNE',
      rates: [
        RateItem('SCRAP (ARM)', '1145'),
        RateItem('DELHI RASA', '1045'),
        RateItem('TAMBA BARTAN', '1055'),
      ],
    ),
    CityRates(
      cityName: 'HYDERABAD',
      rates: [
        RateItem('CC ROD', '1312+/1361'),
        RateItem('SUPER D', '1195+/1249'),
        RateItem('ARM', '1178'),
      ],
    ),
    CityRates(
      cityName: 'NAGPUR',
      rates: [
        RateItem('ARM', '1175'),
        RateItem('BARIK', '1117'),
        RateItem('KALYA', '1097'),
      ],
    ),
    CityRates(
      cityName: 'CHENNAI',
      rates: [
        RateItem('ARM', '1125'),
        RateItem('LAAL', '1135'),
        RateItem('SUPER', '1050'),
      ],
    ),
    CityRates(
      cityName: 'KOLKATA',
      rates: [
        RateItem('ARM', '1170'),
        RateItem('JALA', '1180'),
        RateItem('SUPER', '1122'),
      ],
    ),
    CityRates(
      cityName: 'RAIPUR',
      rates: [
        RateItem('ARM', '1175'),
        RateItem('JALA', '1185'),
        RateItem('SUPER', '1125'),
      ],
    ),
  ],
);
