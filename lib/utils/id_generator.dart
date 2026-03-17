import 'dart:math';

class IdGenerator {
  // Epoch: 2026-01-01T00:00:00Z
  static const int _epoch = 1735689600000;

  // Bits allocation
  static const int _timestampBits = 41;
  static const int _workerIdBits = 5;
  static const int _datacenterIdBits = 5;
  static const int _sequenceBits = 12;

  // Max values
  static const int _maxWorkerId = -1 ^ (-1 << _workerIdBits);
  static const int _maxDatacenterId = -1 ^ (-1 << _datacenterIdBits);
  static const int _maxSequence = -1 ^ (-1 << _sequenceBits);

  // Shifts
  static const int _workerIdShift = _sequenceBits;
  static const int _datacenterIdShift = _sequenceBits + _workerIdBits;
  static const int _timestampLeftShift =
      _sequenceBits + _workerIdBits + _datacenterIdBits;

  static int _lastTimestamp = -1;
  static int _workerId = 1; // Default
  static int _datacenterId = 1; // Default
  static int _sequence = 0;

  /// Generates a Snowflake ID as a 64-bit integer.
  static int _nextId() {
    int timestamp = DateTime.now().millisecondsSinceEpoch - _epoch;

    if (timestamp < _lastTimestamp) {
      throw Exception('Clock moved backwards. Refusing to generate ID.');
    }

    if (_lastTimestamp == timestamp) {
      _sequence = (_sequence + 1) & _maxSequence;
      if (_sequence == 0) {
        // Sequence exhausted, wait for next millisecond
        while (timestamp <= _lastTimestamp) {
          timestamp = DateTime.now().millisecondsSinceEpoch - _epoch;
        }
      }
    } else {
      _sequence = 0;
    }

    _lastTimestamp = timestamp;

    return (timestamp << _timestampLeftShift) |
        (_datacenterId << _datacenterIdShift) |
        (_workerId << _workerIdShift) |
        _sequence;
  }

  /// Generates an order number in the format QLE-XXXXXXXX
  /// where XXXXXXXX is the base36 representation of a Snowflake ID.
  static String generateOrderNumber() {
    final id = _nextId();
    String base36 = id.toRadixString(36).toUpperCase();

    // Ensure it's padded to at least 8 characters for consistency
    if (base36.length < 8) {
      base36 = base36.padLeft(8, '0');
    }

    return 'QLE-$base36';
  }
}
