import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewCompletedJob extends StatefulWidget {
  const ViewCompletedJob({super.key});

  @override
  State<ViewCompletedJob> createState() => _ViewCompletedJobState();
}

class _ViewCompletedJobState extends State<ViewCompletedJob> {
  final CollectionReference jobCollection =
      FirebaseFirestore.instance.collection("JobCollection");
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text("Completed Job"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Shop Name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: jobCollection
                  .where('isCompleted', isEqualTo: true)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final List<DocumentSnapshot> users = snapshot.data!.docs;

                // Filter the users based on the search query
                final filteredUsers = users.where((user) {
                  final data = user.data() as Map<String, dynamic>;
                  final shopName =
                      data['shopName']?.toString().toLowerCase() ?? '';
                  return shopName.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> user =
                        filteredUsers[index].data() as Map<String, dynamic>;
                    return Container(
                      width: double.infinity,
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
                              Container(
                                height: 30,
                                width: 30,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  border:
                                      Border.all(color: Colors.green, width: 2),
                                ),
                                child: Icon(Icons.done, color: Colors.green),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['shopName'] ?? 'NO Name',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text("Tailors Name:-${user['tailorName'] ?? 'NO Name'}",
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
                                        SizedBox(width: 30),
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
                                        SizedBox(width: 30),
                                        Text(
                                          'Rate:- ${user['rate'] ?? 'NO Name'}',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: 30),
                                    Text(
                                      'Total Amount:- ${(user['totalAmount'] ?? 0).toString()}',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      'Delivered Date:- ${user['date'] ?? 'NO Name'}',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      'Received Date:- ${user['reDate'] ?? 'NO Name'}',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      'Other:- ${user['other'] ?? 'NO Name'}',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
