import 'package:hive/hive.dart';
import '../constants/app_constants.dart';

/// Cached device identification from GATT probing.
///
/// Stored in Hive with remoteId as key. Expires after [ttl].
class CachedDeviceIdentification extends HiveObject {
  static const Duration ttl = CacheConstants.deviceCacheTtl;

  String remoteId;
  String? manufacturer;
  String? deviceType;
  List<String> serviceUuids;
  String? deviceName;
  int gattServiceCount;
  DateTime probedAt;

  CachedDeviceIdentification({
    required this.remoteId,
    this.manufacturer,
    this.deviceType,
    this.serviceUuids = const [],
    this.deviceName,
    this.gattServiceCount = 0,
    required this.probedAt,
  });

  bool get isExpired =>
      DateTime.now().difference(probedAt) > ttl;
}

/// Manual Hive adapter — avoids build_runner code generation.
class CachedDeviceIdentificationAdapter
    extends TypeAdapter<CachedDeviceIdentification> {
  @override
  final int typeId = 0;

  @override
  CachedDeviceIdentification read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return CachedDeviceIdentification(
      remoteId: fields[0] as String,
      manufacturer: fields[1] as String?,
      deviceType: fields[2] as String?,
      serviceUuids: (fields[3] as List?)?.cast<String>() ?? [],
      deviceName: fields[4] as String?,
      gattServiceCount: fields[5] as int? ?? 0,
      probedAt: DateTime.fromMillisecondsSinceEpoch(fields[6] as int),
    );
  }

  @override
  void write(BinaryWriter writer, CachedDeviceIdentification obj) {
    writer.writeByte(7); // number of fields
    writer.writeByte(0);
    writer.write(obj.remoteId);
    writer.writeByte(1);
    writer.write(obj.manufacturer);
    writer.writeByte(2);
    writer.write(obj.deviceType);
    writer.writeByte(3);
    writer.write(obj.serviceUuids);
    writer.writeByte(4);
    writer.write(obj.deviceName);
    writer.writeByte(5);
    writer.write(obj.gattServiceCount);
    writer.writeByte(6);
    writer.write(obj.probedAt.millisecondsSinceEpoch);
  }
}
