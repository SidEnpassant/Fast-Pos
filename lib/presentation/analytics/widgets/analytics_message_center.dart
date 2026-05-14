import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnalyticsMessageCenter extends StatelessWidget {
  const AnalyticsMessageCenter({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.red,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
