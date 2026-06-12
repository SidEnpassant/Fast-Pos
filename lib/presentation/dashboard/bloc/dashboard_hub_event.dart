import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/entities/customer.dart';
import 'package:inventopos/domain/entities/expense.dart';
import 'package:inventopos/domain/entities/pos_notification.dart';
import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/domain/entities/user_profile.dart';

sealed class DashboardHubEvent extends Equatable {
  const DashboardHubEvent();

  @override
  List<Object?> get props => [];
}

class DashboardHubStarted extends DashboardHubEvent {
  const DashboardHubStarted(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class DashboardHubBillsReceived extends DashboardHubEvent {
  const DashboardHubBillsReceived(this.bills);

  final List<Bill> bills;

  @override
  List<Object?> get props => [bills];
}

class DashboardHubProfileReceived extends DashboardHubEvent {
  const DashboardHubProfileReceived(this.profiles);

  final List<UserProfile> profiles;

  @override
  List<Object?> get props => [profiles];
}

class DashboardHubProductsReceived extends DashboardHubEvent {
  const DashboardHubProductsReceived(this.products);

  final List<Product> products;

  @override
  List<Object?> get props => [products];
}

class DashboardHubExpensesReceived extends DashboardHubEvent {
  const DashboardHubExpensesReceived(this.expenses);

  final List<Expense> expenses;

  @override
  List<Object?> get props => [expenses];
}

class DashboardHubCustomersReceived extends DashboardHubEvent {
  const DashboardHubCustomersReceived(this.customers);

  final List<Customer> customers;

  @override
  List<Object?> get props => [customers];
}

class DashboardHubPendingSyncChanged extends DashboardHubEvent {
  const DashboardHubPendingSyncChanged(this.count);

  final int count;

  @override
  List<Object?> get props => [count];
}

class DashboardHubNotificationsReceived extends DashboardHubEvent {
  const DashboardHubNotificationsReceived(this.notifications);

  final List<PosNotification> notifications;

  @override
  List<Object?> get props => [notifications];
}

class DashboardHubConnectivityChanged extends DashboardHubEvent {
  const DashboardHubConnectivityChanged({required this.isOnline});

  final bool isOnline;

  @override
  List<Object?> get props => [isOnline];
}

class DashboardHubAiUnreadChanged extends DashboardHubEvent {
  const DashboardHubAiUnreadChanged(this.count);

  final int count;

  @override
  List<Object?> get props => [count];
}

class DashboardHubRecomputeRequested extends DashboardHubEvent {
  const DashboardHubRecomputeRequested();
}
