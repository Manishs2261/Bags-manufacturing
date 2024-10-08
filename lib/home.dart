import 'dart:convert';

import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:bags/addNewShop.dart';
import 'package:bags/table.dart';
import 'package:bags/viewActiveJob.dart';
import 'package:bags/viewCompletedJob.dart';
import 'package:bags/viewExistingShop.dart';
import 'package:bags/viewExistingTailor.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'addNewTailor.dart';

enum bagHandle { H, WH }

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bagHandle? bagHandleOrWithoutHandle = bagHandle.H;

  final gobleKey = GlobalKey<FormState>();
  var shopName;
  var userMobileNumber;
  var tailorName;
  var tailorMobileNumber;

  final pcsController = TextEditingController();
  final rateController = TextEditingController();
  final sizeController = TextEditingController();
  final otherController = TextEditingController();

  var whatsappKey;
  bool isShopName = false;
  bool isTailorName = false;

  double finalAmount = 0.0;
  bool _isLoading = false;
  bool isDate = false;

  List<Map<String, String>> _list = [];
  List<Map<String, String>> tailor_list = [];

  var now = DateTime.now();
  var formatter = DateFormat('yyyy-MM-dd');
  var formattedDate;
  DateTime? _selectedDate;

  // Function to show the date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(), // Initial date
      firstDate: DateTime(2000), // Starting date
      lastDate: DateTime(2100), // Ending date
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _launchURL() async {
    final Uri _url = Uri.parse('https://wa.me/$tailorMobileNumber');

    if (!await launchUrl(_url)) {
      throw 'Could not launch $_url';
    }
  }

  Future<void> _fetchMetaApiKey() async {
    try {
      // Fetch the collection 'metaKey' and get all documents
      var querySnapshot =
          await FirebaseFirestore.instance.collection("metaKey").get();

      // If you want to get the first document in the collection
      if (querySnapshot.docs.isNotEmpty) {
        // Assuming you want to get a specific field 'apiKey' from the first document
        var documentSnapshot = querySnapshot.docs.first;
        var apiKey = documentSnapshot
            .data()['meta']; // Replace 'apiKey' with your key name

        print(apiKey);
        setState(() {
          whatsappKey = apiKey;
        });
      } else {
        print('No documents found in the collection.');
      }
    } catch (e) {
      print("Meta API fetching error: $e");
    }
  }

  Future<void> _fetchTailorNames() async {
    try {
      var querySnapshot =
          await FirebaseFirestore.instance.collection('Tailor').get();
      var tailorName = querySnapshot.docs.map((doc) {
        return {
          'tailorName': doc['tailorName'] as String,
          'mobileNumber': doc['mobileNumber'] as String
        };
      }).toList();

      setState(() {
        tailor_list = tailorName;
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

  Future<void> _fetchShopNames() async {
    try {
      var querySnapshot =
          await FirebaseFirestore.instance.collection('User').get();
      var shopNames = querySnapshot.docs.map((doc) {
        return {
          'shopName': doc['shopName'] as String,
          'mobileNumber': doc['mobileNumber'] as String
        };
      }).toList();

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
    var formatter = DateFormat('yyyy-MM-dd');
    String formattedDate = formatter.format(now);

    try {
      await FirebaseFirestore.instance.collection("JobCollection").add({
        'shopName': shopName,
        'tailorName': tailorName,
        'mobile': userMobileNumber,
        'pcs': pcsController.text,
        'rate': rateController.text,
        'size': sizeController.text,
        'totalAmount': finalAmount,
        'Handle': bagHandleOrWithoutHandle?.name,
        'isCompleted': false,
        'other': otherController.text,
        'date': DateFormat('dd/MM/yyyy').format(DateFormat('yyyy-MM-dd').parse(_selectedDate.toString())),
        'tailorNumber': tailorMobileNumber
      });

      pcsController.clear();
      rateController.clear();
      sizeController.clear();
      otherController.clear();
      _selectedDate = null;



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

  Future<void> sendWhatsAppMessage(
    BuildContext context,
  ) async {
    var now = DateTime.now();
    var formatter = DateFormat('yyyy-MM-dd');
    String formattedDate = formatter.format(now);

    var url = Uri.parse(
        'https://graph.facebook.com/v20.0/395078663694887/messages'); // Replace with your API endpoint

    var headers = {
      'Authorization': 'Bearer $whatsappKey', // Replace with your token
      'Content-Type': 'application/json',
    };

    // Body
    var body = jsonEncode({
      'messaging_product': 'whatsapp',
      'to': userMobileNumber, // Replace with recipient's phone number
      'type': 'template',
      'template': {
        'name': 'deliver', // Replace with your WhatsApp template name
        'language': {
          'code': 'en' // English language code
        },
        'components': [
          {
            'type': 'body',
            'parameters': [
              {'type': 'text', 'text': formattedDate},
              // Placeholder {{1}} for PickUp Date
              {'type': 'text', 'text': shopName},
              // Placeholder {{2}} for Shop Name
              {'type': 'text', 'text': sizeController.text},
              // Placeholder {{3}} for Size
              {'type': 'text', 'text': bagHandleOrWithoutHandle?.name},
              // Placeholder {{4}} for Handle/Without Handle
              {'type': 'text', 'text': otherController.text.isNotEmpty},
              // Placeholder {{5}} for Other
              {'type': 'text', 'text': pcsController.text},
              // Placeholder {{6}} for Pcs
              {'type': 'text', 'text': rateController.text},
              // Placeholder {{7}} for Rate
              {'type': 'text', 'text': finalAmount}
              // Placeholder {{8}} for Total
            ]
          }
        ]
      }
    });

    print("step 4");

    try {
      var response = await http.post(url, headers: headers, body: body);
      print("step 5");

      print(response.statusCode);
      print(response.body);
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
        print("step 6");

        CherryToast.error(
          description: Text("Failed to send WhatsApp message",
              style: TextStyle(color: Colors.black)),
          animationType: AnimationType.fromBottom,
          toastPosition: Position.bottom,
          animationDuration: Duration(milliseconds: 300),
        ).show(context);
      }
    } catch (e) {
      print("step 7");

      _isLoading = false;

      print("Error Execution sending WhatsApp message: $e");
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
    formattedDate = formatter.format(now);

    _fetchMetaApiKey();
    _fetchShopNames();
    _fetchTailorNames();
    pcsController.addListener(_calculateFinalAmount);
    rateController.addListener(_calculateFinalAmount);
  }

  @override
  void dispose() {
    // TODO: implement dispose

    pcsController.dispose();
    rateController.dispose();
    sizeController.dispose();
    otherController.dispose();

    super.dispose();
  }

  Widget build(BuildContext context) {
    _fetchShopNames();
    _fetchTailorNames();

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

                  case "5":
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => ShopScreen()));
                    print("5");
                    break;

                  case "6":
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => AddNewTailor()));
                    break;

                  case "7":
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ViewExistingTailor()));
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
                      value: '6',
                      child: Row(
                        children: [
                          Icon(Icons.person_add),
                          SizedBox(
                            width: 6,
                          ),
                          Text('Add New Tailor')
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
                    const PopupMenuItem<String>(
                        value: '7',
                        child: Row(
                          children: [
                            Icon(Icons.person),
                            SizedBox(
                              width: 5,
                            ),
                            Text("View Existing Tailor"),
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
                        )),
                    const PopupMenuItem(
                        value: '5',
                        child: Row(
                          children: [
                            Icon(Icons.file_download),
                            SizedBox(
                              width: 5,
                            ),
                            Text("Export"),
                          ],
                        )),
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
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              side: BorderSide(
                                  color: isDate ? Colors.red : Colors.transparent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                // Border radius of 8
                              ),
                              padding: EdgeInsets.symmetric(vertical: 15),
                              backgroundColor: Colors.blueGrey.shade50),
                          onPressed: () => _selectDate(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [Text("${_selectedDate == null ? "Pickup Date" : DateFormat('dd/MM/yyyy').format(DateFormat('yyyy-MM-dd').parse(_selectedDate.toString()))}", style: TextStyle(color: Colors.black),)],
                          )),
                      SizedBox(
                        height: 16,
                      ),
                      CustomDropdown.search(
                        decoration: CustomDropdownDecoration(
                            closedBorder: isShopName
                                ? Border.all(color: Colors.red)
                                : null,
                            closedFillColor: Colors.blueGrey.shade50),
                        hintText: 'Select Tailor',
                        items: tailor_list.map((item) {
                          return item['tailorName'];
                        }).toList(),
                        excludeSelected: false,
                        onChanged: (value) {
                          var selectedValue = tailor_list.firstWhere(
                              ((shop) => shop['tailorName'] == value));

                          tailorName = selectedValue['tailorName'];
                          tailorMobileNumber = selectedValue['mobileNumber'];
                        },
                      ),
                      SizedBox(
                        height: 16,
                      ),
                      CustomDropdown.search(
                        decoration: CustomDropdownDecoration(
                            closedBorder: isTailorName
                                ? Border.all(color: Colors.red)
                                : null,
                            closedFillColor: Colors.blueGrey.shade50),
                        hintText: 'Select Shop',
                        items: _list.map((item) {
                          return item['shopName'];
                        }).toList(),
                        excludeSelected: false,
                        onChanged: (value) {
                          var selectedValue = _list.firstWhere(
                              ((shop) => shop['shopName'] == value));

                          shopName = selectedValue['shopName'];
                          userMobileNumber = selectedValue['mobileNumber'];
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
                                value: bagHandle.WH,
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
                        keyboardType: TextInputType.text,
                        controller: otherController,
                        maxLength: 150,
                        maxLines: null,
                        minLines: 1,
                        onTapOutside: (e) => FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          labelText: "Other",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                        ),
                      ),
                      SizedBox(
                        height: 16,
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

                    if(_selectedDate == null) isDate = true;
                    if (tailorName == null) isTailorName = true;
                    if (shopName == null) isShopName = true;

                    if (gobleKey.currentState!.validate() &&
                        tailorName != null &&
                        shopName != null &&
                         _selectedDate != null) {
                      isDate = false;
                      isTailorName = false;
                      isShopName = false;
                      _calculateFinalAmount();
//                       //  await sendWhatsAppMessage(context);
//
                      addJob();
                      Clipboard.setData(ClipboardData(text: '''
Order details - Pickup
PickUp Date - ${DateFormat('dd/MM/yyyy').format(DateFormat('yyyy-MM-dd').parse(_selectedDate.toString()))}
Shop Name - ${shopName}
Size - ${sizeController.text}
Handle/Without Handle - ${bagHandleOrWithoutHandle?.name}
Other - ${otherController.text}
Pcs - ${pcsController.text}
Rate - ${rateController.text}
Total - ${finalAmount}
'''));

                      _launchURL();
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
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                )),
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
