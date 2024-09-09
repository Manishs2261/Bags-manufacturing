import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewExistingTailor extends StatefulWidget {
  const ViewExistingTailor({super.key});

  @override
  State<ViewExistingTailor> createState() => _ViewExistingTailorState();
}

class _ViewExistingTailorState extends State<ViewExistingTailor> {
  final CollectionReference _usersCollection =
  FirebaseFirestore.instance.collection('Tailor');
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    // TODO: implement dispose
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text('Shops'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by tailor name',
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
              stream: _usersCollection.snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
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
                final filterUsers = users.where((user) {
                  final data = user.data() as Map<String, dynamic>;
                  final shopName =
                      data['tailorName']?.toString().toLowerCase() ?? '';
                  return shopName.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                    itemCount: filterUsers.length,
                    itemBuilder: (BuildContext context, int index) {
                      Map<String, dynamic> user =
                      filterUsers[index].data() as Map<String, dynamic>;
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey,
                              blurRadius: 1.0,
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(
                            user['tailorName'] ?? 'NO Name',
                            style: TextStyle(fontSize: 16),
                          ),
                          subtitle: Text(
                              '+91 ${user['mobileNumber'] ?? 'No Number'}'),
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
