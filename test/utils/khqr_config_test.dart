import 'package:flutter_test/flutter_test.dart';
import 'package:inventrack/utils/khqr_config.dart';
import 'package:khqr_sdk/khqr_sdk.dart';

void main() {
  group('KhqrConfig', () {
    test('exposes consistent merchant branding values', () {
      expect(KhqrConfig.merchantName(), 'InvenTrack Store');
      expect(KhqrConfig.storeLabel(), 'InvenTrack Store');
      expect(KhqrConfig.currency(), 'USD');
    });

    test('builds merchant info from shared config functions', () {
      final info = KhqrConfig.merchantInfo(
        amountInUsd: 12.5,
        expirationTimestamp: 123456789,
      );

      expect(info, isA<MerchantInfo>());
      expect(info.bakongAccountId, KhqrConfig.bakongAccountId());
      expect(info.acquiringBank, KhqrConfig.acquiringBank());
      expect(info.merchantId, KhqrConfig.merchantId());
      expect(info.merchantName, KhqrConfig.merchantName());
      expect(info.currency, KhqrCurrency.usd);
      expect(info.amount, 12.5);
      expect(info.expirationTimestamp, 123456789);
    });
  });
}
