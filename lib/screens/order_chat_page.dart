import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_app/models/offer_model.dart';
import 'package:delivery_app/models/order_model.dart';
import 'package:delivery_app/repository/offer_repo.dart';
import 'package:delivery_app/repository/order_repo.dart';
import 'package:delivery_app/repository/user_repo.dart';
import 'package:delivery_app/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderOfferPage extends StatefulWidget {
  final OrderModel orderModel;
  const OrderOfferPage({@required this.orderModel});
  @override
  _OrderChatPageState createState() => _OrderChatPageState();
}

class _OrderChatPageState extends State<OrderOfferPage> {
  StreamSubscription _subscription;
  List<OfferModel> offers;
  OfferRepo _offerRepo;
  bool showChat = false;
  TextEditingController _textEditingController;
  OrderRepo _orderRepo;
  @override
  void initState() {
    _textEditingController = TextEditingController();
    if (widget.orderModel.status == OrderStatus.assigned) {
      _subscription = _subscription = Firestore.instance
          .collection("Offers")
          .document(widget.orderModel.offerId)
          .snapshots()
          .listen((e) {
        if (e.exists) {
          offers = [OfferModel.fromJson(e.documentID, e.data)];

          setState(() {
            showChat = true;
          });
        }
      });
    } else {
      _subscription = Firestore.instance
          .collection("Offers")
          .where("order_id", isEqualTo: widget.orderModel.id)
          .snapshots()
          .listen((snap) {
        if (snap.documents.isNotEmpty) {
          offers = snap.documents
              .map((d) => OfferModel.fromJson(d.documentID, d.data))
              .toList();
          setState(() {});
        }
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    _textEditingController?.dispose();
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // var chatView = _chatView();
    _offerRepo = RepositoryProvider.of<OfferRepo>(context);
    _orderRepo = RepositoryProvider.of<OrderRepo>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.orderModel.type == OrderType.shopping
            ? "Order | #${widget.orderModel.id}"
            : "Package | #${widget.orderModel.id}"),
      ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // resizeToAvoidBottomInset: true,

      body: offers != null
          ? showChat
              ? _chatWidget(context, offers.first)
              : ListView.builder(
                  itemCount: offers.length,
                  itemBuilder: (context, i) => OfferListTile(
                        offerModel: offers[i],
                        onAccepted: () async {
                          // final offerRepo = RepositoryProvider.of<OfferRepo>(context);
                          offers[i].status = OfferStatus.accepted;
                          offers[i].chats.add(Chats(
                              senderId: offers[i].customerId,
                              type: ChatType.text,
                              value: "Accepted"));
                          await _offerRepo.update(offers[i]);
                          widget.orderModel.status = OrderStatus.assigned;
                          widget.orderModel.offerId = offers[i].id;
                          await _orderRepo.update(widget.orderModel);
                          setState(() {
                            showChat = true;
                            // offers = [offerModel];
                          });
                        },
                      ))
          : Center(
              child: Text("Waiting for offers"),
            ),
    );
  }

  // _onRejected(OfferModel offerModel) async {
  //   // final offerRepo = RepositoryProvider.of<OfferRepo>(context);
  //   offerModel.status = OfferStatus.rejected;
  //   offerModel.chats.add(Chats(
  //       senderId: offerModel.customerId,
  //       type: ChatType.text,
  //       value: "Rejected"));
  //   await _offerRepo.update(offerModel);

  //   setState(() {
  //     showChat = true;
  //     // offers = [offerModel];
  //   });
  // }

  _chatWidget(BuildContext context, OfferModel offer) {
    // final user = RepositoryProvider.of<UserRepo>(context).user;
    Size size = MediaQuery.of(context).size;
    int l = offer.chats.length;
    return Stack(
      children: [
        Container(),
        Expanded(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: size.height - 60),
            child: ListView.builder(
                shrinkWrap: true,
                reverse: true,
                itemCount: l,
                itemBuilder: (context, i) => _chatCard(offer.chats[l - 1 - i])),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _textEditingController,
                decoration: InputDecoration(
                    enabled: offers.first.status == OfferStatus.accepted,
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                        icon: Icon(Icons.arrow_forward),
                        onPressed: () {
                          offers.first.chats.add(Chats(
                              senderId: offers.first.customerId,
                              type: ChatType.text,
                              value: _textEditingController.text));
                          _textEditingController.clear();
                          // _offerRepo.update(offer);
                          setState(() {});
                        })),
              ),
            ),
          ),
        )
      ],
    );
  }

  _chatCard(Chats chat) => Card(child: Text(chat.value));
}

class OfferListTile extends StatelessWidget {
  final OfferModel offerModel;
  final VoidCallback onAccepted;
  // final VoidCallback onRejected;
  const OfferListTile({
    this.offerModel,
    this.onAccepted,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.person),
                ),
                title: Text("Delivery cost : \$ ${offerModel.price}"),
              ),
              Divider(),
              RaisedButton(
                onPressed: onAccepted,
                child: Text("Accept"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
