import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';

/// Service for managing NFC operations
class NfcService {
  static final NfcService _instance = NfcService._internal();
  factory NfcService() => _instance;
  NfcService._internal();

  /// Check if NFC is available on the device
  Future<bool> isNfcAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Start NFC tag reading session
  /// [onDiscovered] callback is called when a tag is discovered
  Future<void> startReading({
    required Function(NfcTag tag) onDiscovered,
    Function(dynamic error)? onError,
  }) async {
    try {
      final isAvailable = await isNfcAvailable();
      if (!isAvailable) {
        throw Exception('NFC is not available on this device');
      }

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          onDiscovered(tag);
        },
        onError: (error) async {
          if (onError != null) {
            onError(error);
          }
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Stop NFC tag reading session
  Future<void> stopReading() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      // Session may already be stopped
    }
  }

  /// Read NDEF message from a tag
  /// Returns a map with tag information and records
  Map<String, dynamic>? readNdefMessage(NfcTag tag) {
    try {
      final ndef = Ndef.from(tag);
      if (ndef == null) {
        return null;
      }

      final cachedMessage = ndef.cachedMessage;
      if (cachedMessage == null) {
        return null;
      }

      final records = cachedMessage.records.map((record) {
        return {
          'typeNameFormat': record.typeNameFormat.index,
          'type': record.type,
          'identifier': record.identifier,
          'payload': record.payload,
          'payloadAsString': _tryDecodePayload(record.payload),
        };
      }).toList();

      return {
        'isWritable': ndef.isWritable,
        'maxSize': ndef.maxSize,
        'records': records,
      };
    } catch (e) {
      return null;
    }
  }

  /// Try to decode payload as UTF-8 string
  String? _tryDecodePayload(Uint8List payload) {
    try {
      // Skip language code byte for text records
      if (payload.isNotEmpty) {
        final languageCodeLength = payload[0] & 0x3F;
        if (payload.length > languageCodeLength + 1) {
          return String.fromCharCodes(
              payload.sublist(languageCodeLength + 1));
        }
      }
      return String.fromCharCodes(payload);
    } catch (e) {
      return null;
    }
  }

  /// Write NDEF message to a tag
  /// [text] is the text content to write
  Future<bool> writeNdefMessage({
    required NfcTag tag,
    required String text,
  }) async {
    try {
      final ndef = Ndef.from(tag);
      if (ndef == null) {
        throw Exception('Tag is not NDEF compatible');
      }

      if (!ndef.isWritable) {
        throw Exception('Tag is not writable');
      }

      // Create NDEF message with text record
      final record = NdefRecord.createText(text);
      final message = NdefMessage([record]);

      // Check if message fits on tag
      final messageSize = message.byteLength;
      if (messageSize > ndef.maxSize) {
        throw Exception(
            'Message too large ($messageSize bytes > ${ndef.maxSize} bytes)');
      }

      // Write to tag
      await ndef.write(message);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Write URI to NFC tag
  Future<bool> writeUri({
    required NfcTag tag,
    required String uri,
  }) async {
    try {
      final ndef = Ndef.from(tag);
      if (ndef == null) {
        throw Exception('Tag is not NDEF compatible');
      }

      if (!ndef.isWritable) {
        throw Exception('Tag is not writable');
      }

      // Create NDEF message with URI record
      final record = NdefRecord.createUri(Uri.parse(uri));
      final message = NdefMessage([record]);

      // Check if message fits on tag
      final messageSize = message.byteLength;
      if (messageSize > ndef.maxSize) {
        throw Exception(
            'Message too large ($messageSize bytes > ${ndef.maxSize} bytes)');
      }

      // Write to tag
      await ndef.write(message);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Get tag identifier
  String? getTagId(NfcTag tag) {
    try {
      // Try NFC-V (ISO/IEC 15693) first
      if (tag.data.containsKey('nfcv')) {
        final nfcvData = tag.data['nfcv'];
        if (nfcvData is Map && nfcvData.containsKey('identifier')) {
          final identifier = nfcvData['identifier'] as List<dynamic>;
          return identifier
              .map((e) => e.toRadixString(16).padLeft(2, '0'))
              .join(':')
              .toUpperCase();
        }
      }

      // Try NFC-A
      if (tag.data.containsKey('nfca')) {
        final nfcaData = tag.data['nfca'];
        if (nfcaData is Map && nfcaData.containsKey('identifier')) {
          final identifier = nfcaData['identifier'] as List<dynamic>;
          return identifier
              .map((e) => e.toRadixString(16).padLeft(2, '0'))
              .join(':')
              .toUpperCase();
        }
      }

      // Try NFC-B
      if (tag.data.containsKey('nfcb')) {
        final nfcbData = tag.data['nfcb'];
        if (nfcbData is Map && nfcbData.containsKey('identifier')) {
          final identifier = nfcbData['identifier'] as List<dynamic>;
          return identifier
              .map((e) => e.toRadixString(16).padLeft(2, '0'))
              .join(':')
              .toUpperCase();
        }
      }

      // Try NFC-F
      if (tag.data.containsKey('nfcf')) {
        final nfcfData = tag.data['nfcf'];
        if (nfcfData is Map && nfcfData.containsKey('identifier')) {
          final identifier = nfcfData['identifier'] as List<dynamic>;
          return identifier
              .map((e) => e.toRadixString(16).padLeft(2, '0'))
              .join(':')
              .toUpperCase();
        }
      }

      return 'No ID Available';
    } catch (e) {
      return null;
    }
  }

  /// Get tag type information
  String getTagType(NfcTag tag) {
    final types = <String>[];

    if (Ndef.from(tag) != null) types.add('NDEF');

    // Add more tag type detection based on tag.data keys
    if (tag.data.containsKey('nfca')) types.add('NFC-A (ISO 14443-3A)');
    if (tag.data.containsKey('nfcb')) types.add('NFC-B (ISO 14443-3B)');
    if (tag.data.containsKey('nfcf')) types.add('NFC-F (JIS 6319-4)');
    if (tag.data.containsKey('nfcv')) types.add('NFC-V (ISO 15693 / Type 5)');
    if (tag.data.containsKey('isodep')) types.add('IsoDep');
    if (tag.data.containsKey('mifareclassic')) types.add('MifareClassic');
    if (tag.data.containsKey('mifareultralight')) types.add('MifareUltralight');

    return types.isEmpty ? 'Unknown' : types.join(', ');
  }

  /// Get detailed tag information
  Map<String, dynamic> getTagDetails(NfcTag tag) {
    final details = <String, dynamic>{
      'id': getTagId(tag),
      'type': getTagType(tag),
      'technologies': <String>[],
      'isNdefFormatted': Ndef.from(tag) != null,
    };

    // List all available technologies
    details['technologies'] = tag.data.keys.toList();

    // Get NDEF details if available
    final ndef = Ndef.from(tag);
    if (ndef != null) {
      details['ndef'] = {
        'isWritable': ndef.isWritable,
        'maxSize': ndef.maxSize,
        'type': ndef.additionalData['type'] ?? 'Unknown',
      };
    }

    // Get NFC-V specific details if available
    if (tag.data.containsKey('nfcv')) {
      final nfcvData = tag.data['nfcv'] as Map;
      details['nfcv'] = {
        'dsfId': nfcvData['dsfId'],
        'responseFlags': nfcvData['responseFlags'],
      };
    }

    return details;
  }

}
