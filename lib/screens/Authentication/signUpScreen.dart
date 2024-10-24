import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import for Firebase Storage
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventopos/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController =
      TextEditingController(); // Business Address Controller
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _gstNumberController = TextEditingController(); // GST Number Controller
  final _billRulesController = TextEditingController();
  File? _signatureImage; // To hold the signature image
  bool _isLoading = false;
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start managing your business with FastPOS',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _businessNameController,
                    decoration: InputDecoration(
                      labelText: 'Business Name',
                      prefixIcon: const Icon(Icons.business_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your business name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _businessAddressController,
                    decoration: InputDecoration(
                      labelText: 'Business Address',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your business address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _gstNumberController,
                    decoration: InputDecoration(
                      labelText: 'GST Number (Optional)',
                      prefixIcon: const Icon(Icons.business),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _billRulesController,
                    decoration: InputDecoration(
                      labelText:
                          'Bill Rules and Notes (will be auto \nprinted on bill)',
                      // hintText: 'Enter any rules or notes to appear on bills',
                      prefixIcon: const Icon(Icons.rule_folder_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3, // Allow multiple lines for longer rules
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter bill rules and notes';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickSignature,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _signatureImage == null
                          ? const Center(
                              child: Text(
                                  'Tap to add signature\n(which will be auto printed on bill)'),
                            )
                          : Image.file(
                              _signatureImage!,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Register',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickSignature() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _signatureImage = File(image.path);
      });
    }
  }

  Future<void> _handleRegister() async {
    Future<void> saveBusinessName(String businessName) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('businessName', businessName);
    }

    if (_formKey.currentState!.validate()) {
      if (_signatureImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload a signature image.'),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // First, create the user account
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Upload the signature image to Firebase Storage
        String signatureUrl = await _uploadSignatureImage();

        // Then, store additional user information in Firestore
        if (credential.user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(credential.user!.uid)
              .set({
            'name': _nameController.text,
            'businessName': _businessNameController.text,
            'businessAddress':
                _businessAddressController.text, // Save business address
            'phoneNumber': _phoneController.text,
            'email': _emailController.text.trim(),
            'gstNumber': _gstNumberController.text.trim(),
            'billRules': _billRulesController.text.trim(),
            'signatureUrl': signatureUrl,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Send email verification
          await credential.user!.sendEmailVerification();

          // Show success message and navigate to verification screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Verification email sent. Please check your inbox.'),
            ),
          );

          Navigator.pushReplacementNamed(
            context,
            '/verify-email',
            arguments: _emailController.text,
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'An error occurred';
        if (e.code == 'email-already-in-use') {
          errorMessage = 'This email is already registered';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _uploadSignatureImage() async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('signatures/${_nameController.text}_signature.jpg');
    final uploadTask = storageRef.putFile(_signatureImage!);
    final snapshot = await uploadTask.whenComplete(() => null);
    return await snapshot.ref.getDownloadURL();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _gstNumberController.dispose();
    _billRulesController.dispose(); // Dispose the new controller
    super.dispose();
  }
}












































// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:inventopos/main.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class RegisterScreen extends StatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   _RegisterScreenState createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _businessNameController = TextEditingController();
//   final _businessAddressController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _gstNumberController = TextEditingController();
//   final _billRulesController = TextEditingController(); // New controller for bill rules
//   File? _signatureImage;
//   bool _isLoading = false;
//   bool _obscureText = true;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Create Account',
//                     style: TextStyle(
//                       fontSize: 32,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Start managing your business with FastPOS',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   const SizedBox(height: 32),
//                   // ... (previous form fields remain the same until GST Number)

//                   TextFormField(
//                     controller: _billRulesController,
//                     decoration: InputDecoration(
//                       labelText: 'Bill Rules and Notes',
//                       hintText: 'Enter any rules or notes to appear on bills',
//                       prefixIcon: const Icon(Icons.rule_folder_outlined),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     maxLines: 3, // Allow multiple lines for longer rules
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter bill rules and notes';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 16),
                  
//                   // ... (rest of the form fields and UI remain the same)
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _handleRegister() async {
//     Future<void> saveBusinessName(String businessName) async {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.setString('businessName', businessName);
//     }

//     if (_formKey.currentState!.validate()) {
//       if (_signatureImage == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Please upload a signature image.'),
//           ),
//         );
//         return;
//       }

//       setState(() {
//         _isLoading = true;
//       });

//       try {
//         final credential =
//             await FirebaseAuth.instance.createUserWithEmailAndPassword(
//           email: _emailController.text.trim(),
//           password: _passwordController.text,
//         );

//         String signatureUrl = await _uploadSignatureImage();

//         if (credential.user != null) {
//           await FirebaseFirestore.instance
//               .collection('users')
//               .doc(credential.user!.uid)
//               .set({
//             'name': _nameController.text,
//             'businessName': _businessNameController.text,
//             'businessAddress': _businessAddressController.text,
//             'phoneNumber': _phoneController.text,
//             'email': _emailController.text.trim(),
//             'gstNumber': _gstNumberController.text.trim(),
//             'billRules': _billRulesController.text.trim(), // Store bill rules in database
//             'signatureUrl': signatureUrl,
//             'createdAt': FieldValue.serverTimestamp(),
//           });

//           await credential.user!.sendEmailVerification();

//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Verification email sent. Please check your inbox.'),
//             ),
//           );

//           Navigator.pushReplacementNamed(
//             context,
//             '/verify-email',
//             arguments: _emailController.text,
//           );
//         }
//       } on FirebaseAuthException catch (e) {
//         String errorMessage = 'An error occurred';
//         if (e.code == 'email-already-in-use') {
//           errorMessage = 'This email is already registered';
//         }
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(errorMessage)),
//         );
//       } finally {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _businessNameController.dispose();
//     _businessAddressController.dispose();
//     _phoneController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _gstNumberController.dispose();
//     _billRulesController.dispose(); // Dispose the new controller
//     super.dispose();
//   }

//   // ... (rest of the methods remain the same)
// }