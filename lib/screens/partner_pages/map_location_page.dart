import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_app/models/offer_model.dart';
import 'package:delivery_app/models/order_model.dart';
import 'package:delivery_app/repository/offer_repo.dart';
import 'package:delivery_app/repository/order_repo.dart';
import 'package:delivery_app/repository/user_repo.dart';
import 'package:delivery_app/utils/constants.dart';
import 'package:delivery_app/utils/enums.dart';
import 'package:delivery_app/widgets/chat_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:flutter_google_maps/flutter_google_maps.dart';
// import 'package:flutter_google_maps/flutter_google_maps.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapLocationPage extends StatefulWidget {
  final OrderModel orderModel;
  final double d1;
  final d2;
  MapLocationPage({this.orderModel, this.d1, this.d2});
  @override
  _MapLocationPageState createState() => _MapLocationPageState();
}

class _MapLocationPageState extends State<MapLocationPage> {
  GoogleMapController _controller;
  CameraPosition _initialLocation;
  Set<Marker> _markers;
  bool loading = true;
  bool showMap;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription _subscription;
  double _price;
  // OrderModel orderModel;
  OfferModel offer;
  TextEditingController _textEditingController;
  OfferRepo _offerRepo;
  OrderRepo _orderRepo;
  @override
  void initState() {
    _textEditingController = TextEditingController();
    checkIfexist(context);
    super.initState();
  }

  @override
  void dispose() {
    _textEditingController?.dispose();
    _subscription?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  _listenOffer(OfferModel offer) {
    _subscription = Firestore.instance
        .collection("Offers")
        .document(offer.id)
        .snapshots()
        .listen((event) {
      if (event.exists) {
        offer = OfferModel.fromJson(event.documentID, event.data);
        setState(() {});
      }
    });
  }

  checkIfexist(context) {
    // final user = RepositoryProvider.of<UserRepo>(context).user;
    Firestore.instance
        .collection("Offers")
        .where("order_id", isEqualTo: widget.orderModel.id)
        .where("partner_id", isEqualTo: Constants.partnerId)
        .getDocuments()
        .then((snap) {
      if (snap.documents.isNotEmpty) {
        showMap = false;

        offer = OfferModel.fromJson(
            snap.documents[0].documentID, snap.documents[0].data);
        _listenOffer(offer);
      } else {
        showMap = true;
        final order = widget.orderModel;

        _initialLocation = CameraPosition(
            bearing: 192.8334901395799,
            target: LatLng(order.pickupLocation.coordinates.latitude,
                order.pickupLocation.coordinates.longitude),
            // tilt: 59.440717697143555,
            zoom: 15.151926040649414);
        _markers = {
          Marker(
            markerId: MarkerId('Pick up'),
            position: LatLng(order.pickupLocation.coordinates.latitude,
                order.pickupLocation.coordinates.longitude),
            infoWindow: InfoWindow(title: 'Pick up'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueCyan,
            ),
          ),
          Marker(
            markerId: MarkerId('Drop'),
            position: LatLng(order.dropLocation.coordinates.latitude,
                order.dropLocation.coordinates.longitude),
            infoWindow: InfoWindow(title: 'Drop'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        };
      }
      setState(() {
        loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _offerRepo = RepositoryProvider.of<OfferRepo>(context);
    _orderRepo = RepositoryProvider.of<OrderRepo>(context);
    return new Scaffold(
      appBar: AppBar(),
      key: _scaffoldKey,
      body: loading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : widget.orderModel.status == OrderStatus.assigned &&
                  widget.orderModel.partnerId != Constants.partnerId
              ? Center(
                  child: Text("Order assigned to someone else!"),
                )
              : showMap
                  ? Column(
                      children: [
                        Expanded(child: _buildGoogleMap()),
                        Container(
                          padding: const EdgeInsets.all(10),
                          color: Colors.white,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Pick up ${widget.d1} km",
                                      style: TextStyle(color: Colors.cyan)),
                                  VerticalDivider(),
                                  Text("Drop up ${widget.d2} km",
                                      style: TextStyle(color: Colors.green)),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  onChanged: (str) {
                                    _price = double.parse(str);
                                  },
                                  decoration: InputDecoration(
                                      border: InputBorder.none,
                                      labelText: "Delivery cost",
                                      suffixIcon: IconButton(
                                          icon: Icon(Icons.arrow_forward),
                                          onPressed: () async {
                                            if (_price != null && _price > 0) {
                                              // final partner =
                                              //     RepositoryProvider.of<UserRepo>(context)
                                              //         .user;
                                              offer = OfferModel(
                                                  chats: [
                                                    Chats(
                                                        senderId: widget
                                                            .orderModel.userId,
                                                        type: ChatType.text,
                                                        value: widget.orderModel
                                                            .description),
                                                    Chats(
                                                        senderId:
                                                            Constants.partnerId,
                                                        type: ChatType.text,
                                                        value:
                                                            "Offers $_price delivery charges")
                                                  ],
                                                  customerId:
                                                      widget.orderModel.userId,
                                                  orderId: widget.orderModel.id,
                                                  partnerId:
                                                      Constants.partnerId,
                                                  price: _price,
                                                  status: OfferStatus.sent);
                                              await RepositoryProvider.of<
                                                      OfferRepo>(context)
                                                  .create(offer);
                                              setState(() {
                                                showMap = false;
                                              });
                                            }
                                            Fluttertoast.showToast(
                                                msg: "Please enter the amount");
                                          })),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    )
                  : _chatWidget(context, offer),
    );
  }

  Widget _buildGoogleMap() {
    return GoogleMap(
      zoomControlsEnabled: true,
      zoomGesturesEnabled: true,
      onMapCreated: _onCameracreated,
      myLocationEnabled: true,
      compassEnabled: true,
      markers: _markers,
      initialCameraPosition: _initialLocation,
      mapToolbarEnabled: true,
      myLocationButtonEnabled: true,
    );
  }

  void _onCameracreated(GoogleMapController controller) {
    _controller = controller;
  }

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
                    enabled: offer.status == OfferStatus.accepted,
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                        icon: Icon(Icons.arrow_forward),
                        onPressed: () {
                          offer.chats.add(Chats(
                              senderId: offer.partnerId,
                              type: ChatType.text,
                              value: _textEditingController.text));
                          _textEditingController.clear();
                          _offerRepo.update(offer);
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
