import 'package:khqr_sdk/khqr_sdk.dart';

class KhqrConfig {
  static const String bakongAccountId = 'oun_mengheang@aclb';
  static const String acquiringBank = 'ACLEDA Bank';
  static const String merchantId = 'TEMP001';
  static const String merchantName = 'Oun MengHeang';   
  static const String merchantCity = 'Phnom Penh';
  static const String storeLabel = 'InvenTrack Store';
  static const String terminalLabel = 'InvenTrack';
}

class KhqrCodeHelper {
  /// Generate a KHQR payment string for [amountInUsd] using the local SDK.
  static String? generateKhqrCode(double amountInUsd) {
    try {
      final expire =
          DateTime.now().millisecondsSinceEpoch + (10 * 3600000);

      final info = MerchantInfo(
        bakongAccountId: KhqrConfig.bakongAccountId,
        acquiringBank: KhqrConfig.acquiringBank,
        merchantId: KhqrConfig.merchantId,
        merchantName: KhqrConfig.merchantName,
        currency: KhqrCurrency.usd,
        amount: amountInUsd,
        expirationTimestamp: expire,
      );

      final res = KhqrSdk.generateMerchant(info);
      final qr = res.data?.qr;
      if (qr == null || qr.isEmpty) return null;
      return qr;
    } catch (e) {
      print('Error generating KHQR code: $e');
      return null;
    }
  }

  static bool isValidCode(String? code) =>
      code != null && code.trim().isNotEmpty;
}
