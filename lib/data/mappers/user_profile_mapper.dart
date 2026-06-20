import 'package:inventopos/domain/entities/user_profile.dart';
import 'package:inventopos/supabase_mappers.dart';

abstract final class UserProfileMapper {
  static UserProfile fromSupabaseRow(Map<String, dynamic> r) {
    final m = SupabaseMappers.profileFromRow(r);
    return UserProfile(
      name: m['name'] as String?,
      email: m['email'] as String?,
      businessName: m['businessName'] as String?,
      businessAddress: m['businessAddress'] as String?,
      phoneNumber: m['phoneNumber'] as String?,
      gstNumber: m['gstNumber'] as String?,
      billRules: m['billRules'] as String?,
      signatureUrl: m['signatureUrl'] as String?,
      lastBillNumber: (m['lastBillNumber'] as num?)?.toInt(),
      createdAt: m['createdAt'],
      stateCode: m['stateCode'] as String?,
      isCompositionDealer: m['isCompositionDealer'] as bool? ?? false,
      pdfBillSize: m['pdfBillSize'] as String? ?? 'A4',
    );
  }

  /// Keys match [SupabaseMappers.profileFromRow] for UI compatibility.
  static Map<String, dynamic> toFieldMap(UserProfile p) {
    return {
      'name': p.name,
      'email': p.email,
      'businessName': p.businessName,
      'businessAddress': p.businessAddress,
      'phoneNumber': p.phoneNumber,
      'gstNumber': p.gstNumber,
      'billRules': p.billRules,
      'signatureUrl': p.signatureUrl,
      'lastBillNumber': p.lastBillNumber,
      'createdAt': p.createdAt,
      'stateCode': p.stateCode,
      'isCompositionDealer': p.isCompositionDealer,
      'pdfBillSize': p.pdfBillSize,
    };
  }
}
