import 'package:khqr_sdk/khqr_sdk.dart';

class KhqrConfig {
  static String bakongAccountId() => 'oun_mengheang@aclb';

  static String acquiringBank() => 'ACLEDA Bank';

  static String merchantId() => 'TEMP001';

  static String merchantName() => 'InvenTrack Store';

  static String currency() => 'USD';

  static String merchantCity() => 'Phnom Penh';

  static String storeLabel() => 'InvenTrack Store';

  static String phoneNumber() => '';

  static String terminalLabel() => 'InvenTrack';

  static MerchantInfo merchantInfo({
    required double amountInUsd,
    required int expirationTimestamp,
  }) {
    return MerchantInfo(
      bakongAccountId: bakongAccountId(),
      acquiringBank: acquiringBank(),
      merchantId: merchantId(),
      merchantName: merchantName(),
      currency: KhqrCurrency.usd,
      amount: amountInUsd,
      expirationTimestamp: expirationTimestamp,
    );
  }
}
