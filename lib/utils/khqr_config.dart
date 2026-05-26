import 'package:khqr_sdk/khqr_sdk.dart';

class KhqrConfig {
  static String bakongAccountId() => 'oun_mengheang@aclb';

  static String acquiringBank() => 'ACLEDA Bank';

  static String merchantId() => 'TEMP001';

  static String merchantName() => 'Oun MengHeang';

  static String currency() => 'KHR';

  static String merchantCity() => 'Phnom Penh';

  static String storeLabel() => 'InvenTrack Store';

  static String phoneNumber() => '';

  static String terminalLabel() => 'InvenTrack';

  static KhqrCurrency khqrCurrency() => KhqrCurrency.usd;

  static MerchantInfo merchantInfo({
    required double amountInUsd,
    required int expirationTimestamp,
    String? merchantName,
  }) {
    return MerchantInfo(
      bakongAccountId: bakongAccountId(),
      acquiringBank: acquiringBank(),
      merchantId: merchantId(),
      merchantName: merchantName ?? KhqrConfig.merchantName(),
      currency: khqrCurrency(),
      amount: amountInUsd,
      expirationTimestamp: expirationTimestamp,
    );
  }
}
