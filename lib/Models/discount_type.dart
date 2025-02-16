enum DiscountType {
  mainPrice('Main Price'),
  addons('Add-ons'),
  both('Both');

  final String display;
  const DiscountType(this.display);

  String get value {
    switch (this) {
      case DiscountType.mainPrice:
        return 'mainPrice';
      case DiscountType.addons:
        return 'addons';
      case DiscountType.both:
        return 'both';
    }
  }

  static DiscountType fromString(String type) {
    switch (type) {
      case 'mainPrice':
        return DiscountType.mainPrice;
      case 'addons':
        return DiscountType.addons;
      case 'both':
        return DiscountType.both;
      default:
        return DiscountType.mainPrice;
    }
  }
}
