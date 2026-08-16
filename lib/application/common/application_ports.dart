abstract interface class ApplicationClock {
  DateTime nowUtc();
}

abstract interface class TransactionIdGenerator {
  String generate();
}
