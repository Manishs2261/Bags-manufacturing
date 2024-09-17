import 'dart:convert';

import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewActivejob extends StatefulWidget {
  const ViewActivejob({super.key});

  @override
  State<ViewActivejob> createState() => _ViewActivejobState();
}

class _ViewActivejobState extends State<ViewActivejob> {
  var whatsappKey;

  final CollectionReference jobCollection =
      FirebaseFirestore.instance.collection("JobCollection");
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  var now = DateTime.now();
  var formatter = DateFormat('yyyy-MM-dd');
  var formattedDate;
  var tailorMobileNumber;

  Future<void> _launchURL(number) async {
    final Uri _url = Uri.parse('https://wa.me/$number');

    if (!await launchUrl(_url)) {
      throw 'Could not launch $_url';
    }
  }

  Future<void> jobUpdated(String userId) async {
    var now = DateTime.now();
    var formatter = DateFormat('dd-MM-yyyy');
    String formattedDate = formatter.format(now);

    try {
      await FirebaseFirestore.instance
          .collection("JobCollection")
          .doc(userId)
          .update({
        'isCompleted': true,
        'reDate': formattedDate,
      });
    } catch (e) {
      print("error:$e");
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

  Future<void> sendWhatsAppMessage(BuildContext context, mobileNumber, shopName,
      size, pcs, rate, total, other, bagHandle, userId) async {
    var now = DateTime.now();
    var formatter = DateFormat('dd-MM-yyyy');
    String formattedDate = formatter.format(now);

    var url = Uri.parse(
        'https://graph.facebook.com/v20.0/395078663694887/messages'); // Replace with your API endpoint

    // Headers
    var headers = {
      'Authorization': 'Bearer $whatsappKey',
      // Replace with your token
      'Content-Type': 'application/json',
    };

    print("Other $other");

    // Body
    var body = jsonEncode({
      'messaging_product': 'whatsapp',
      'to': mobileNumber, // Replace with recipient's phone number
      'type': 'template',
      'template': {
        'name': 'received', // Replace with your WhatsApp template name
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
              {'type': 'text', 'text': size},
              // Placeholder {{3}} for Size
              {'type': 'text', 'text': bagHandle},
              // Placeholder {{4}} for Handle/Without Handle
              {'type': 'text', 'text': other},
              // Placeholder {{5}} for Other
              {'type': 'text', 'text': pcs},
              // Placeholder {{6}} for Pcs
              {'type': 'text', 'text': rate},
              // Placeholder {{7}} for Rate
              {'type': 'text', 'text': total}
              // Placeholder {{8}} for Total
            ]
          }
        ]
      }
    });

    try {
      var response = await http.post(url, headers: headers, body: body);

      print(response.statusCode);
      print(response.body);
      if (response.statusCode == 200) {
        jobUpdated(userId);
        CherryToast.success(
          toastPosition: Position.bottom,
          animationType: AnimationType.fromBottom,
          animationDuration: Duration(milliseconds: 300),
          title: Text("WhatsApp message sent successfully",
              style: TextStyle(color: Colors.black)),
        ).show(context);
      } else {
        CherryToast.error(
          description: Text("Failed to send WhatsApp message",
              style: TextStyle(color: Colors.black)),
          animationType: AnimationType.fromBottom,
          toastPosition: Position.bottom,
          animationDuration: Duration(milliseconds: 300),
        ).show(context);
      }
    } catch (e) {
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
  void dispose() {
    // TODO: implement dispose
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchMetaApiKey();
    formattedDate = formatter.format(now);
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text("Active job"),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by shop name',
                prefixIcon: Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toString();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: jobCollection
                  .where('isCompleted', isEqualTo: false)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final List<DocumentSnapshot> users = snapshot.data!.docs;
                final filteredUsers = users.where((user) {
                  final data = user.data() as Map<String, dynamic>;
                  final shopName =
                      data['shopName']?.toString().toLowerCase() ?? '';
                  return shopName.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (BuildContext context, int index) {
                      Map<String, dynamic> user =
                          filteredUsers[index].data() as Map<String, dynamic>;
                      return Container(
                        width: width,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green,
                              blurRadius: 1.0,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: Colors.green,
                                ),
                                SizedBox(
                                  width: 20,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user['shopName'] ?? 'NO Name',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        "Tailor Name:-${user['tailorName'] ?? 'NO Name'}",
                                        style: TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            'Size:- ${user['size'] ?? 'NO Name'}',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          SizedBox(
                                            width: 30,
                                          ),
                                          Text(
                                            'Handle:- ${user['Handle'] ?? 'NO Name'}',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            'Pcs:- ${user['pcs'] ?? 'NO Name'}',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          SizedBox(
                                            width: 30,
                                          ),
                                          Text(
                                            'Rate:- ${user['rate'] ?? 'NO Name'}',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        width: 30,
                                      ),
                                      Text(
                                        'Total Amount: ₹${(user['totalAmount'] ?? 0).toString()}',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        'Other:- ${user['other'] ?? ''}',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Delivered Date:- ${DateFormat('dd/MM/yyyy').format(DateFormat('yyyy-MM-dd').parse(formattedDate))}',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                          SizedBox(
                                            height: 30,
                                            child: ElevatedButton(
                                                onPressed: () {
                                                  Clipboard.setData(
                                                      ClipboardData(text: '''
Order details - Received
PickUp Date - ${DateFormat('dd/MM/yyyy').format(DateFormat('yyyy-MM-dd').parse(formattedDate))}
Shop Name - ${user['shopName']}
Size - ${user['size']}
Handle/Without Handle - ${user['Handle']}
Other - ${user['other']}
Pcs - ${user['pcs']}
Rate - ${user['rate']}
Total - ${user['totalAmount']}
'''));


                                                  jobUpdated(users[index].id);
                                                  _launchURL(
                                                      user['tailorNumber']);

                                                  // sendWhatsAppMessage(
                                                  //     context,
                                                  //     user['mobile'],
                                                  //     user['shopName'],
                                                  //     user['size'],
                                                  //     user['pcs'],
                                                  //     user['rate'],
                                                  //     user['totalAmount'],
                                                  //     user['other'],
                                                  //     user['Handle'],
                                                  //     users[index].id);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 10),
                                                    side: BorderSide(
                                                        color: Colors.amber),
                                                    backgroundColor:
                                                        Colors.amber),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Image.asset(
                                                      'assets/images/whatapps.png',
                                                      height: 20,
                                                      width: 20,
                                                    ),
                                                    SizedBox(
                                                      width: 5,
                                                    ),
                                                    Text(
                                                      'Completed',
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    )
                                                  ],
                                                )),
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      );
                    });
              },
            ),
          ),
        ],
      ),
    );
  }
}
