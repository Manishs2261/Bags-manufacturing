
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

class AddNewShop extends StatefulWidget {
  const AddNewShop({super.key});

  @override
  State<AddNewShop> createState() => _AddNewShopState();
}

class _AddNewShopState extends State<AddNewShop> {

  final gobleKey = GlobalKey<FormState>();

  final shopName = TextEditingController();
  final mobileNumber = TextEditingController();



  //Function to add data to Firestore
  
  Future<void> addShop() async{
    
    try{
      await FirebaseFirestore.instance.collection("User").add({
        'shopName':shopName.text,
        'mobileNumber':'91${mobileNumber.text}',
      });

      CherryToast.success(
          toastPosition: Position.bottom,
          animationType: AnimationType.fromBottom,
          animationDuration:  Duration(milliseconds:  300),
          title:  Text("Added successfully", style: TextStyle(color: Colors.black))
      ).show(context);
      shopName.clear();
      mobileNumber.clear();
    }catch(e){

      CherryToast.error(
        description:  Text("Failed", style: TextStyle(color: Colors.black)),
        animationType:  AnimationType.fromBottom,
        toastPosition: Position.bottom,
        animationDuration:  Duration(milliseconds:  300),
      ).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Add New Shop"),backgroundColor: Colors.amber,),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

      Form(
        key: gobleKey,
          child: Column(
        children: [
          TextFormField(
            keyboardType: TextInputType.text,
            controller: shopName,
            onTapOutside: (e) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              labelText: "Shop Name",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter a shop Name";
              }
              return null;
            },
          ),

          SizedBox(height: 16,),

          TextFormField(
            keyboardType: TextInputType.number,
            controller: mobileNumber,
            maxLength: 10,
            onTapOutside: (e) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              counterText: "",
              labelText: "Mobile Number",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter a mobile number";
              }
              return null;
            },
          ),

        ],
      )),
            SizedBox(height: 40,),

            ElevatedButton(
                onPressed: (){
                  if (!gobleKey.currentState!.validate()) return;

                  if (mobileNumber.text.length != 10) {

                    CherryToast.info(
                      toastPosition: Position.bottom,
                      animationType: AnimationType.fromBottom,
                      animationDuration:  Duration(milliseconds:  300),
                      title:  Text("10-digit mobile number is required", style: TextStyle(color: Colors.black)),
                    ).show(context);
                    return;
                  }

                  addShop();


                },
                style: ElevatedButton.styleFrom(
                  side: BorderSide(color: Colors.amber),
                  backgroundColor: Colors.amber
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("ADD",style: TextStyle(color: Colors.black),),
                  ],
                ))


        ],),
      ),



      );
  }
}
