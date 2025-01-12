import 'package:flutter/material.dart';
import 'package:kantin/Models/Food.dart';
import 'package:kantin/Models/cartItem.dart';
import 'package:collection/collection.dart';

class Restaurant extends ChangeNotifier {
  final List<Food> _menu = [
    Food(
      name: "Nasi Goreng",
      description: "Nasi yang digoreng dengan bumbu spesial dan sayuran.",
      imagePath:
          "https://th.bing.com/th/id/OIP.NzSXtxNWD57kCe_7JuxC4wHaE8?rs=1&pid=ImgDetMain", // Ganti dengan URL yang valid
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
          "https://allofresh.id/blog/wp-content/uploads/2023/09/cara-membuat-mie-goreng-4-1-scaled.jpg", // Ganti dengan URL yang valid
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
          "https://icone-inc.org/wp-content/uploads/2018/11/Soto-Ayam-2-micita.jpeg", // Ganti dengan URL yang valid
      price: 20000,
      category: foodCategory.mainCourse,
      addOns: [],
    ),
    Food(
      name: "Gado-Gado",
      description: "Salad sayuran dengan saus kacang.",
      imagePath:
          "https://www.wandercooks.com/wp-content/uploads/2020/11/gado-gado-salad-with-peanut-sauce-ft-1.jpg", // Ganti dengan URL yang valid
      price: 15000,
      category: foodCategory.healthy,
      addOns: [],
    ),
    Food(
      name: "Bakso",
      description: "Bakso daging sapi dalam kuah kaldu.",
      imagePath:
          "https://cdn.tasteatlas.com/images/dishrestaurants/35a1edd0bee948e1bcf590b13f9f76c3.jpg", // Ganti dengan URL yang valid
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
          "https://cdn.kuali.com/wp-content/uploads/2021/09/02213920/crispy-pisang-goreng.jpg", // Ganti dengan URL yang valid
      price: 8000,
      category: foodCategory.snacks,
      addOns: [],
    ),
    Food(
      name: "Kue Cubir",
      description: "Kue mini yang lembut dan manis.",
      imagePath:
          "https://i0.wp.com/resepkoki.id/wp-content/uploads/2019/08/Resep-Kue-Cubit-Original.jpg?fit=1040%2C1300&ssl=1", // Ganti dengan URL yang valid
      price: 6000,
      category: foodCategory.desserts,
      addOns: [],
    ),
    Food(
      name: "Roti Bakar",
      description: "Roti panggang dengan berbagai isian.",
      imagePath:
          "https://th.bing.com/th/id/OIP.MUNsj5cc_HEdqiff8f7m5wHaFA?rs=1&pid=ImgDetMain", // Ganti dengan URL yang valid
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
          "https://i.pinimg.com/originals/5d/31/ef/5d31ef90cd6c389e07bc48a08e583122.jpg", // Ganti dengan URL yang valid
      price: 5000,
      category: foodCategory.beverages,
      addOns: [],
    ),
    Food(
      name: "Kerupuk",
      description: "Kerupuk renyah sebagai camilan.",
      imagePath:
          "https://s1.bukalapak.com/bukalapak-kontenz-production/content_attachments/55446/original/Kerupuk_Putih.jpg", // Ganti dengan URL yang valid
      price: 3000,
      category: foodCategory.snacks,
      addOns: [],
    ),
    Food(
      name: "Nasi Campur",
      description: "Nasi dengan berbagai lauk pauk.",
      imagePath:
          "https://i.pinimg.com/originals/e3/20/77/e32077057baa98e4fffa4c5abe048379.jpg", // Ganti dengan URL yang valid
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
          "https://img-global.cpcdn.com/recipes/c4f877da53e71f2e/751x532cq70/tahu-tempe-goreng-praktis-foto-resep-utama.jpg", // Ganti dengan URL yang valid
      price: 10000,
      category: foodCategory.healthy,
      addOns: [],
    ),
    Food(
      name: "Ayam Penyet",
      description: "Ayam yang digoreng dan disajikan dengan sambal.",
      imagePath:
          "https://th.bing.com/th/id/OIP.tX8cSRN65uqrta6l5wWFZAHaHa?rs=1&pid=ImgDetMain", // Ganti dengan URL yang valid
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
          "https://th.bing.com/th/id/OIP.f1mlxPZ88G29bFR0EyiDrgHaE8?rs=1&pid=ImgDetMain", // Ganti dengan URL yang valid
      price: 7000,
      category: foodCategory.desserts,
      addOns: [],
    ),
    Food(
      name: "Kwetiau Goreng",
      description: "Kwetiau yang digoreng dengan sayuran dan daging.",
      imagePath:
          "https://2.bp.blogspot.com/-Uwhu7PAikNQ/WImP41aNzmI/AAAAAAAAAZY/rH0GCe6w2oAECx0XLU6gAC2zKU21oYMMgCLcB/s1600/kwetiau.jpg", // Ganti dengan URL yang valid
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
          "https://th.bing.com/th/id/R.5834de0a24edc422553bb9a9015a5f39?rik=k5zGUWKEL1dE%2fQ&riu=http%3a%2f%2fwww.rumahmesin.com%2fwp-content%2fuploads%2f2017%2f03%2fresep-sate-ayam-madura-mencicipi-makanan-asli-indonesia-yang-mendunia.jpg&ehk=n42w6xcn41RbMbPvg19nltCAKInNNohJv9ZpDIUWphc%3d&risl=&pid=ImgRaw&r=0", // Ganti dengan URL yang valid
      price: 20000,
      category: foodCategory.mainCourse,
      addOns: [],
    ),
    Food(
      name: "Es Jeruk",
      description: "Minuman jeruk segar yang disajikan dingin.",
      imagePath:
          "https://dcostseafood.id/wp-content/uploads/2021/12/ES-JERUK-murni.jpg", // Ganti dengan URL yang valid
      price: 6000,
      category: foodCategory.beverages,
      addOns: [],
    ),
    Food(
      name: "Martabak Manis",
      description: "Kue martabak manis dengan berbagai isian.",
      imagePath:
          "https://th.bing.com/th/id/R.a3000f3aa654eedddc085f2873891344?rik=PMVn%2fT95nFBE1g&riu=http%3a%2f%2findonesiaexpat.biz%2fwp-content%2fuploads%2f2018%2f11%2fmartabak-manis.jpg&ehk=KbOqv%2bWoX1IMseI5cLxARqf4Oobsp55tqwUYTYFNnSY%3d&risl=&pid=ImgRaw&r=0", // Ganti dengan URL yang valid
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
          "https://img.freepik.com/fotos-premium/nasi-uduk-betawi-plato-arroz-al-vapor-sabor-coco-betawi-yakarta-sirve-varios-platos_431906-4501.jpg?w=2000", // Ganti dengan URL yang valid
      price: 16000,
      category: foodCategory.mainCourse,
      addOns: [],
    ),
  ];
  List<Food> get menu => _menu;

  final List<CartItem> _cart = [];

  void addToCart(Food food, List<foodAddOn> selectedAddOns) {
    CartItem? existingCart = _cart.firstWhereOrNull((item) {
      bool isSameFood = item.food == food;
      bool isSameAddOns =
          ListEquality().equals(item.selectedAddOns, selectedAddOns);
      return isSameFood && isSameAddOns;
    });

    if (existingCart != null) {
      existingCart.quantity++;
    } else {
      _cart.add(CartItem(food: food, selectedAddOns: selectedAddOns));
    }
    notifyListeners();
  }
}
