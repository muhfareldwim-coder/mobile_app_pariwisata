import '../models/payment.dart';

class PaymentService {
  static final List<Payment> payments = [];

  Future<Payment> createPayment(Payment payment) async {
    payments.add(payment);
    return payment;
  }
}
