/// Complete Flutter models matching Django backend structure
/// All field names and types match the backend exactly for seamless API integration

// ============== ENUMS ==============
// Note: UserRole is defined in user_role_constants.dart
// Note: StatusBadgeWidget defines StockStatus, OrderStatus, InvoiceStatus

// Additional enums for backend compatibility
enum CustomerTypeEnum { individual, business }

enum TransactionMethodEnum { cash, card, khqr, bankTransfer, other }

enum TransactionStatusEnum { pending, completed, failed, refunded }

// ============== USER MODELS ==============
// Note: User model is defined in user_model.dart - imported via app_export.dart

/// UserProfile model - Matches Django UserProfile
class UserProfile {
  final int profileId;
  final int userId; // FK to User
  final String? qrCodeImage;
  final String? businessName;
  final String? businessAddress;
  final String? businessPhone;
  final String? businessEmail;
  final String? taxId;
  final DateTime updatedAt;

  UserProfile({
    required this.profileId,
    required this.userId,
    this.qrCodeImage,
    this.businessName,
    this.businessAddress,
    this.businessPhone,
    this.businessEmail,
    this.taxId,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      profileId: json['profileId'] ?? 0,
      userId: json['user'] ?? 0,
      qrCodeImage: json['qrCodeImage'],
      businessName: json['businessName'],
      businessAddress: json['businessAddress'],
      businessPhone: json['businessPhone'],
      businessEmail: json['businessEmail'],
      taxId: json['taxId'],
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileId': profileId,
      'user': userId,
      'qrCodeImage': qrCodeImage,
      'businessName': businessName,
      'businessAddress': businessAddress,
      'businessPhone': businessPhone,
      'businessEmail': businessEmail,
      'taxId': taxId,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

// ============== CATEGORY MODELS ==============

/// Category model - Matches Django Category
class Category {
  final int categoryId;
  final String name;
  final DateTime createdAt;

  Category({
    required this.categoryId,
    required this.name,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryId: json['categoryId'] ?? 0,
      name: json['name'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// SubCategory model - Matches Django SubCategory
class SubCategory {
  final int subcategoryId;
  final int categoryId; // FK to Category
  final String name;
  final DateTime createdAt;

  SubCategory({
    required this.subcategoryId,
    required this.categoryId,
    required this.name,
    required this.createdAt,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      subcategoryId: json['subcategoryId'] ?? 0,
      categoryId: json['category'] ?? 0,
      name: json['name'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subcategoryId': subcategoryId,
      'category': categoryId,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// ============== SUPPLIER/SOURCE MODELS ==============

/// Source model (Supplier) - Matches Django Source
class Source {
  final int sourceId;
  final String name;
  final String? sourceUrl;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String? district;
  final DateTime createdAt;

  Source({
    required this.sourceId,
    required this.name,
    this.sourceUrl,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.district,
    required this.createdAt,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      sourceId: json['sourceId'] ?? 0,
      name: json['name'] ?? '',
      sourceUrl: json['sourceUrl'],
      contactPerson: json['contactPerson'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      district: json['district'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sourceId': sourceId,
      'name': name,
      'sourceUrl': sourceUrl,
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'district': district,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// ============== PRODUCT MODELS ==============

/// Product model - Matches Django Product
class Product {
  final int productId;
  final String productName;
  final String description;
  final String? image;
  final String skuCode;
  final String unit;
  final double costPrice; // Original price from supplier
  final double salePrice; // Sale price to customers
  final double discount; // Discount percentage
  final int subcategoryId; // FK to SubCategory
  final int? sourceId; // FK to Source (nullable)
  final String status; // 'Active', 'Inactive', 'Discount'
  final DateTime createdAt;

  Product({
    required this.productId,
    required this.productName,
    required this.description,
    this.image,
    required this.skuCode,
    required this.unit,
    required this.costPrice,
    required this.salePrice,
    required this.discount,
    required this.subcategoryId,
    this.sourceId,
    required this.status,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['productId'] ?? 0,
      productName: json['productName'] ?? '',
      description: json['description'] ?? '',
      image: json['image'],
      skuCode: json['skuCode'] ?? '',
      unit: json['unit'] ?? '',
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      salePrice: (json['salePrice'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      subcategoryId: json['subcategory'] ?? 0,
      sourceId: json['source'],
      status: json['status'] ?? 'Active',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'description': description,
      'image': image,
      'skuCode': skuCode,
      'unit': unit,
      'costPrice': costPrice,
      'salePrice': salePrice,
      'discount': discount,
      'subcategory': subcategoryId,
      'source': sourceId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Inventory model - Matches Django Inventory
class Inventory {
  final int inventoryId;
  final int productId; // FK to Product
  final int quantity;
  final int reorderLevel;
  final String location;
  final DateTime updatedAt;

  Inventory({
    required this.inventoryId,
    required this.productId,
    required this.quantity,
    required this.reorderLevel,
    required this.location,
    required this.updatedAt,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      inventoryId: json['inventoryId'] ?? 0,
      productId: json['product'] ?? 0,
      quantity: json['quantity'] ?? 0,
      reorderLevel: json['reorderLevel'] ?? 0,
      location: json['location'] ?? '',
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inventoryId': inventoryId,
      'product': productId,
      'quantity': quantity,
      'reorderLevel': reorderLevel,
      'location': location,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// NewStock model - Matches Django NewStock
class NewStock {
  final int newstockId;
  final int inventoryId; // FK to Inventory
  final int quantity;
  final double purchasePrice;
  final DateTime receivedDate;
  final int? supplierId; // FK to Source (nullable)
  final int? addedByUserId; // FK to User (nullable)
  final String? note;
  final DateTime createdAt;

  NewStock({
    required this.newstockId,
    required this.inventoryId,
    required this.quantity,
    required this.purchasePrice,
    required this.receivedDate,
    this.supplierId,
    this.addedByUserId,
    this.note,
    required this.createdAt,
  });

  factory NewStock.fromJson(Map<String, dynamic> json) {
    return NewStock(
      newstockId: json['newstockId'] ?? 0,
      inventoryId: json['inventory'] ?? 0,
      quantity: json['quantity'] ?? 0,
      purchasePrice: (json['purchasePrice'] ?? 0).toDouble(),
      receivedDate: DateTime.parse(
        json['receivedDate'] ?? DateTime.now().toString(),
      ),
      supplierId: json['supplier'],
      addedByUserId: json['addedByUser'],
      note: json['note'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'newstockId': newstockId,
      'inventory': inventoryId,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'receivedDate': receivedDate.toIso8601String(),
      'supplier': supplierId,
      'addedByUser': addedByUserId,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// ============== CUSTOMER MODELS ==============

/// Customer model - Matches Django Customer
class Customer {
  final int customerId;
  final String name;
  final String businessAddress;
  final String phone;
  final String? email;
  final String
  customerType; // 'Individual' or 'Business' (string for backend compatibility)
  final DateTime? firstPurchaseDate;
  final DateTime createdAt;

  Customer({
    required this.customerId,
    required this.name,
    required this.businessAddress,
    required this.phone,
    this.email,
    required this.customerType,
    this.firstPurchaseDate,
    required this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerId: json['customerId'] ?? 0,
      name: json['name'] ?? '',
      businessAddress: json['businessAddress'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      customerType: json['customerType'] ?? 'Individual',
      firstPurchaseDate: json['firstPurchaseDate'] != null
          ? DateTime.parse(json['firstPurchaseDate'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'name': name,
      'businessAddress': businessAddress,
      'phone': phone,
      'email': email,
      'customerType': customerType,
      'firstPurchaseDate': firstPurchaseDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// ============== INVOICE/ORDER MODELS ==============

/// Invoice model - Matches Django Invoice (renamed from Order for clarity)
class Invoice {
  final int invoiceId;
  final String? invoiceNumber;
  final int? customerId; // FK to Customer (nullable)
  final String customerName;
  final String? customerPhone;
  final int? createdByUserId; // FK to User (nullable)
  final double totalBeforeDiscount;
  final double discount;
  final double tax;
  final double grandTotal;
  final String paymentMethod; // 'Cash', 'KHQR'
  final String? note;
  final String status; // 'Pending', 'Paid', 'Cancelled'
  final DateTime? paidAt;
  final String? khqrCodeString;
  final String? khqrMd5;
  final String? khqrTransactionHash;
  final String? khqrShortHash;
  final String? khqrDeeplink;
  final DateTime? khqrLastCheckedAt;
  final Map<String, dynamic>? khqrPaymentData;
  final DateTime createdAt;
  final List<Purchase> purchases; // Line items

  Invoice({
    required this.invoiceId,
    this.invoiceNumber,
    this.customerId,
    required this.customerName,
    this.customerPhone,
    this.createdByUserId,
    required this.totalBeforeDiscount,
    required this.discount,
    required this.tax,
    required this.grandTotal,
    required this.paymentMethod,
    this.note,
    required this.status,
    this.paidAt,
    this.khqrCodeString,
    this.khqrMd5,
    this.khqrTransactionHash,
    this.khqrShortHash,
    this.khqrDeeplink,
    this.khqrLastCheckedAt,
    this.khqrPaymentData,
    required this.createdAt,
    this.purchases = const [],
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      invoiceId: json['invoiceId'] ?? 0,
      invoiceNumber: json['invoiceNumber'],
      customerId: json['customer'],
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'],
      createdByUserId: json['createdByUser'],
      totalBeforeDiscount: (json['totalBeforeDiscount'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      grandTotal: (json['grandTotal'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? 'Cash',
      note: json['note'],
      status: json['status'] ?? 'Pending',
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      khqrCodeString: json['khqrCodeString'],
      khqrMd5: json['khqrMd5'],
      khqrTransactionHash: json['khqrTransactionHash'],
      khqrShortHash: json['khqrShortHash'],
      khqrDeeplink: json['khqrDeeplink'],
      khqrLastCheckedAt: json['khqrLastCheckedAt'] != null
          ? DateTime.parse(json['khqrLastCheckedAt'])
          : null,
      khqrPaymentData: json['khqrPaymentData'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      purchases:
          (json['purchases'] as List?)
              ?.map((p) => Purchase.fromJson(p))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'customer': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'createdByUser': createdByUserId,
      'totalBeforeDiscount': totalBeforeDiscount,
      'discount': discount,
      'tax': tax,
      'grandTotal': grandTotal,
      'paymentMethod': paymentMethod,
      'note': note,
      'status': status,
      'paidAt': paidAt?.toIso8601String(),
      'khqrCodeString': khqrCodeString,
      'khqrMd5': khqrMd5,
      'khqrTransactionHash': khqrTransactionHash,
      'khqrShortHash': khqrShortHash,
      'khqrDeeplink': khqrDeeplink,
      'khqrLastCheckedAt': khqrLastCheckedAt?.toIso8601String(),
      'khqrPaymentData': khqrPaymentData,
      'createdAt': createdAt.toIso8601String(),
      'purchases': purchases.map((p) => p.toJson()).toList(),
    };
  }
}

/// Purchase model - Matches Django Purchase (renamed from OrderItem for clarity)
class Purchase {
  final int purchaseId;
  final int invoiceId; // FK to Invoice
  final int? productId; // FK to Product (nullable)
  final int quantity;
  final double pricePerUnit;
  final double discount;
  final double subtotal;
  final DateTime createdAt;

  Purchase({
    required this.purchaseId,
    required this.invoiceId,
    this.productId,
    required this.quantity,
    required this.pricePerUnit,
    required this.discount,
    required this.subtotal,
    required this.createdAt,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      purchaseId: json['purchaseId'] ?? 0,
      invoiceId: json['invoice'] ?? 0,
      productId: json['product'],
      quantity: json['quantity'] ?? 0,
      pricePerUnit: (json['pricePerUnit'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purchaseId': purchaseId,
      'invoice': invoiceId,
      'product': productId,
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
      'discount': discount,
      'subtotal': subtotal,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// ============== ANALYTICS MODELS ==============

/// ProductAssociation model - Matches Django ProductAssociation
class ProductAssociation {
  final int associationId;
  final int product1Id; // FK to Product
  final int product2Id; // FK to Product
  final int frequency;
  final double associationPercentage;
  final int totalProduct1Purchases;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductAssociation({
    required this.associationId,
    required this.product1Id,
    required this.product2Id,
    required this.frequency,
    required this.associationPercentage,
    required this.totalProduct1Purchases,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductAssociation.fromJson(Map<String, dynamic> json) {
    return ProductAssociation(
      associationId: json['associationId'] ?? 0,
      product1Id: json['product1'] ?? 0,
      product2Id: json['product2'] ?? 0,
      frequency: json['frequency'] ?? 0,
      associationPercentage: (json['associationPercentage'] ?? 0).toDouble(),
      totalProduct1Purchases: json['totalProduct1Purchases'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'associationId': associationId,
      'product1': product1Id,
      'product2': product2Id,
      'frequency': frequency,
      'associationPercentage': associationPercentage,
      'totalProduct1Purchases': totalProduct1Purchases,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

// ============== TRANSACTION MODELS ==============

/// Transaction model - Matches Django Transaction
class Transaction {
  final int transactionId;
  final int invoiceId; // FK to Invoice
  final int? customerId; // FK to Customer (nullable)
  final double amountPaid;
  final String paymentMethod; // 'Cash', 'Card', 'KHQR', 'BankTransfer', 'Other'
  final String
  transactionStatus; // 'Pending', 'Completed', 'Failed', 'Refunded'
  final String? paymentReference;
  final DateTime transactionDate;
  final int? recordedByUserId; // FK to User (nullable)

  Transaction({
    required this.transactionId,
    required this.invoiceId,
    this.customerId,
    required this.amountPaid,
    required this.paymentMethod,
    required this.transactionStatus,
    this.paymentReference,
    required this.transactionDate,
    this.recordedByUserId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      transactionId: json['transactionId'] ?? 0,
      invoiceId: json['invoice'] ?? 0,
      customerId: json['customer'],
      amountPaid: (json['amountPaid'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? 'Cash',
      transactionStatus: json['transactionStatus'] ?? 'Pending',
      paymentReference: json['paymentReference'],
      transactionDate: DateTime.parse(
        json['transactionDate'] ?? DateTime.now().toString(),
      ),
      recordedByUserId: json['recordedByUser'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'invoice': invoiceId,
      'customer': customerId,
      'amountPaid': amountPaid,
      'paymentMethod': paymentMethod,
      'transactionStatus': transactionStatus,
      'paymentReference': paymentReference,
      'transactionDate': transactionDate.toIso8601String(),
      'recordedByUser': recordedByUserId,
    };
  }
}

// ============== AUDIT MODELS ==============

/// ActivityLog model - Matches Django ActivityLog
class ActivityLog {
  final int logId;
  final int? userId; // FK to User (nullable)
  final String actionType;
  final String description;
  final DateTime createdAt;

  ActivityLog({
    required this.logId,
    this.userId,
    required this.actionType,
    required this.description,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      logId: json['logId'] ?? 0,
      userId: json['user'],
      actionType: json['actionType'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logId': logId,
      'user': userId,
      'actionType': actionType,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
