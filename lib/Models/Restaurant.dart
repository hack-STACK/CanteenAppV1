import 'package:kantin/Models/Food.dart';

class Restaurant {
  final List<Food> _menu = [
    Food(
      name: "Nasi Goreng",
      description: "Nasi yang digoreng dengan bumbu spesial dan sayuran.",
      imagePath:
          "https://example.com/nasi_goreng.jpg", // Ganti dengan URL yang valid
      price: 15000,
      category: foodCategory.mainCourse,
      addOns: [
        foodAddOn(name: "Telur Mata Sapi", price: 3000),
        foodAddOn(name: "Ayam Crispy", price: 5000),
      ],
    ),
    Food(
      name: "Mie Goreng",
      description: "Mie yang digoreng dengan sayuran dan bumbu khas.",
      imagePath:
          "https://example.com/mie_goreng.jpg", // Ganti dengan URL yang valid
      price: 12000,
      category: foodCategory.mainCourse,
      addOns: [
        foodAddOn(name: "Bakso", price: 4000),
      ],
    ),
    Food(
      name: "Soto Ayam",
      description: "Sup ayam dengan rempah-rempah dan sayuran.",
      imagePath:
          "https://example.com/soto_ayam.jpg", // Ganti dengan URL yang valid
      price: 20000,
      category: foodCategory.mainCourse,
      addOns: [],
    ),
    Food(
      name: "Gado-Gado",
      description: "Salad sayuran dengan saus kacang.",
      imagePath:
          "https://example.com/gado_gado.jpg", // Ganti dengan URL yang valid
      price: 15000,
      category: foodCategory.healthy,
      addOns: [],
    ),
    Food(
      name: "Bakso",
      description: "Bakso daging sapi dalam kuah kaldu.",
      imagePath: "https://example.com/bakso.jpg", // Ganti dengan URL yang valid
      price: 18000,
      category: foodCategory.mainCourse,
      addOns: [
        foodAddOn(name: "Mie", price: 2000),
        foodAddOn(name: "Kerupuk", price: 3000),
      ],
    ),
    Food(
      name: "Pisang Goreng",
      description: "Pisang yang digoreng hingga crispy.",
      imagePath:
          "https://example.com/pisang_goreng.jpg", // Ganti dengan URL yang valid
      price: 8000,
      category: foodCategory.snacks,
      addOns: [],
    ),
    Food(
      name: "Kue Cubir",
      description: "Kue mini yang lembut dan manis.",
      imagePath:
          "https://example.com/kue_cubir.jpg", // Ganti dengan URL yang valid
      price: 6000,
      category: foodCategory.desserts,
      addOns: [],
    ),
    Food(
      name: "Roti Bakar",
      description: "Roti panggang dengan berbagai isian.",
      imagePath:
          "https://example.com/roti_bakar.jpg", // Ganti dengan URL yang valid
      price: 10000,
      category: foodCategory.snacks,
      addOns: [
        foodAddOn(name: "Cokelat", price: 2000),
        foodAddOn(name: "Keju", price: 3000),
      ],
    ),
    Food(
      name: "Es Teh Manis",
      description: "Teh manis yang disajikan dingin.",
      imagePath:
          "https://example.com/es_teh.jpg", // Ganti dengan URL yang valid
      price: 5000,
      category: foodCategory.beverages,
      addOns: [],
    ),
    Food(
      name: "Kerupuk",
      description: "Kerupuk renyah sebagai camilan.",
      imagePath:
          "https://example.com/kerupuk.jpg", // Ganti dengan URL yang valid
      price: 3000,
      category: foodCategory.snacks,
      addOns: [],
    ),
    Food(
      name: "Nasi Campur",
      description: "Nasi dengan berbagai lauk pauk.",
      imagePath:
          "https://example.com/nasi_campur.jpg", // Ganti dengan URL yang valid
      price: 18000,
      category: foodCategory.mainCourse,
      addOns: [
        foodAddOn(name: "Sambal", price: 2000),
      ],
    ),
    Food(
      name: "Tahu Tempe",
      description: "Tahu dan tempe goreng yang renyah.",
      imagePath:
          "https://example.com/tahu_tempe.jpg", // Ganti dengan URL yang valid
      price: 10000,
      category: foodCategory.healthy,
      addOns: [],
    ),
    Food(
      name: "Ayam Penyet",
      description: "Ayam yang digoreng dan disajikan dengan sambal.",
      imagePath:
          "https://example.com/ayam_penyet.jpg", // Ganti dengan URL yang valid
      price: 22000,
      category: foodCategory.mainCourse,
      addOns: [
        foodAddOn(name: "Nasi Putih", price: 3000),
        foodAddOn(name: "Sambal", price: 2000),
      ],
    ),
    Food(
      name: "Cendol",
      description: "Minuman manis dengan cendol dan santan.",
      imagePath:
          "https://example.com/cendol.jpg", // Ganti dengan URL yang valid
      price: 7000,
      category: foodCategory.desserts,
      addOns: [],
    ),
    Food(
      name: "Kwetiau Goreng",
      description: "Kwetiau yang digoreng dengan sayuran dan daging.",
      imagePath:
          "https://example.com/kwetiau_goreng.jpg", // Ganti dengan URL yang valid
      price: 15000,
      category: foodCategory.mainCourse,
      addOns: [
        foodAddOn(name: "Telur", price: 3000),
      ],
    ),
    Food(
      name: "Sate Ayam",
      description: "Sate ayam dengan bumbu kacang.",
      imagePath:
          "https://example.com/sate_ayam.jpg", // Ganti dengan URL yang valid
      price: 20000,
      category: foodCategory.mainCourse,
      addOns: [],
    ),
    Food(
      name: "Es Jeruk",
      description: "Minuman jeruk segar yang disajikan dingin.",
      imagePath:
          "https://example.com/es_jeruk.jpg", // Ganti dengan URL yang valid
      price: 6000,
      category: foodCategory.beverages,
      addOns: [],
    ),
    Food(
      name: "Martabak Manis",
      description: "Kue martabak manis dengan berbagai isian.",
      imagePath:
          "https://example.com/martabak_manis.jpg", // Ganti dengan URL yang valid
      price: 15000,
      category: foodCategory.desserts,
      addOns: [
        foodAddOn(name: "Kacang", price: 2000),
        foodAddOn(name: "Keju", price: 3000),
      ],
    ),
    Food(
      name: "Nasi Uduk",
      description: "Nasi yang dimasak dengan santan dan rempah.",
      imagePath:
          "https://example.com/nasi_uduk.jpg", // Ganti dengan URL yang valid
      price: 16000,
      category: foodCategory.mainCourse,
      addOns: [],
    ),
  ];
}
