/// Data model for ad content displayed in the home carousel and detail screen.
class AdData {
  final int id;
  final String imagePath;
  final String carouselTitle;
  final String carouselSubtitle;
  final String companyName;
  final String heading;
  final List<AdInfoItem> infoItems;
  final List<AdContactItem> contacts;
  final String? disclaimer;

  const AdData({
    required this.id,
    required this.imagePath,
    required this.carouselTitle,
    required this.carouselSubtitle,
    required this.companyName,
    required this.heading,
    required this.infoItems,
    required this.contacts,
    this.disclaimer,
  });
}

class AdInfoItem {
  final String title;
  final String description;
  final String iconName;

  const AdInfoItem({
    required this.title,
    required this.description,
    this.iconName = 'info',
  });
}

class AdContactItem {
  final String type; // 'phone', 'email', 'website', 'whatsapp'
  final String label;
  final String uri;

  const AdContactItem({
    required this.type,
    required this.label,
    required this.uri,
  });
}

/// All 7 ads data
const List<AdData> allAds = [
  // Ad 1 — RNT METALS
  AdData(
    id: 1,
    imagePath: 'assets/images/1.jpeg',
    carouselTitle: 'RNT METALS PVT LTD',
    carouselSubtitle: 'Continuous Casting Copper Rod Manufacturer',
    companyName: 'MARKET HUB',
    heading: 'RNT METALS PVT LTD',
    infoItems: [
      AdInfoItem(
        title: 'Manufacturing Unit',
        description: 'Continuous Casting Copper Rod 8mm, 12.5mm',
        iconName: 'factory',
      ),
      AdInfoItem(
        title: 'Supply',
        description: 'Good Quality CCR 8mm, 12.5mm',
        iconName: 'verified',
      ),
      AdInfoItem(
        title: 'Looking For',
        description: 'Genuine Suppliers Of Copper Scrap (Only Import)',
        iconName: 'search',
      ),
      AdInfoItem(
        title: 'Plant',
        description: 'Khushkhera, Bhiwadi, Rajasthan',
        iconName: 'location',
      ),
    ],
    contacts: [
      AdContactItem(type: 'phone', label: '9999909345', uri: 'tel:9999909345'),
      AdContactItem(type: 'email', label: 'rntmetals@gmail.com', uri: 'mailto:rntmetals@gmail.com'),
    ],
  ),

  // Ad 2 — Masters India
  AdData(
    id: 2,
    imagePath: 'assets/images/2.jpeg',
    carouselTitle: 'Masters India IT Solutions',
    carouselSubtitle: 'Comprehensive Vendor & Vehicle Verification',
    companyName: 'MASTERS INDIA IT SOLUTIONS',
    heading: 'Comprehensive Solution For',
    infoItems: [
      AdInfoItem(
        title: 'Physical Verification',
        description: 'Physical verification of vendor address',
        iconName: 'verified',
      ),
      AdInfoItem(
        title: 'FASTag Tracking',
        description: 'Tracking vehicle movement via FASTag automatically',
        iconName: 'location',
      ),
      AdInfoItem(
        title: 'Invoice Proof',
        description: 'Storing Invoice wise delivery Proof for future reference',
        iconName: 'document',
      ),
      AdInfoItem(
        title: 'Vehicle Verification',
        description: 'Complete vehicle verification service',
        iconName: 'search',
      ),
    ],
    contacts: [
      AdContactItem(type: 'phone', label: '+91 95608-07771', uri: 'tel:+919560807771'),
      AdContactItem(type: 'whatsapp', label: 'WhatsApp', uri: 'https://wa.me/919560807771'),
      AdContactItem(type: 'email', label: 'info@mastersindia.co', uri: 'mailto:info@mastersindia.co'),
    ],
  ),

  // Ad 3 — Cutech Alloys
  AdData(
    id: 3,
    imagePath: 'assets/images/3.jpeg',
    carouselTitle: 'Cutech Alloys Pvt. Ltd.',
    carouselSubtitle: 'Copper Alloys Remelting Ingots Manufacturer',
    companyName: 'MARKET HUB',
    heading: 'LOOKING FOR SUPPLIERS',
    infoItems: [
      AdInfoItem(
        title: 'Company',
        description: 'M/s Cutech Alloys Pvt. Ltd., Bhavnagar, Gujarat',
        iconName: 'factory',
      ),
      AdInfoItem(
        title: 'Manufacturing',
        description: 'Copper Alloys Remelting Ingots as per all International Standards with precision',
        iconName: 'verified',
      ),
      AdInfoItem(
        title: 'Looking for Suppliers',
        description: 'Gunmetal, Aluminum Bronze, Copper Nickel 90/10, 95/5, 70/30, Monel',
        iconName: 'search',
      ),
      AdInfoItem(
        title: 'Looking for Buyers',
        description: 'Copper Alloy Ingots',
        iconName: 'info',
      ),
    ],
    contacts: [
      AdContactItem(type: 'phone', label: '9888420855 (Mr. Abhinav Garg)', uri: 'tel:9888420855'),
      AdContactItem(type: 'website', label: 'www.cutechalloys.com', uri: 'https://www.cutechalloys.com'),
      AdContactItem(type: 'email', label: 'director@cutechalloys.com', uri: 'mailto:director@cutechalloys.com'),
    ],
    disclaimer: 'This Is A Paid Advertisement, Market Hub Is Not Responsible For Any Profit Or Loss',
  ),

  // Ad 4 — Naveen Jain Metal Udyog
  AdData(
    id: 4,
    imagePath: 'assets/images/4.jpeg',
    carouselTitle: 'Naveen Jain Metal Udyog',
    carouselSubtitle: 'Trusted Since 1966 | ISO & IATF Certified',
    companyName: 'MARKET HUB',
    heading: 'NAVEEN JAIN METAL UDYOG',
    infoItems: [
      AdInfoItem(
        title: 'Certifications',
        description: 'ISO 9001:2015, ISO 14001:2015, ISO 45001:2018, IATF',
        iconName: 'verified',
      ),
      AdInfoItem(
        title: 'Manufacturing',
        description: 'Leading Manufacturer of High-Quality Prime & Recycled Zinc Ingots',
        iconName: 'factory',
      ),
      AdInfoItem(
        title: 'Known For',
        description: 'Environmental Sustainability, Customized Solutions, Reliability, and Timely Deliveries',
        iconName: 'info',
      ),
      AdInfoItem(
        title: 'Zinc Scrap',
        description: 'Die Cast, Shredded, Zinc Score & More',
        iconName: 'search',
      ),
      AdInfoItem(
        title: 'Non-Ferrous Scrap',
        description: 'Aluminium, Copper, Brass, Lead',
        iconName: 'search',
      ),
      AdInfoItem(
        title: 'Plant Address',
        description: '20/4, Main Mathura Road, Nepco Bevel Gear Compound, Faridabad, Haryana - 121004',
        iconName: 'location',
      ),
    ],
    contacts: [
      AdContactItem(type: 'phone', label: '+91 9990666158', uri: 'tel:+919990666158'),
      AdContactItem(type: 'website', label: 'www.njmu.in', uri: 'http://www.njmu.in'),
      AdContactItem(type: 'email', label: 'sales@njmu.in', uri: 'mailto:sales@njmu.in'),
    ],
  ),

  // Ad 5 — TUMAS Special Steel & Metal
  AdData(
    id: 5,
    imagePath: 'assets/images/5.jpeg',
    carouselTitle: 'TUMAS Special Steel & Metal',
    carouselSubtitle: 'Ferrous & Non-Ferrous Processor | 24x7 Service',
    companyName: 'MARKET HUB',
    heading: 'TUMAS SPECIAL STEEL & METAL',
    infoItems: [
      AdInfoItem(
        title: 'Steel Types',
        description: 'Alloy • Die Block • Hot die • Tool • HSS • OHNS • Spring • Case Hardening • Nitriding',
        iconName: 'factory',
      ),
      AdInfoItem(
        title: 'Rolls',
        description: 'HCHCR • HICRO • Cr-Mo • Cr-Ni • Ni-Hard • Mn Steel',
        iconName: 'info',
      ),
      AdInfoItem(
        title: 'Stainless',
        description: 'SS (Series 200/300/400) • Alloy 20 • Castings • Heat Resistant',
        iconName: 'verified',
      ),
      AdInfoItem(
        title: 'Special Alloys',
        description: 'Inconel • Incoloy • Monel • Ni-Chrome • Nimonic • Silver • Cupro Ni • Hastelloy',
        iconName: 'info',
      ),
      AdInfoItem(
        title: 'Power Grades',
        description: 'P91/F91 • P22/F22 • P11/F11 • P9/F9',
        iconName: 'info',
      ),
      AdInfoItem(
        title: 'Job Work',
        description: 'Furnace • Forging • Rolling • Finished • Machining • Fabrication • Spares • Tools',
        iconName: 'factory',
      ),
      AdInfoItem(
        title: 'Motto',
        description: 'Quality • Service • Commitment – Where Quality Meets Excellence',
        iconName: 'verified',
      ),
    ],
    contacts: [
      AdContactItem(type: 'phone', label: '+91 98313 18231', uri: 'tel:+919831318231'),
      AdContactItem(type: 'phone', label: '+91 93316 90718', uri: 'tel:+919331690718'),
      AdContactItem(type: 'phone', label: '+91 98305 86674', uri: 'tel:+919830586674'),
      AdContactItem(type: 'email', label: 'truthudyogmetalsteel@gmail.com', uri: 'mailto:truthudyogmetalsteel@gmail.com'),
      AdContactItem(type: 'website', label: 'www.tumasgroup.in', uri: 'https://www.tumasgroup.in'),
    ],
  ),

  // Ad 6 — Palvi Industries
  AdData(
    id: 6,
    imagePath: 'assets/images/6.jpeg',
    carouselTitle: 'Palvi Industries Limited',
    carouselSubtitle: 'Molybdenum Oxide & Ferro Molybdenum Since 1996',
    companyName: 'MARKET HUB',
    heading: 'PALVI INDUSTRIES LIMITED',
    infoItems: [
      AdInfoItem(
        title: 'Since',
        description: '1996 | ISO 9001:2015, ISO 14001:2015, ISO 45001:2018 Certified',
        iconName: 'verified',
      ),
      AdInfoItem(
        title: 'Manufacturing',
        description: 'Leading manufacturer of Molybdenum Oxide & Ferro Molybdenum',
        iconName: 'factory',
      ),
      AdInfoItem(
        title: 'Products',
        description: 'Molybdenum Oxide, Ferro Molybdenum, Ferro Silicon, Zinc Ingots, Copper Cathode, Nickel Cathode, Cobalt Cathode, Cobalt Sulphate, Lithium Carbonate, Copper Sulphate',
        iconName: 'info',
      ),
      AdInfoItem(
        title: 'Office',
        description: '315, Aditviya Complex, Nr. Deluxe, Nizampura, Vadodara - 390002',
        iconName: 'location',
      ),
    ],
    contacts: [
      AdContactItem(type: 'phone', label: '9979711388 (Mr Aditya Bhavsar)', uri: 'tel:9979711388'),
      AdContactItem(type: 'email', label: 'aditya@palvichemical.com', uri: 'mailto:aditya@palvichemical.com'),
      AdContactItem(type: 'phone', label: '9998050676 (Ms Jasmin Lala)', uri: 'tel:9998050676'),
      AdContactItem(type: 'email', label: 'jasmin@palvichemical.com', uri: 'mailto:jasmin@palvichemical.com'),
      AdContactItem(type: 'website', label: 'www.palvichemical.com', uri: 'https://www.palvichemical.com'),
    ],
  ),

  // Ad 7 — Slag Grinding & Metal Separation
  AdData(
    id: 7,
    imagePath: 'assets/images/7.jpeg',
    carouselTitle: 'Slag Grinding Specialists',
    carouselSubtitle: "North India's Trusted Name | 30 Years Experience",
    companyName: 'MARKET HUB',
    heading: 'SLAG GRINDING & METAL SEPARATION SPECIALISTS',
    infoItems: [
      AdInfoItem(
        title: 'Experience',
        description: '30 साल की भरोसेमंद सेवा – North India\'s Trusted Name in Slag Processing',
        iconName: 'verified',
      ),
      AdInfoItem(
        title: 'Services (Hindi)',
        description: 'भट्टी का कीट/स्लैग/ड्रॉस की पिसाई, ताम्बा, पीतल, एल्युमिनियम, जस्ता की पिसाई, मिक्स मेटल से धातु और मिट्टी अलग करना',
        iconName: 'factory',
      ),
      AdInfoItem(
        title: 'Services (English)',
        description: 'Copper, Brass, Aluminium, Zinc & Mixed Metal Grinding. High-quality metal & dust separation. Advanced machinery.',
        iconName: 'info',
      ),
      AdInfoItem(
        title: 'Speciality',
        description: '100% Metal Recovery, Dust-Free & Efficient Grinding. We also buy slag/keet directly.',
        iconName: 'search',
      ),
      AdInfoItem(
        title: 'Location',
        description: 'New Mandoli Industrial Area, Delhi — Shyam Bihari (Mandoli Wale)',
        iconName: 'location',
      ),
    ],
    contacts: [
      AdContactItem(type: 'phone', label: '9811846141', uri: 'tel:9811846141'),
      AdContactItem(type: 'phone', label: '7042745580', uri: 'tel:7042745580'),
      AdContactItem(type: 'email', label: 'adiwires1010@gmail.com', uri: 'mailto:adiwires1010@gmail.com'),
    ],
  ),
];
