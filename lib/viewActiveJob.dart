import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewActivejob extends StatefulWidget {
  const ViewActivejob({super.key});

  @override
  State<ViewActivejob> createState() => _ViewActivejobState();
}

class _ViewActivejobState extends State<ViewActivejob> {

  final CollectionReference jobCollection = FirebaseFirestore.instance.collection("JobCollection");
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';


  Future<void> jobUpdated(String userId) async{
    try{
      await FirebaseFirestore.instance.collection("JobCollection").doc(userId).update({
      'isCompleted':true
      });

      CherryToast.success(
          toastPosition: Position.bottom,
          animationType: AnimationType.fromBottom,
          animationDuration:  Duration(milliseconds:  300),
          title:  Text("Completed successfully", style: TextStyle(color: Colors.black))
      ).show(context);

    }catch(e){

      print("error:$e");
      CherryToast.error(
        description:  Text("Failed", style: TextStyle(color: Colors.black)),
        animationType:  AnimationType.fromBottom,
        toastPosition: Position.bottom,
        animationDuration:  Duration(milliseconds:  300),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
      backgroundColor: Colors.amber,
      title: Text("Active job"),
    ),

      body: Column(
        children: [
          Padding(padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by shop name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onChanged: (value){
                setState(() {
                  _searchQuery = value.toString();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: jobCollection.where('isCompleted', isEqualTo: false).orderBy('date' , descending: true).snapshots(),
              builder: (context, snapshot){
                if(snapshot.hasError){
                  return Center(child: Text("Error: ${snapshot.error}"),);
                }
            
                if(snapshot.connectionState == ConnectionState.waiting){
                  return Center(child: CircularProgressIndicator(),);
                }
            
                final List<DocumentSnapshot> users = snapshot.data!.docs;
                final filteredUsers = users.where((user){
                  final data = user.data() as Map<String,dynamic>;
                  final shopName = data['shopName']?.toString().toLowerCase() ?? '';
                  return shopName.contains(_searchQuery);
                }).toList();
            
                return ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (BuildContext context, int index){
                      Map<String , dynamic> user = filteredUsers[index].data() as Map<String,dynamic>;
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(8),
            
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [BoxShadow(
                            color: Colors.green,
                            blurRadius: 1.0,
                          ),],
                        ),
                        child:  Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                           Row(
                             children: [
                               Icon(Icons.access_time,color: Colors.green,),
                               SizedBox(width: 20,),
                               Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                 Text(user['shopName'] ?? 'NO Name',style: TextStyle(fontSize: 18,fontWeight: FontWeight.w500),),
                                Row(children: [
                                  Text('Size : ${user['size'] ?? 'NO Name'}',style: TextStyle(fontSize: 16),),
                                  SizedBox(width: 30,),
                                  Text('Handle: ${user['Handle'] ?? 'NO Name'}',style: TextStyle(fontSize: 16),),
                                ],),
                                 Row(
                                   children: [
                                     Text( 'Pcs: ${user['pcs'] ?? 'NO Name'}',style: TextStyle(fontSize: 16),),
                                     SizedBox(width: 30,),
                                     Text('Rate: ${user['rate'] ?? 'NO Name'}',style: TextStyle(fontSize: 16),),
            
                                    ],
                                 ),
                                   SizedBox(width: 30,),
                                   Text('Date: ${user['date'] ?? 'NO Name'}',style: TextStyle(fontSize: 14),),
                               Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                 children: [
                                   Text('Total Amount: ${(user['totalAmount'] ?? 0).toString()}',style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
            
                                   InkWell(
                                     onTap: (){
            
                                         jobUpdated(users[index].id);
                                     },
                                     child: Container(
                                       margin: EdgeInsets.only(left: 60),
                                       alignment: Alignment.centerRight,
                                       padding: EdgeInsets.symmetric(vertical: 5,horizontal: 10),
                                       decoration: BoxDecoration(
                                         color: Colors.amber,
                                         borderRadius: BorderRadius.circular(8)
                                       ),
                                       child: Text("Completed",style: TextStyle(color: Colors.black),),
                                     ),
                                   )
                                 ],
                               )
            
                               ],)
            
                             ],
                           )
                        ],),
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
