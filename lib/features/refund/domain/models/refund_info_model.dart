class RefundInfoModel {
  bool? alreadyRequested;
  bool? expired;
  Refund? refund;

  RefundInfoModel({this.alreadyRequested, this.expired, this.refund});

  RefundInfoModel.fromJson(Map<String, dynamic> json) {
    alreadyRequested = json['already_requested'];
    expired = json['expired'];
    refund =
    json['refund'] != null ? Refund.fromJson(json['refund']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['already_requested'] = alreadyRequested;
    data['expired'] = expired;
    if (refund != null) {
      data['refund'] = refund!.toJson();
    }
    return data;
  }
}

class Refund {
  double? productPrice;
  int? quntity;
  double? productTotalDiscount;
  double? productTotalTax;
  double? subtotal;
  double? couponDiscount;
  double? referralDiscount;
  double? refundAmount;

  Refund(
      {this.productPrice,
        this.quntity,
        this.productTotalDiscount,
        this.productTotalTax,
        this.subtotal,
        this.couponDiscount,
        this.refundAmount,
        this.referralDiscount,
      });

  Refund.fromJson(Map<String, dynamic> json) {
    productPrice = json['product_price'].toDouble();
    quntity = json['quntity'];
    productTotalDiscount = json['product_total_discount'].toDouble();
    productTotalTax = json['product_total_tax'].toDouble();
    subtotal = json['subtotal'].toDouble();
    couponDiscount = json['coupon_discount'].toDouble();
    refundAmount = json['refund_amount'].toDouble();
    referralDiscount = double.tryParse(json['referral_discount'].toString()) ?? 0.0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['product_price'] = productPrice;
    data['quntity'] = quntity;
    data['product_total_discount'] = productTotalDiscount;
    data['product_total_tax'] = productTotalTax;
    data['subtotal'] = subtotal;
    data['coupon_discount'] = couponDiscount;
    data['refund_amount'] = refundAmount;
    data['referral_discount'] = referralDiscount;
    return data;
  }
}
