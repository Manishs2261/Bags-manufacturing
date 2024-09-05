import 'package:bags/home.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _containerSize = 50.0;  // Initial small size
  double _opacity = 0.0;  // Initial opacity

  @override
  void initState() {
    super.initState();

    // Trigger the animations after a short delay
    Future.delayed(Duration(milliseconds: 300), () {
      setState(() {
        _containerSize = 200.0;  // Final large size
        _opacity = 1.0;  // Fully visible
      });
    });


    // Navigate to home screen after the animation completes
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Home()),
      );
    });

  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: AnimatedOpacity(
              duration: Duration(seconds: 2),
              curve: Curves.easeInOut,
              opacity: _opacity,
              child: AnimatedContainer(
                duration: Duration(seconds: 2),
                curve: Curves.easeInOut,
                padding: EdgeInsets.all(5),
                height: _containerSize,
                width: _containerSize,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: 100,
                  backgroundColor: Colors.white,
                  child: Image.asset("assets/images/bag.png"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
