import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:khqr_sdk/khqr_sdk.dart';
import 'dart:async';

class KhqrPaymentCard extends StatefulWidget {
  final double width;
  final String receiverName;
  final dynamic amount;
  final bool keepIntegerDecimal;
  final KhqrCurrency currency;
  final String qr;
  final Widget? qrIcon;
  final Duration? duration;
  final VoidCallback? onRetry;
  final Widget? clearAmountIcon;
  final Widget? expiredIcon;
  final Widget Function(Duration)? onCountingDown;

  const KhqrPaymentCard({
    super.key,
    required this.width,
    required this.receiverName,
    required this.amount,
    required this.keepIntegerDecimal,
    required this.currency,
    required this.qr,
    this.qrIcon,
    this.duration,
    this.onRetry,
    this.clearAmountIcon,
    this.expiredIcon,
    this.onCountingDown,
  });

  @override
  State<KhqrPaymentCard> createState() => _KhqrPaymentCardState();
}

class _KhqrPaymentCardState extends State<KhqrPaymentCard> {
  late Timer _countdownTimer;
  late Duration _remainingTime;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    if (widget.duration != null) {
      _remainingTime = widget.duration!;
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        } else {
          _isExpired = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    if (widget.duration != null) {
      _countdownTimer.cancel();
    }
    super.dispose();
  }

  String _formatAmount() {
    if (widget.amount == null) return '0';

    final numAmount = widget.amount is String
        ? double.tryParse(widget.amount) ?? 0
        : widget.amount as double;

    if (widget.keepIntegerDecimal) {
      return numAmount.toStringAsFixed(2);
    }

    return numAmount.toStringAsFixed(0);
  }

  String _getCurrencySymbol() {
    switch (widget.currency) {
      case KhqrCurrency.khr:
        return '៛';
      case KhqrCurrency.usd:
        return '\$';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Red Header Banner
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFE63946),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'KHQR',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(width: 8),
                // QR Icon placeholder
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // White Card Body
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: _isExpired && widget.expiredIcon != null
                ? Center(child: widget.expiredIcon)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Receiver Name Label
                      Text(
                        'RECEIVER NAME',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Receiver Name
                      Text(
                        widget.receiverName.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Amount Section with Clear Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.currency == KhqrCurrency.khr
                                      ? 'RIELS'
                                      : 'DOLLARS',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_getCurrencySymbol()}${_formatAmount()}',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.clearAmountIcon != null)
                            SizedBox(
                              width: 30,
                              height: 30,
                              child: widget.clearAmountIcon,
                            ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Container(height: 1, color: Colors.grey[200]),

                      const SizedBox(height: 20),

                      // QR Code Container with Icon
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (widget.qr.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: QrImageView(
                                data: widget.qr,
                                version: QrVersions.auto,
                                size: widget.width - 80,
                                backgroundColor: Colors.white,
                                errorCorrectionLevel: QrErrorCorrectLevel.H,
                                constrainErrorBounds: false,
                              ),
                            )
                          else
                            Container(
                              width: widget.width - 80,
                              height: widget.width - 80,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[50],
                              ),
                              child: const Center(
                                child: Text(
                                  'QR Code',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          // QR Icon Overlay
                          if (widget.qrIcon != null)
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: widget.qrIcon,
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Countdown or Scan Instructions
                      if (widget.duration != null && !_isExpired)
                        widget.onCountingDown != null
                            ? widget.onCountingDown!(_remainingTime)
                            : Text(
                                'Expires in: ${_remainingTime.inSeconds}s',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                      else
                        Text(
                          'Scan to Pay',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                      // Retry Button
                      if (_isExpired && widget.onRetry != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: ElevatedButton.icon(
                            onPressed: widget.onRetry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE63946),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
