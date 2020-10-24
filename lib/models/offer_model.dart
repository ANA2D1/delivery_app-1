// var offers = {
//   "id":"",
//   "order_id":"",
//   "partner_id":"",
//   "customer_id":"",
//   "price":0.0,
//   "status":""

// };

import 'package:delivery_app/utils/enums.dart';

import 'order_model.dart';

class OfferModel {
  String id;
  String orderId;
  String partnerId;
  String customerId;
  double price;
  OfferStatus status;
  List<Chats> chats;

  OfferModel(
      {this.id,
      this.orderId,
      this.partnerId,
      this.customerId,
      this.price,
      this.status,
      this.chats});

  OfferModel.fromJson(String key, Map<dynamic, dynamic> json) {
    id = key;
    orderId = json['order_id'];
    partnerId = json['partner_id'];
    customerId = json['customer_id'];
    price = json['price'];
    status = OfferStatus.values[json['status']];
    if (json['chats'] != null) {
      chats = new List<Chats>();
      json['chats'].forEach((v) {
        chats.add(new Chats.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    // data['id'] = this.id;
    data['order_id'] = this.orderId;
    data['partner_id'] = this.partnerId;
    data['customer_id'] = this.customerId;
    data['price'] = this.price;
    data['status'] = this.status.index;
    if (this.chats != null) {
      data['chats'] = this.chats.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
