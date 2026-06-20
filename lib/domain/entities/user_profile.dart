import 'package:equatable/equatable.dart';

/// Profile row for the signed-in merchant.
class UserProfile extends Equatable {
  const UserProfile({
    this.name,
    this.email,
    this.businessName,
    this.businessAddress,
    this.phoneNumber,
    this.gstNumber,
    this.billRules,
    this.signatureUrl,
    this.lastBillNumber,
    this.createdAt,
    this.stateCode,
    this.isCompositionDealer = false,
    this.pdfBillSize = 'A4',
  });

  final String? name;
  final String? email;
  final String? businessName;
  final String? businessAddress;
  final String? phoneNumber;
  final String? gstNumber;
  final String? billRules;
  final String? signatureUrl;
  final int? lastBillNumber;
  final Object? createdAt;
  final String? stateCode;
  final bool isCompositionDealer;
  final String pdfBillSize;

  @override
  List<Object?> get props => [
        name,
        email,
        businessName,
        businessAddress,
        phoneNumber,
        gstNumber,
        billRules,
        signatureUrl,
        lastBillNumber,
        createdAt,
        stateCode,
        isCompositionDealer,
        pdfBillSize,
      ];
}
