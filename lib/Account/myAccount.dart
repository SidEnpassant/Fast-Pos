import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:ui';
import 'package:flutter/services.dart';

class MyAccountPage extends StatefulWidget {
  @override
  _MyAccountPageState createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _userData = {};
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userData =
          await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _userData = userData.data() as Map<String, dynamic>;
      });
    }
  }

  Future<void> _updateUserData(String field, String value) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({field: value});
      setState(() {
        _userData[field] = value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated successfully'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor:
              const Color.fromARGB(255, 100, 44, 255).withOpacity(0.8),
        ),
      );
    }
  }

  Future<void> _updateSignature() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      User? user = _auth.currentUser;
      if (user != null) {
        final ref =
            FirebaseStorage.instance.ref().child('signatures/${user.uid}.jpg');
        await ref.putFile(File(image.path));
        String downloadURL = await ref.getDownloadURL();

        await _firestore.collection('users').doc(user.uid).update({
          'signatureUrl': downloadURL,
        });

        setState(() {
          _userData['signatureUrl'] = downloadURL;
        });
      }
    }
  }

  Widget _buildGlassmorphicContainer(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(width: 1.5, color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, String field) {
    return _buildGlassmorphicContainer(
      ListTile(
        title: Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.white70),
        ),
        subtitle: Text(
          _userData[field] ?? 'Not set',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        trailing: IconButton(
          icon: Icon(Icons.edit, color: Colors.white70),
          onPressed: () {
            _showEditDialog(label, field);
          },
        ),
      ),
    );
  }

  void _showEditDialog(String label, String field) {
    TextEditingController _controller =
        TextEditingController(text: _userData[field]);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: _buildGlassmorphicContainer(
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Edit $label',
                      style: TextStyle(color: Colors.white, fontSize: 20)),
                  SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter $label',
                      hintStyle: TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: Text('Cancel',
                            style: TextStyle(color: Colors.white70)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        child: Text('Save'),
                        onPressed: () {
                          _updateUserData(field, _controller.text);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal.shade700, Colors.blue.shade900],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _animation,
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _updateSignature,
                      child: Hero(
                        tag: 'profileImage',
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(blurRadius: 20, color: Colors.black26)
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              _userData['signatureUrl'] ??
                                  'https://via.placeholder.com/150',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      _userData['name'] ?? 'Your Name',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _userData['email'] ?? 'your.email@example.com',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    SizedBox(height: 30),
                    ...[
                      _buildEditableField('Name', 'name'),
                      SizedBox(height: 15),
                      _buildEditableField('Phone Number', 'phoneNumber'),
                      SizedBox(height: 15),
                      _buildEditableField('Business Name', 'businessName'),
                      SizedBox(height: 15),
                      _buildEditableField(
                          'Business Address', 'businessAddress'),
                      SizedBox(height: 15),
                      _buildEditableField('GST Number', 'gstNumber'),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
