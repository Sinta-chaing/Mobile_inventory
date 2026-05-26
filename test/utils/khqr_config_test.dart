import 'package:flutter_test/flutter_test.dart';
import 'package:inventrack/utils/khqr_config.dart';
import 'package:khqr_sdk/khqr_sdk.dart';

void main() {
  group('KhqrConfig', () {
    test('exposes consistent merchant branding values', () {
      expect(KhqrConfig.merchantName(), 'Oun MengHeang');
      expect(KhqrConfig.storeLabel(), 'InvenTrack Store');
      expect(KhqrConfig.currency(), 'KHR');
    });

    test('builds default merchant info from shared config functions', () {
      final info = KhqrConfig.merchantInfo(
        amountInUsd: 12.5,
        expirationTimestamp: 123456789,
      );

      expect(info, isA<MerchantInfo>());
      expect(info.bakongAccountId, KhqrConfig.bakongAccountId());
      expect(info.acquiringBank, KhqrConfig.acquiringBank());
      expect(info.merchantId, KhqrConfig.merchantId());
      expect(info.merchantName, KhqrConfig.merchantName());
      expect(info.currency, KhqrConfig.khqrCurrency());
      expect(info.amount, 12.5);
      expect(info.expirationTimestamp, 123456789);
    });

    test('allows overriding merchant name for store-specific QR generation', () {
      final info = KhqrConfig.merchantInfo(
        amountInUsd: 12.5,
        expirationTimestamp: 123456789,
        merchantName: KhqrConfig.storeLabel(),
      );

      expect(info.merchantName, KhqrConfig.storeLabel());
    });
  });
}
