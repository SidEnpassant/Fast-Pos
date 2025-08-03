// // lib/screens/auth/email_verification_screen.dart
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:pinput/pinput.dart';

// class EmailVerificationScreen extends StatefulWidget {
//   final String email;

//   const EmailVerificationScreen({
//     super.key,
//     required this.email,
//   });

//   @override
//   State<EmailVerificationScreen> createState() =>
//       _EmailVerificationScreenState();
// }

// class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
//   bool isEmailVerified = false;
//   bool canResendEmail = false;
//   Timer? timer;
//   final otpController = TextEditingController();
//   bool isLoading = false;
//   int remainingTime = 60; // 60 seconds timeout
//   late Timer countdownTimer;

//   @override
//   void initState() {
//     super.initState();
//     // Send initial verification email
//     _sendVerificationEmail();
//     // Start countdown timer
//     _startCountdownTimer();
//   }

//   void _startCountdownTimer() {
//     countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         if (remainingTime > 0) {
//           remainingTime--;
//         } else {
//           canResendEmail = true;
//           timer.cancel();
//         }
//       });
//     });
//   }

//   Future<void> _sendVerificationEmail() async {
//     try {
//       setState(() {
//         isLoading = true;
//       });

//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         await user.sendEmailVerification();

//         setState(() {
//           canResendEmail = false;
//           remainingTime = 60;
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Verification email sent to ${widget.email}'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error sending verification email: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final defaultPinTheme = PinTheme(
//       width: 56,
//       height: 56,
//       textStyle: const TextStyle(
//         fontSize: 20,
//         color: Colors.black,
//         fontWeight: FontWeight.w600,
//       ),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade300),
//         borderRadius: BorderRadius.circular(8),
//       ),
//     );

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
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.mark_email_unread_outlined,
//                 size: 100,
//                 color: Theme.of(context).primaryColor,
//               ),
//               const SizedBox(height: 32),
//               const Text(
//                 'Verify your email',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 'We\'ve sent a verification email to',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey[600],
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 widget.email,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 32),
//               // Pinput(
//               //   length: 6,
//               //   controller: otpController,
//               //   defaultPinTheme: defaultPinTheme,
//               //   focusedPinTheme: defaultPinTheme.copyDecorationWith(
//               //     border: Border.all(color: Theme.of(context).primaryColor),
//               //   ),
//               //   submittedPinTheme: defaultPinTheme.copyDecorationWith(
//               //     border: Border.all(color: Colors.green),
//               //   ),
//               //   showCursor: true,
//               //   onCompleted: (pin) => _verifyOTP(pin),
//               // ),
//               const SizedBox(height: 32),
//               if (!canResendEmail) ...[
//                 Text(
//                   'Resend email in ${remainingTime}s',
//                   style: TextStyle(color: Colors.grey[600]),
//                 ),
//               ],
//               if (canResendEmail) ...[
//                 TextButton(
//                   onPressed: isLoading
//                       ? null
//                       : () {
//                           _sendVerificationEmail();
//                           _startCountdownTimer();
//                         },
//                   child: const Text('Resend Verification Email'),
//                 ),
//               ],
//               const SizedBox(height: 16),
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton(
//                   onPressed:
//                       isLoading ? null : () => _verifyOTP(otpController.text),
//                   style: ElevatedButton.styleFrom(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text(
//                           'Verify Email',
//                           style: TextStyle(fontSize: 16),
//                         ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _verifyOTP(String otp) async {
//     // if (otp.length != 6) {
//     //   ScaffoldMessenger.of(context).showSnackBar(
//     //     const SnackBar(
//     //       content: Text(
//     //           'Please verify you email through the link attached in email'),
//     //       backgroundColor: Colors.red,
//     //     ),
//     //   );
//     //   return;
//     // }

//     setState(() {
//       isLoading = true;
//     });

//     try {
//       // Here you would typically verify the OTP with your backend
//       // For this example, we'll simulate verification with Firebase Custom Claims
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         // Call your backend to verify OTP
//         // await verifyOTPWithBackend(otp);

//         // On successful verification
//         Navigator.of(context).pushReplacementNamed('/home');
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error verifying email: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     countdownTimer.cancel();
//     otpController.dispose();
//     super.dispose();
//   }
// }

// // lib/services/email_verification_service.dart
// class EmailVerificationService {
//   static final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Send verification email
//   static Future<void> sendVerificationEmail() async {
//     final user = _auth.currentUser;
//     if (user != null && !user.emailVerified) {
//       await user.sendEmailVerification();
//     }
//   }

//   // Check email verification status
//   static Future<bool> checkEmailVerified() async {
//     await _auth.currentUser?.reload();
//     return _auth.currentUser?.emailVerified ?? false;
//   }
// }

// import 'dart:async';
// import 'package:flutter/material.dart';

// class RegistrationSuccessScreen extends StatefulWidget {
//   final String email;

//   const RegistrationSuccessScreen({
//     super.key,
//     required this.email,
//   });

//   @override
//   State<RegistrationSuccessScreen> createState() =>
//       _RegistrationSuccessScreenState();
// }

// class _RegistrationSuccessScreenState extends State<RegistrationSuccessScreen>
//     with TickerProviderStateMixin {
//   late AnimationController _checkAnimationController;
//   late AnimationController _scaleAnimationController;
//   late AnimationController _slideAnimationController;
//   late AnimationController _fadeAnimationController;

//   late Animation<double> _checkAnimation;
//   late Animation<double> _scaleAnimation;
//   late Animation<Offset> _slideAnimation;
//   late Animation<double> _fadeAnimation;

//   bool _showSlider = false;
//   double _sliderValue = 0.0;
//   bool _isSliding = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimations();
//     _startAnimationSequence();
//   }

//   void _initializeAnimations() {
//     // Check mark animation
//     _checkAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     );
//     _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//           parent: _checkAnimationController, curve: Curves.easeInOut),
//     );

//     // Scale animation for the circle
//     _scaleAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//     _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//           parent: _scaleAnimationController, curve: Curves.elasticOut),
//     );

//     // Slide animation for text
//     _slideAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.3),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//         parent: _slideAnimationController, curve: Curves.easeOut));

//     // Fade animation for slider
//     _fadeAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 500),
//       vsync: this,
//     );
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeIn),
//     );
//   }

//   void _startAnimationSequence() async {
//     // Start scale animation
//     await _scaleAnimationController.forward();

//     // Start check animation
//     await _checkAnimationController.forward();

//     // Start slide animation for text
//     await _slideAnimationController.forward();

//     // Show slider after a delay
//     await Future.delayed(const Duration(milliseconds: 500));
//     setState(() {
//       _showSlider = true;
//     });
//     _fadeAnimationController.forward();
//   }

//   void _onSliderChanged(double value) {
//     setState(() {
//       _sliderValue = value;
//       _isSliding = value > 0.1;
//     });

//     if (value >= 0.9) {
//       _navigateToHome();
//     }
//   }

//   void _navigateToHome() {
//     Navigator.of(context).pushReplacementNamed('/home');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Color(0xFF667eea),
//               Color(0xFF764ba2),
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Spacer(),

//                 // Animated Success Icon
//                 AnimatedBuilder(
//                   animation: _scaleAnimation,
//                   builder: (context, child) {
//                     return Transform.scale(
//                       scale: _scaleAnimation.value,
//                       child: Container(
//                         width: 120,
//                         height: 120,
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           shape: BoxShape.circle,
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.1),
//                               blurRadius: 20,
//                               offset: const Offset(0, 10),
//                             ),
//                           ],
//                         ),
//                         child: CustomPaint(
//                           painter: CheckMarkPainter(_checkAnimation.value),
//                           size: const Size(120, 120),
//                         ),
//                       ),
//                     );
//                   },
//                 ),

//                 const SizedBox(height: 40),

//                 // Animated Text
//                 SlideTransition(
//                   position: _slideAnimation,
//                   child: FadeTransition(
//                     opacity: _slideAnimationController,
//                     child: Column(
//                       children: [
//                         const Text(
//                           'Welcome Aboard!',
//                           style: TextStyle(
//                             fontSize: 32,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           'Your account has been successfully created',
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.white.withOpacity(0.9),
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 8),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 8,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.2),
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Text(
//                             widget.email,
//                             style: const TextStyle(
//                               fontSize: 14,
//                               color: Colors.white,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),

//                 const Spacer(),

//                 // Animated Slider Button
//                 if (_showSlider)
//                   FadeTransition(
//                     opacity: _fadeAnimation,
//                     child: SlideTransition(
//                       position: Tween<Offset>(
//                         begin: const Offset(0, 0.5),
//                         end: Offset.zero,
//                       ).animate(CurvedAnimation(
//                         parent: _fadeAnimationController,
//                         curve: Curves.easeOut,
//                       )),
//                       child: _buildSliderButton(),
//                     ),
//                   ),

//                 const SizedBox(height: 40),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSliderButton() {
//     return Container(
//       width: double.infinity,
//       height: 60,
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.2),
//         borderRadius: BorderRadius.circular(30),
//         border: Border.all(
//           color: Colors.white.withOpacity(0.3),
//           width: 1,
//         ),
//       ),
//       child: Stack(
//         children: [
//           // Background progress
//           Container(
//             height: 60,
//             width: (_sliderValue * MediaQuery.of(context).size.width - 48),
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 colors: [Color(0xFF56ab2f), Color(0xFFa8e6cf)],
//               ),
//               borderRadius: BorderRadius.circular(30),
//             ),
//           ),

//           // Slider
//           Positioned(
//             left: _sliderValue * (MediaQuery.of(context).size.width - 108),
//             child: GestureDetector(
//               onPanUpdate: (details) {
//                 final RenderBox box = context.findRenderObject() as RenderBox;
//                 final double maxWidth = box.size.width - 60;
//                 final double newValue =
//                     (details.localPosition.dx - 30) / maxWidth;
//                 _onSliderChanged(newValue.clamp(0.0, 1.0));
//               },
//               onPanEnd: (details) {
//                 if (_sliderValue < 0.9) {
//                   setState(() {
//                     _sliderValue = 0.0;
//                     _isSliding = false;
//                   });
//                 }
//               },
//               child: AnimatedContainer(
//                 duration: Duration(milliseconds: _isSliding ? 0 : 300),
//                 width: 60,
//                 height: 60,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   shape: BoxShape.circle,
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.2),
//                       blurRadius: 10,
//                       offset: const Offset(0, 5),
//                     ),
//                   ],
//                 ),
//                 child: Icon(
//                   _sliderValue >= 0.9 ? Icons.check : Icons.arrow_forward_ios,
//                   color: _sliderValue >= 0.9
//                       ? const Color(0xFF56ab2f)
//                       : const Color(0xFF667eea),
//                 ),
//               ),
//             ),
//           ),

//           // Text
//           Center(
//             child: Text(
//               _sliderValue >= 0.9 ? 'Welcome!' : 'Slide to Continue',
//               style: TextStyle(
//                 color: _sliderValue > 0.5
//                     ? Colors.white
//                     : Colors.white.withOpacity(0.8),
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _checkAnimationController.dispose();
//     _scaleAnimationController.dispose();
//     _slideAnimationController.dispose();
//     _fadeAnimationController.dispose();
//     super.dispose();
//   }
// }

// // Custom Painter for Check Mark Animation
// class CheckMarkPainter extends CustomPainter {
//   final double animationValue;

//   CheckMarkPainter(this.animationValue);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = const Color(0xFF56ab2f)
//       ..strokeWidth = 4.0
//       ..strokeCap = StrokeCap.round
//       ..style = PaintingStyle.stroke;

//     final center = Offset(size.width / 2, size.height / 2);
//     final checkPath = Path()
//       ..moveTo(center.dx - 20, center.dy)
//       ..lineTo(center.dx - 5, center.dy + 15)
//       ..lineTo(center.dx + 20, center.dy - 10);

//     final pathMetrics = checkPath.computeMetrics().toList();
//     if (pathMetrics.isNotEmpty) {
//       final pathMetric = pathMetrics.first;
//       final extractedPath = pathMetric.extractPath(
//         0.0,
//         pathMetric.length * animationValue,
//       );
//       canvas.drawPath(extractedPath, paint);
//     }
//   }

//   @override
//   bool shouldRepaint(CheckMarkPainter oldDelegate) {
//     return oldDelegate.animationValue != animationValue;
//   }
// }

// import 'dart:async';
// import 'package:flutter/material.dart';

// class RegistrationSuccessScreen extends StatefulWidget {
//   final String email;

//   const RegistrationSuccessScreen({
//     super.key,
//     required this.email,
//   });

//   @override
//   State<RegistrationSuccessScreen> createState() =>
//       _RegistrationSuccessScreenState();
// }

// class _RegistrationSuccessScreenState extends State<RegistrationSuccessScreen>
//     with TickerProviderStateMixin {
//   late AnimationController _checkAnimationController;
//   late AnimationController _scaleAnimationController;
//   late AnimationController _slideAnimationController;
//   late AnimationController _fadeAnimationController;

//   late Animation<double> _checkAnimation;
//   late Animation<double> _scaleAnimation;
//   late Animation<Offset> _slideAnimation;
//   late Animation<double> _fadeAnimation;

//   bool _showSlider = false;
//   double _sliderValue = 0.0;
//   bool _isSliding = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimations();
//     _startAnimationSequence();
//   }

//   void _initializeAnimations() {
//     // Check mark animation
//     _checkAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     );
//     _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//           parent: _checkAnimationController, curve: Curves.easeInOut),
//     );

//     // Scale animation for the circle
//     _scaleAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//     _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//           parent: _scaleAnimationController, curve: Curves.elasticOut),
//     );

//     // Slide animation for text
//     _slideAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.3),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//         parent: _slideAnimationController, curve: Curves.easeOut));

//     // Fade animation for slider
//     _fadeAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 500),
//       vsync: this,
//     );
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeIn),
//     );
//   }

//   void _startAnimationSequence() async {
//     // Start scale animation
//     await _scaleAnimationController.forward();

//     // Start check animation
//     await _checkAnimationController.forward();

//     // Start slide animation for text
//     await _slideAnimationController.forward();

//     // Show slider after a delay
//     await Future.delayed(const Duration(milliseconds: 500));
//     setState(() {
//       _showSlider = true;
//     });
//     _fadeAnimationController.forward();
//   }

//   void _onSliderChanged(double value) {
//     setState(() {
//       _sliderValue = value;
//       _isSliding = value > 0.1;
//     });

//     if (value >= 0.9) {
//       _navigateToHome();
//     }
//   }

//   void _navigateToHome() {
//     Navigator.of(context).pushReplacementNamed('/home');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Color(0xFF667eea),
//               Color(0xFF764ba2),
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Spacer(),

//                 // Animated Success Icon
//                 AnimatedBuilder(
//                   animation: _scaleAnimation,
//                   builder: (context, child) {
//                     return Transform.scale(
//                       scale: _scaleAnimation.value,
//                       child: Container(
//                         width: 120,
//                         height: 120,
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           shape: BoxShape.circle,
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.1),
//                               blurRadius: 20,
//                               offset: const Offset(0, 10),
//                             ),
//                           ],
//                         ),
//                         child: CustomPaint(
//                           painter: CheckMarkPainter(_checkAnimation.value),
//                           size: const Size(120, 120),
//                         ),
//                       ),
//                     );
//                   },
//                 ),

//                 const SizedBox(height: 40),

//                 // Animated Text
//                 SlideTransition(
//                   position: _slideAnimation,
//                   child: FadeTransition(
//                     opacity: _slideAnimationController,
//                     child: Column(
//                       children: [
//                         const Text(
//                           'Welcome Aboard!',
//                           style: TextStyle(
//                             fontSize: 32,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           'Your account has been successfully created',
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.white.withOpacity(0.9),
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 8),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 8,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.2),
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Text(
//                             widget.email,
//                             style: const TextStyle(
//                               fontSize: 14,
//                               color: Colors.white,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),

//                 const Spacer(),

//                 // Animated Slider Button
//                 if (_showSlider)
//                   FadeTransition(
//                     opacity: _fadeAnimation,
//                     child: SlideTransition(
//                       position: Tween<Offset>(
//                         begin: const Offset(0, 0.5),
//                         end: Offset.zero,
//                       ).animate(CurvedAnimation(
//                         parent: _fadeAnimationController,
//                         curve: Curves.easeOut,
//                       )),
//                       child: _buildSliderButton(),
//                     ),
//                   ),

//                 const SizedBox(height: 40),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSliderButton() {
//     return Container(
//       width: double.infinity,
//       height: 60,
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.2),
//         borderRadius: BorderRadius.circular(30),
//         border: Border.all(
//           color: Colors.white.withOpacity(0.3),
//           width: 1,
//         ),
//       ),
//       child: Stack(
//         children: [
//           // Background progress
//           Container(
//             height: 60,
//             width: (_sliderValue * MediaQuery.of(context).size.width - 48),
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 colors: [Color(0xFF56ab2f), Color(0xFFa8e6cf)],
//               ),
//               borderRadius: BorderRadius.circular(30),
//             ),
//           ),

//           // Slider
//           Positioned(
//             left: _sliderValue * (MediaQuery.of(context).size.width - 108),
//             child: GestureDetector(
//               onPanUpdate: (details) {
//                 final RenderBox box = context.findRenderObject() as RenderBox;
//                 final double maxWidth = box.size.width - 60;
//                 final double newValue =
//                     (details.localPosition.dx - 30) / maxWidth;
//                 _onSliderChanged(newValue.clamp(0.0, 1.0));
//               },
//               onPanEnd: (details) {
//                 if (_sliderValue < 0.9) {
//                   setState(() {
//                     _sliderValue = 0.0;
//                     _isSliding = false;
//                   });
//                 }
//               },
//               child: AnimatedContainer(
//                 duration: Duration(milliseconds: _isSliding ? 0 : 300),
//                 width: 60,
//                 height: 60,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   shape: BoxShape.circle,
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.2),
//                       blurRadius: 10,
//                       offset: const Offset(0, 5),
//                     ),
//                   ],
//                 ),
//                 child: Icon(
//                   _sliderValue >= 0.9 ? Icons.check : Icons.arrow_forward_ios,
//                   color: _sliderValue >= 0.9
//                       ? const Color(0xFF56ab2f)
//                       : const Color(0xFF667eea),
//                 ),
//               ),
//             ),
//           ),

//           // Text
//           Center(
//             child: Text(
//               _sliderValue >= 0.9 ? 'Welcome!' : 'Slide to Continue',
//               style: TextStyle(
//                 color: _sliderValue > 0.5
//                     ? Colors.white
//                     : Colors.white.withOpacity(0.8),
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _checkAnimationController.dispose();
//     _scaleAnimationController.dispose();
//     _slideAnimationController.dispose();
//     _fadeAnimationController.dispose();
//     super.dispose();
//   }
// }

// // Custom Painter for Check Mark Animation
// class CheckMarkPainter extends CustomPainter {
//   final double animationValue;

//   CheckMarkPainter(this.animationValue);

//   @override
//   void paint(Canvas canvas, Size size) {
//     if (animationValue <= 0) return;

//     final paint = Paint()
//       ..color = const Color(0xFF56ab2f)
//       ..strokeWidth = 4.0
//       ..strokeCap = StrokeCap.round
//       ..style = PaintingStyle.stroke;

//     final center = Offset(size.width / 2, size.height / 2);
//     final checkPath = Path()
//       ..moveTo(center.dx - 20, center.dy)
//       ..lineTo(center.dx - 5, center.dy + 15)
//       ..lineTo(center.dx + 20, center.dy - 10);

//     try {
//       final pathMetrics = checkPath.computeMetrics().toList();
//       if (pathMetrics.isNotEmpty) {
//         final pathMetric = pathMetrics.first;
//         final length = pathMetric.length * animationValue;
//         if (length > 0) {
//           final extractedPath = pathMetric.extractPath(0.0, length);
//           canvas.drawPath(extractedPath, paint);
//         }
//       }
//     } catch (e) {
//       // Fallback: draw a simple check mark
//       canvas.drawLine(
//         Offset(center.dx - 20, center.dy),
//         Offset(center.dx - 5, center.dy + 15),
//         paint,
//       );
//       if (animationValue > 0.5) {
//         canvas.drawLine(
//           Offset(center.dx - 5, center.dy + 15),
//           Offset(center.dx + 20, center.dy - 10),
//           paint,
//         );
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(CheckMarkPainter oldDelegate) {
//     return oldDelegate.animationValue != animationValue;
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';

class RegistrationSuccessScreen extends StatefulWidget {
  final String email;

  const RegistrationSuccessScreen({
    super.key,
    required this.email,
  });

  @override
  State<RegistrationSuccessScreen> createState() =>
      _RegistrationSuccessScreenState();
}

class _RegistrationSuccessScreenState extends State<RegistrationSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  double _sliderPosition = 0.0;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
    ));

    _controller.forward();
  }

  void _onSliderUpdate(double value) {
    setState(() {
      _sliderPosition = value;
    });

    if (value >= 0.95 && !_isComplete) {
      _isComplete = true;
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 0, 83, 155),
              Color.fromARGB(255, 0, 113, 119),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),

                        // Success Icon
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 60,
                            color: Color(0xFF00C851),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Title
                        const Text(
                          '🎉 Welcome!',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Subtitle
                        const Text(
                          'Account created successfully',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Email badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            widget.email,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Slider Button
                        _buildSlideButton(),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSlideButton() {
    const double buttonHeight = 70.0;
    const double thumbSize = 60.0;

    return Container(
      height: buttonHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Progress background
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: buttonHeight,
            width: _sliderPosition * (MediaQuery.of(context).size.width - 64) +
                thumbSize,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C851), Color(0xFF007E33)],
              ),
              borderRadius: BorderRadius.circular(35),
            ),
          ),

          // Slide text
          if (_sliderPosition < 0.8)
            const Center(
              child: Text(
                'Slide to get started  →',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // Success text
          if (_sliderPosition >= 0.8)
            const Center(
              child: Text(
                'Let\'s Go! 🚀',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // Slider thumb
          Positioned(
            left: _sliderPosition *
                (MediaQuery.of(context).size.width - 64 - thumbSize),
            top: (buttonHeight - thumbSize) / 2,
            child: GestureDetector(
              onPanUpdate: (details) {
                final containerWidth = MediaQuery.of(context).size.width - 64;
                final maxSlide = containerWidth - thumbSize;
                final newPosition =
                    (details.localPosition.dx / maxSlide).clamp(0.0, 1.0);
                _onSliderUpdate(newPosition);
              },
              onPanEnd: (details) {
                if (_sliderPosition < 0.95) {
                  setState(() {
                    _sliderPosition = 0.0;
                  });
                }
              },
              child: AnimatedContainer(
                duration:
                    Duration(milliseconds: _sliderPosition > 0.1 ? 0 : 300),
                width: thumbSize,
                height: thumbSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  _sliderPosition >= 0.95
                      ? Icons.check_rounded
                      : Icons.arrow_forward_ios_rounded,
                  color: _sliderPosition >= 0.95
                      ? const Color(0xFF00C851)
                      : const Color(0xFF4facfe),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
