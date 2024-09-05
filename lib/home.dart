import 'dart:convert';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:bags/addNewShop.dart';
import 'package:bags/viewActiveJob.dart';
import 'package:bags/viewCompletedJob.dart';
import 'package:bags/viewExistingShop.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

enum bagHandle { H, B }

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bagHandle? bagHandleOrWithoutHandle = bagHandle.H;

  final gobleKey = GlobalKey<FormState>();
  var shopName;

  final pcsController = TextEditingController();
  final rateController = TextEditingController();
  final sizeController = TextEditingController();
  double finalAmount = 0.0;
  bool _isLoading = false;

  List<String> _list = [];

  Future<void> _fetchShopNames() async {
    try {
      var querySnapshot =
          await FirebaseFirestore.instance.collection('User').get();
      var shopNames =
          querySnapshot.docs.map((doc) => doc['shopName'] as String).toList();

      setState(() {
        _list = shopNames;
      });
    } catch (e) {

      print("Error fetching shop names: $e");
      CherryToast.error(
        description: Text("Failed to fetch shop names",
            style: TextStyle(color: Colors.black)),
        animationType: AnimationType.fromBottom,
        toastPosition: Position.bottom,
        animationDuration: Duration(milliseconds: 300),
      ).show(context);
    }
  }

  Future<void> addJob() async {
    var now = DateTime.now();
    var formatter = DateFormat('dd-MM-yyyy');
    String formattedDate = formatter.format(now);

    try {
      await FirebaseFirestore.instance.collection("JobCollection").add({
        'shopName': shopName,
        'pcs': pcsController.text,
        'rate': rateController.text,
        'size': sizeController.text,
        'totalAmount': finalAmount,
        'Handle': bagHandleOrWithoutHandle?.name,
        'isCompleted': false,
        'date': formattedDate,
      });

      pcsController.clear();
      rateController.clear();
      sizeController.clear();
      finalAmount = 0;
    } catch (e) {
      print("Error $e");
    }
  }

  void _calculateFinalAmount() {
    double pcs = double.tryParse(pcsController.text) ?? 0.0;
    double rate = double.tryParse(rateController.text) ?? 0.0;

    setState(() {
      finalAmount = pcs * rate;
    });
  }

  Future<void> sendWhatsAppMessage(BuildContext context) async {
    var url = Uri.parse('https://graph.facebook.com/v20.0/395078663694887/messages');
    var headers = {
      'Authorization': 'Bearer EAAQtQymSe5gBO0I9NQ6n4ueGqVViWsBzjFubF2jNs8tpsGMHdRffny7lTeHXoKC3kFTQTCSdZA2FWuTXN2sAQw1n6M9sIVmI7Pc3oIT1UmekCWBZC0IZB607gh2ZB6tkko21jhq06mVvdIO9QbNz7vhnaWO6LlrzjtFyTmtmxBYIzzc8gdaYnbTYiZCsUvVCSrJoATcVKJGfysWdF1ZCnvI395EYvGHCbIh3kzw5IYWSoZD',
      'Content-Type': 'application/json',
    };
    var body = jsonEncode({
      'messaging_product': 'whatsapp',
      'to': '917389523175',
      'type': 'template',
      'template': {
        'name': 'hello_world',
        'language': {'code': 'en_US'}
      }
    });

    try {
      var response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        addJob();
        _isLoading = false;
        CherryToast.success(
          toastPosition: Position.bottom,
          animationType: AnimationType.fromBottom,
          animationDuration: Duration(milliseconds: 300),
          title: Text("WhatsApp message sent successfully",
              style: TextStyle(color: Colors.black)),
        ).show(context);
      } else {
        _isLoading = false;
        CherryToast.error(
          description: Text("Failed to send WhatsApp message",
              style: TextStyle(color: Colors.black)),
          animationType: AnimationType.fromBottom,
          toastPosition: Position.bottom,
          animationDuration: Duration(milliseconds: 300),
        ).show(context);
      }
    } catch (e) {
      _isLoading = false;
      print("Error sending WhatsApp message: $e");
      CherryToast.error(
        description: Text("Failed to send WhatsApp message",
            style: TextStyle(color: Colors.black)),
        animationType: AnimationType.fromBottom,
        toastPosition: Position.bottom,
        animationDuration: Duration(milliseconds: 300),
      ).show(context);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchShopNames();
    pcsController.addListener(_calculateFinalAmount);
    rateController.addListener(_calculateFinalAmount);
  }

  @override
  void dispose() {
    // TODO: implement dispose

    pcsController.dispose();
    rateController.dispose();
    sizeController.dispose();

    super.dispose();
  }

  Widget build(BuildContext context) {
    _fetchShopNames();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Home"),
        backgroundColor: Colors.amber,
        actions: [
          // IconButton(onPressed: () {}, icon: Icon(Icons.menu))

          PopupMenuButton<String>(
              position: PopupMenuPosition.under,
              color: Colors.amber,
              icon: Icon(Icons.menu),
              onSelected: (String result) {
                switch (result) {
                  case "1":
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => AddNewShop()));
                    print("1");
                    break;

                  case "2":
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ViewExistingShop()));
                    print("2");
                    break;

                  case "3":
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ViewActivejob()));
                    print("3");
                    break;

                  case "4":
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ViewCompletedJob()));
                    print("4");
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: '1',
                      child: Row(
                        children: [
                          Icon(Icons.add_business),
                          SizedBox(
                            width: 5,
                          ),
                          Text('Add New Shop')
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                        value: '2',
                        child: Row(
                          children: [
                            Icon(Icons.store),
                            SizedBox(
                              width: 5,
                            ),
                            Text("View Existing Shop"),
                          ],
                        )),
                    const PopupMenuItem(
                        value: '3',
                        child: Row(
                          children: [
                            Icon(Icons.access_time),
                            SizedBox(
                              width: 5,
                            ),
                            Text("View Active Job"),
                          ],
                        )),
                    const PopupMenuItem(
                        value: '4',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle),
                            SizedBox(
                              width: 5,
                            ),
                            Text("View Completed Job"),
                          ],
                        ))
                  ])
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Form(
                  key: gobleKey,
                  child: Column(
                    children: [
                      CustomDropdown.search(
                        decoration: CustomDropdownDecoration(
                            closedFillColor: Colors.blueGrey.shade50),
                        hintText: 'Select Shop',
                        items: _list,
                        excludeSelected: false,
                        onChanged: (value) {
                          shopName = value;
                        },
                      ),
                      SizedBox(
                        height: 16,
                      ),
                      TextFormField(
                        autofocus: false,
                        keyboardType: TextInputType.text,
                        controller: sizeController,
                        onTapOutside: (e) => FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          labelText: "Size",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter a Size";
                          }
                          return null;
                        },
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: ListTile(
                              title: const Text('H'),
                              leading: Radio<bagHandle>(
                                value: bagHandle.H,
                                groupValue: bagHandleOrWithoutHandle,
                                onChanged: (bagHandle? value) {
                                  setState(() {
                                    bagHandleOrWithoutHandle = value;
                                  });
                                },
                              ),
                            ),
                          ),
                          Flexible(
                            child: ListTile(
                              title: const Text('WH'),
                              leading: Radio<bagHandle>(
                                value: bagHandle.B,
                                groupValue: bagHandleOrWithoutHandle,
                                onChanged: (bagHandle? value) {
                                  setState(() {
                                    bagHandleOrWithoutHandle = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      TextFormField(
                        autofocus: false,
                        keyboardType: TextInputType.number,
                        controller: pcsController,
                        onTapOutside: (e) => FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          labelText: "Pcs",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the number of pieces';
                          }
                          return null;
                        },
                      ),
                      SizedBox(
                        height: 16,
                      ),
                      TextFormField(
                        autofocus: false,
                        keyboardType: TextInputType.number,
                        controller: rateController,
                        onTapOutside: (e) => FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          labelText: "Rate",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the number of Rate';
                          }
                          return null;
                        },
                      ),
                    ],
                  )),
              SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Text(
                    "Final Amount :- ",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    " ₹$finalAmount/-",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.green),
                  )
                ],
              ),
              SizedBox(
                height: 40,
              ),
              ElevatedButton(
                  onPressed: () async {
                    if (gobleKey.currentState!.validate()) {
                      _isLoading = true;
                      _calculateFinalAmount();
                      await sendWhatsAppMessage(context);

                    }
                  },
                  style: ElevatedButton.styleFrom(
                      side: BorderSide(color: Colors.amber),
                      backgroundColor: Colors.amber),
                  child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 30,
                        height: 30,
                        child: CircularProgressIndicator(color: Colors.black,)),
                  ],
                )
                 : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/whatapps.png',
                        height: 32,
                        width: 32,
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Text(
                        "SEND",
                        style: TextStyle(color: Colors.black),
                      )
                    ],
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
