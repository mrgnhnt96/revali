import 'package:revali_swagger_annotations/revali_swagger_annotations.dart';

import 'package:swagger_sample_app/models/address.dart';
import 'package:swagger_sample_app/models/status.dart';

class ComplexModel {
  const ComplexModel({
    required this.id,
    required this.count,
    required this.score,
    required this.weight,
    required this.isActive,
    required this.createdAt,
    required this.sessionDuration,
    required this.processingTime,
    required this.address,
    required this.tags,
    required this.counters,
    required this.locations,
    required this.contacts,
    required this.namedCoord,
    required this.latLng,
    required this.status,
    this.nickname,
    this.updatedAt,
    this.profileUrl,
    this.billingAddress,
  });

  // --- Primitives ---
  final String id;
  final String? nickname;
  final int count;
  final double score;
  final num weight;
  final bool isActive;

  // --- Well-known SDK types (auto-mapped) ---
  final DateTime createdAt;
  final DateTime? updatedAt;

  // --- Uri (auto-mapped to string/uri) ---
  final Uri? profileUrl;

  // --- Duration: ambiguous serialization ---
  // No annotation → warning is emitted, fallback to {type: string}.
  final Duration sessionDuration;

  // @ApiType overrides the inferred schema.
  @ApiType('integer', format: 'int64')
  final Duration processingTime;

  // --- Nested objects → $ref ---
  final Address address;
  final Address? billingAddress;

  // --- Collections ---
  final List<String> tags;
  final List<Address> locations;
  final Map<String, int> counters;
  final Map<String, Address> contacts;

  // --- Records ---
  // Named record → inline object with named properties.
  final ({String name, int age}) namedCoord;

  // Positional record → inline object with field0/field1 keys.
  final (double, double) latLng;

  // --- Enum → $ref ---
  final Status status;
}
