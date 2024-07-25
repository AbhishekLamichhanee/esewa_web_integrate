import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

class PaymentFormScreen extends StatefulWidget {
  final String? feeAmount;
  const PaymentFormScreen({super.key, required this.feeAmount});

  @override
  _PaymentFormScreenState createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Allow unrestricted JavaScript
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (data) {},
          onUrlChange: (value) {
            final queryParameter = Uri.parse(value.url!).queryParameters;
          },
          onHttpError: (HttpResponseError error) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      );
    _loadHtmlContent();
  }

  Future<void> _loadHtmlContent() async {
    // ePay details
    String txAmt = "0";
    String scd = "EPAYTEST";
    String su = "https://esewa.com.np";
    String fu = "https://esewa.com.np";
    String secretKey = "8gBm/:&EnhH.1/q";
    String sfn = "total_amount,transaction_uuid,product_code";
    String amt = "${widget.feeAmount}";
    int amtValue = int.parse(amt);
    int taXAmtValue = int.parse(txAmt);
    int totalAmount = amtValue + taXAmtValue;
    String tAmt = totalAmount.toString();
    var uuid = const Uuid();
    String tuUid = uuid.v4();
    String dataToSign = 'total_amount=$tAmt,transaction_uuid=$tuUid,product_code=$scd';
    String sig = _generateSignature(dataToSign, secretKey);

    String htmlContent = esewaHtml(
      amount: amt,
      taxAmount: taXAmtValue.toString(),
      totalAmount: tAmt,
      transactionUuid: tuUid,
      productCode: scd,
      successUrl: su,
      failureUrl: fu,
      signedFieldNames: sfn,
      signature: sig,
    );

    _webViewController.loadRequest(Uri.dataFromString(
      htmlContent,
      encoding: Encoding.getByName('utf-8'),
      mimeType: 'text/html',
    ));
  }

  String _generateSignature(String data, String key) {
    var hmacSha256 = Hmac(sha256, utf8.encode(key));
    var digest = hmacSha256.convert(utf8.encode(data));
    return base64.encode(digest.bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Esewa Form'),
        centerTitle: true,
      ),
      body: WebViewWidget(
        controller: _webViewController,
      ),
    );
  }
}

String esewaHtml({
  required String amount,
  required String taxAmount,
  required String totalAmount,
  required String transactionUuid,
  required String productCode,
  required String successUrl,
  required String failureUrl,
  required String signedFieldNames,
  required String signature,
}) {
  return """
    <form id="esewaForm" action="https://rc-epay.esewa.com.np/api/epay/main/v2/form" method="POST">
        <input type="hidden" id="amount" name="amount" value="$amount" required>
        <input type="hidden" id="failure_url" name="failure_url" value="$failureUrl" required>
        <input type="hidden" id="product_delivery_charge" name="product_delivery_charge" value="0" required>
        <input type="hidden" id="product_service_charge" name="product_service_charge" value="0" required>
        <input type="hidden" id="product_code" name="product_code" value="$productCode" required>
        <input type="hidden" id="signed_field_names" name="signed_field_names" value="$signedFieldNames" required>
        <input type="hidden" id="success_url" name="success_url" value="$successUrl" required>
        <input type="hidden" id="tax_amount" name="tax_amount" value="$taxAmount" required>
        <input type="hidden" id="total_amount" name="total_amount" value="$totalAmount" required>
        <input type="hidden" id="transaction_uuid" name="transaction_uuid" value="$transactionUuid" required>
        <input type="hidden" id="signature" name="signature" value="$signature" required> 
    </form>
    <script>
        window.onload = function() {
            document.getElementById("esewaForm").submit();
        };
    </script>
    """;
}
