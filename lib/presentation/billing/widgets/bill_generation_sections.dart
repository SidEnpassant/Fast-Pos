import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventopos/domain/billing/bill_draft_line.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_bloc.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_event.dart';
import 'package:inventopos/presentation/billing/widgets/bill_form_components.dart';

class BillGenerationCustomerSection extends StatelessWidget {
  const BillGenerationCustomerSection({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.isListening,
    required this.onMicPressed,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final bool isListening;
  final VoidCallback onMicPressed;

  @override
  Widget build(BuildContext context) {
    return BillSectionCard(
      title: 'Customer Details',
      icon: Icons.person_outline,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.centerRight,
            children: [
              TextFormField(
                controller: nameController,
                decoration: billGenerationInputDecoration(
                  'Customer Name',
                  Icons.person,
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
              ),
              IconButton(
                icon: Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  color: isListening ? Colors.red : Colors.grey,
                ),
                onPressed: onMicPressed,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: phoneController,
            decoration: billGenerationInputDecoration(
              'Phone Number',
              Icons.phone,
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter phone number';
              }
              if (value!.length != 10) {
                return 'Please enter valid phone number';
              }
              return null;
            },
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }
}

class BillGenerationProductsSection extends StatelessWidget {
  const BillGenerationProductsSection({
    super.key,
    required this.lines,
    required this.totalAmount,
    required this.onAddProduct,
  });

  final List<BillDraftLine> lines;
  final double totalAmount;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    return BillSectionCard(
      title: 'Products',
      icon: Icons.shopping_cart_outlined,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              ElevatedButton.icon(
                onPressed: onAddProduct,
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (lines.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_basket_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No products added yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lines.length,
              itemBuilder: (context, index) {
                final product = lines[index];
                return Slidable(
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) {
                          context.read<BillDraftBloc>().add(
                                BillDraftLineRemoved(index),
                              );
                        },
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: Card(
                    elevation: 0,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[50],
                        child: Text(
                          product.name[0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                      title: Text(
                        product.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '₹${product.price.toStringAsFixed(2)} × ${product.quantity}',
                        style: GoogleFonts.poppins(),
                      ),
                      trailing: Text(
                        '₹${(product.price * product.quantity).toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn().slideX();
              },
            ),
          if (lines.isNotEmpty) ...[
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Total: ',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '₹${totalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideX(delay: const Duration(milliseconds: 200));
  }
}

class BillGenerationPaymentSection extends StatelessWidget {
  const BillGenerationPaymentSection({
    super.key,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paidAmount,
    required this.totalAmount,
    required this.onPaymentMethodChanged,
    required this.onPaymentStatusChanged,
    required this.onPaidAmountChanged,
  });

  final String paymentMethod;
  final String paymentStatus;
  final double paidAmount;
  final double totalAmount;
  final ValueChanged<String?> onPaymentMethodChanged;
  final ValueChanged<String?> onPaymentStatusChanged;
  final ValueChanged<double> onPaidAmountChanged;

  @override
  Widget build(BuildContext context) {
    return BillSectionCard(
      title: 'Payment Details',
      icon: Icons.payment_outlined,
      child: Column(
        children: [
          BillGenerationDropdownField(
            label: 'Payment Method',
            value: paymentMethod,
            items: const {
              'cash': 'Cash Payment',
              'upi': 'UPI Payment',
            },
            prefixIcon: Icons.payments,
            onChanged: onPaymentMethodChanged,
          ),
          const SizedBox(height: 16),
          BillGenerationDropdownField(
            label: 'Payment Status',
            value: paymentStatus,
            items: const {
              'complete': 'Fully Paid',
              'partial': 'Partially Paid',
            },
            prefixIcon: Icons.check_circle,
            onChanged: onPaymentStatusChanged,
          ),
          if (paymentStatus == 'partial') ...[
            const SizedBox(height: 16),
            TextFormField(
              initialValue: paidAmount.toString(),
              decoration: billGenerationInputDecoration(
                'Paid Amount',
                Icons.money,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter paid amount';
                }
                final amount = double.tryParse(value!);
                if (amount == null) {
                  return 'Please enter valid amount';
                }
                if (amount <= 0) {
                  return 'Amount must be greater than 0';
                }
                if (amount > totalAmount) {
                  return 'Amount cannot be greater than total';
                }
                return null;
              },
              onChanged: (value) {
                onPaidAmountChanged(double.tryParse(value) ?? 0);
              },
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideX(delay: const Duration(milliseconds: 400));
  }
}
