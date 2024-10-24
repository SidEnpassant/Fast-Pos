import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/services.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shimmer/shimmer.dart';

class MyAccountPage extends StatefulWidget {
  @override
  _MyAccountPageState createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;

  Map<String, dynamic> _userData = {};
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
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
        _userData = userData.data() as Map<String, dynamic>? ?? {};
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserData(String field, String value) async {
    setState(() => _isLoading = true);
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update({field: value});
        setState(() {
          _userData[field] = value;
        });
        _showSuccessSnackbar('Updated successfully');
      }
    } catch (e) {
      _showErrorSnackbar('Update failed');
    }
    setState(() => _isLoading = false);
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
      ),
    );
  }

  Future<void> _updateSignature() async {
    final ImagePicker _picker = ImagePicker();
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isLoading = true);
        User? user = _auth.currentUser;
        if (user != null) {
          final ref = FirebaseStorage.instance.ref().child(
              'signatures/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await ref.putFile(File(image.path));
          String downloadURL = await ref.getDownloadURL();

          await _firestore
              .collection('users')
              .doc(user.uid)
              .update({'signatureUrl': downloadURL});
          setState(() {
            _userData['signatureUrl'] = downloadURL;
          });
          _showSuccessSnackbar('Profile picture updated successfully');
        }
      }
    } catch (e) {
      _showErrorSnackbar('Failed to update profile picture');
    }
    setState(() => _isLoading = false);
  }

  void _showEditDialog(String label, String field) {
    TextEditingController _controller =
        TextEditingController(text: _userData[field]);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white.withOpacity(0.95),
        title: Text(
          'Edit $label',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter $label',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.teal),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.teal, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('Save', style: TextStyle(fontSize: 16)),
            onPressed: () {
              _updateUserData(field, _controller.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, String field) {
    return AnimationConfiguration.synchronized(
      duration: Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 80,
            borderRadius: 20,
            blur: 20,
            alignment: Alignment.center,
            border: 2,
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.5),
                Colors.white.withOpacity(0.5),
              ],
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 20),
              title: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                _userData[field] ?? 'Not set',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.edit, color: Colors.teal),
                onPressed: () => _showEditDialog(label, field),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.teal, Colors.blue],
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 15,
                color: Colors.black.withOpacity(0.2),
                offset: Offset(0, 5),
              )
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: _userData['signatureUrl'] ??
                      'https://via.placeholder.com/150',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) =>
                      Icon(Icons.person, size: 50, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _updateSignature,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.teal,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 5,
                    color: Colors.black.withOpacity(0.2),
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('My Account',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 24)),
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          // IconButton(
          //   icon: Icon(Icons.settings,
          //       color: const Color.fromARGB(255, 255, 255, 255)),
          //   onPressed: () {
          //     // Add settings functionality
          //   },
          // ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: FadeTransition(
              opacity: _animation,
              child: RefreshIndicator(
                onRefresh: () async => _loadUserData(),
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _buildProfileImage(),
                        SizedBox(height: 20),
                        Text(
                          _userData['name'] ?? 'Your Name',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          _userData['email'] ?? 'your.email@example.com',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 30),
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
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
