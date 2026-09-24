import '../models/booking.dart';

class BookingService {
  static final List<Booking> bookings = [];

  Future<Booking> createBooking(Booking booking) async {
    bookings.add(booking);
    return booking;
  }
}