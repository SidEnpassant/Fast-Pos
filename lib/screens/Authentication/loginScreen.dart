// import 'package:inventopos/screens/forgotPassword.dart';
// import 'package:inventopos/screens/homeScreen.dart';
// import 'package:inventopos/service/auth.dart';
// import 'package:inventopos/screens/signUpScreen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:inventopos/screens/signUpScreen.dart';

// class LogInScreen extends StatefulWidget {
//   const LogInScreen({super.key});

//   @override
//   State<LogInScreen> createState() => _LogInScreenState();
// }

// class _LogInScreenState extends State<LogInScreen> {
//   String email = "", password = "";

//   TextEditingController mailcontroller = new TextEditingController();
//   TextEditingController passwordcontroller = new TextEditingController();

//   final _formkey = GlobalKey<FormState>();

//   userLogin() async {
//     try {
//       await FirebaseAuth.instance
//           .signInWithEmailAndPassword(email: email, password: password);
//       Navigator.push(
//           context, MaterialPageRoute(builder: (context) => HomePage()));
//     } on FirebaseAuthException catch (e) {
//       if (e.code == 'user-not-found') {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//             backgroundColor: Colors.orangeAccent,
//             content: Text(
//               "No User Found for that Email",
//               style: TextStyle(fontSize: 18.0),
//             )));
//       } else if (e.code == 'wrong-password') {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//             backgroundColor: Colors.orangeAccent,
//             content: Text(
//               "Wrong Password Provided by User",
//               style: TextStyle(fontSize: 18.0),
//             )));
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Container(
//         decoration: const BoxDecoration(
//             image: DecorationImage(
//           opacity: 0.5,
//           image: AssetImage('assets/images/background.jpg'),
//           fit: BoxFit.cover,
//         )),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//                 textAlign: TextAlign.left,
//                 style: TextStyle(
//                   fontFamily: 'DMSans',
//                   fontSize: 30.0,
//                   color: Color.fromARGB(255, 255, 234, 0),
//                   fontWeight: FontWeight.bold,
//                 ),
//                 'Hey user'),
//             const SizedBox(
//               height: 30.0,
//             ),
//             Padding(
//               padding: const EdgeInsets.only(left: 20.0, right: 20.0),
//               child: Form(
//                 key: _formkey,
//                 child: Column(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 2.0, horizontal: 30.0),
//                       decoration: BoxDecoration(
//                           color: const Color.fromARGB(255, 255, 255, 255),
//                           borderRadius: BorderRadius.circular(15)),
//                       child: TextFormField(
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please Enter E-mail';
//                           }
//                           return null;
//                         },
//                         controller: mailcontroller,
//                         decoration: const InputDecoration(
//                             border: InputBorder.none,
//                             hintText: "Email",
//                             hintStyle: TextStyle(
//                                 color: Color.fromARGB(255, 104, 102, 102),
//                                 fontSize: 18.0)),
//                       ),
//                     ),
//                     const SizedBox(
//                       height: 30.0,
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 2.0, horizontal: 30.0),
//                       decoration: BoxDecoration(
//                           color: const Color.fromARGB(255, 255, 255, 255),
//                           borderRadius: BorderRadius.circular(15)),
//                       child: TextFormField(
//                         controller: passwordcontroller,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please Enter Password';
//                           }
//                           return null;
//                         },
//                         decoration: const InputDecoration(
//                             border: InputBorder.none,
//                             hintText: "Password",
//                             hintStyle: TextStyle(
//                                 color: Color.fromARGB(255, 104, 102, 102),
//                                 fontSize: 18.0)),
//                         obscureText: true,
//                       ),
//                     ),
//                     const SizedBox(
//                       height: 30.0,
//                     ),
//                     GestureDetector(
//                       onTap: () {
//                         if (_formkey.currentState!.validate()) {
//                           setState(() {
//                             email = mailcontroller.text;
//                             password = passwordcontroller.text;
//                           });
//                         }
//                         userLogin();
//                       },
//                       child: Container(
//                           width: MediaQuery.of(context).size.width,
//                           padding: const EdgeInsets.symmetric(
//                               vertical: 13.0, horizontal: 30.0),
//                           decoration: BoxDecoration(
//                               color: const Color(0xFF273671),
//                               borderRadius: BorderRadius.circular(30)),
//                           child: const Center(
//                               child: Text(
//                             "Sign In",
//                             style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 22.0,
//                                 fontWeight: FontWeight.w500),
//                           ))),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(
//               height: 40.0,
//             ),
//             GestureDetector(
//               onTap: () {
//                 Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) => const ForgotPassword()));
//               },
//               child: const Text("Forgot Password?",
//                   style: TextStyle(
//                       color: Color.fromARGB(255, 255, 255, 255),
//                       fontSize: 18.0,
//                       fontWeight: FontWeight.w500)),
//             ),
//             SizedBox(
//               height: 20,
//             ),
//             // const Text(
//             //   "OR",
//             //   style: TextStyle(
//             //       color: Color.fromARGB(255, 255, 255, 255),
//             //       fontSize: 22.0,
//             //       fontWeight: FontWeight.w500),
//             // ),
//             const SizedBox(
//               height: 20.0,
//             ),
//             // Row(
//             //   mainAxisAlignment: MainAxisAlignment.center,
//             //   children: [
//             //     GestureDetector(
//             //       onTap: () {
//             //         AuthMethods().signInWithGoogle(context);
//             //       },
//             //       child: Image.asset(
//             //         "assets/images/google.png",
//             //         height: 45,
//             //         width: 45,
//             //         fit: BoxFit.cover,
//             //       ),
//             //     ),
//             //   ],
//             // ),
//             const SizedBox(
//               height: 40.0,
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Text("Don't have an account?",
//                     style: TextStyle(
//                         color: Color.fromARGB(255, 255, 255, 255),
//                         fontSize: 18.0,
//                         fontWeight: FontWeight.w500)),
//                 const SizedBox(
//                   width: 5.0,
//                 ),
//                 GestureDetector(
//                   onTap: () {
//                     Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => const SignUpScreen()));
//                   },
//                   child: const Text(
//                     "SignUp",
//                     style: TextStyle(
//                         color: Color.fromARGB(255, 120, 255, 129),
//                         fontSize: 20.0,
//                         fontWeight: FontWeight.w500),
//                   ),
//                 ),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventopos/screens/Authentication/signUpScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50),
                  Center(
                    child: Text(
                      'FastPOS',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Welcome back!',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
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
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgot-password');
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Login',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RegisterScreen()),
                          );
                        },
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final credential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (credential.user != null) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'An error occurred';
        if (e.code == 'user-not-found') {
          errorMessage = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Wrong password provided.';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
