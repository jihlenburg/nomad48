import 'dart:convert';
import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:ndef_record/ndef_record.dart';

/// Service for managing NFC operations.
/// Migrated to nfc_manager 4.x + nfc_manager_ndef 1.x.
class NfcService {
  static final NfcService _instance = NfcService._internal();
  factory NfcService() => _instance;
  NfcService._internal();

  /// Check if NFC is available on the device
  Future<bool> isNfcAvailable() async {
    try {
      final availability = await NfcManager.instance.checkAvailability();
      return availability == NfcAvailability.enabled;
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
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (NfcTag tag) async {
          onDiscovered(tag);
        },
        onSessionErrorIos: (error) {
          if (onError != null) onError(error);
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
      if (ndef == null) return null;

      final cachedMessage = ndef.cachedMessage;
      if (cachedMessage == null) return null;

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

  /// Create an NDEF text record (replaces NdefRecord.createText removed in 4.x)
  NdefRecord _createTextRecord(String text) {
    const languageCode = 'en';
    final encodedText = utf8.encode(text);
    final encodedLang = ascii.encode(languageCode);
    final payload = Uint8List(1 + encodedLang.length + encodedText.length);
    payload[0] = encodedLang.length; // status byte: UTF-8 + language length
    payload.setRange(1, 1 + encodedLang.length, encodedLang);
    payload.setRange(1 + encodedLang.length, payload.length, encodedText);
    return NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList([0x54]), // 'T' for Text
      identifier: Uint8List(0),
      payload: payload,
    );
  }

  /// Create an NDEF URI record (replaces NdefRecord.createUri removed in 4.x)
  NdefRecord _createUriRecord(String uri) {
    int prefixCode = 0x00;
    String body = uri;
    // NFC Forum URI prefix codes
    if (uri.startsWith('https://www.')) {
      prefixCode = 0x02;
      body = uri.substring(12);
    } else if (uri.startsWith('http://www.')) {
      prefixCode = 0x01;
      body = uri.substring(11);
    } else if (uri.startsWith('https://')) {
      prefixCode = 0x04;
      body = uri.substring(8);
    } else if (uri.startsWith('http://')) {
      prefixCode = 0x03;
      body = uri.substring(7);
    }
    final encodedBody = utf8.encode(body);
    final payload = Uint8List(1 + encodedBody.length);
    payload[0] = prefixCode;
    payload.setRange(1, payload.length, encodedBody);
    return NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList([0x55]), // 'U' for URI
      identifier: Uint8List(0),
      payload: payload,
    );
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

      final record = _createTextRecord(text);
      final message = NdefMessage(records: [record]);

      final messageSize = message.byteLength;
      if (messageSize > ndef.maxSize) {
        throw Exception(
            'Message too large ($messageSize bytes > ${ndef.maxSize} bytes)');
      }

      await ndef.write(message: message);
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

      final record = _createUriRecord(uri);
      final message = NdefMessage(records: [record]);

      final messageSize = message.byteLength;
      if (messageSize > ndef.maxSize) {
        throw Exception(
            'Message too large ($messageSize bytes > ${ndef.maxSize} bytes)');
      }

      await ndef.write(message: message);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Extract tag data as a Map (internal helper).
  /// In nfc_manager 4.x, tag.data type changed but the underlying
  /// structure is still a `Map` at runtime.
  Map<String, dynamic>? _tagDataMap(NfcTag tag) {
    try {
      // ignore: invalid_use_of_protected_member
      return tag.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Get tag identifier
  String? getTagId(NfcTag tag) {
    try {
      final data = _tagDataMap(tag);
      if (data == null) return 'No ID Available';

      // Try NFC technologies in order
      for (final key in ['nfcv', 'nfca', 'nfcb', 'nfcf']) {
        if (data.containsKey(key)) {
          final techData = data[key];
          if (techData is Map && techData.containsKey('identifier')) {
            final identifier = techData['identifier'] as List<dynamic>;
            return identifier
                .map((e) => e.toRadixString(16).padLeft(2, '0'))
                .join(':')
                .toUpperCase();
          }
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

    final data = _tagDataMap(tag);
    if (data != null) {
      if (data.containsKey('nfca')) types.add('NFC-A (ISO 14443-3A)');
      if (data.containsKey('nfcb')) types.add('NFC-B (ISO 14443-3B)');
      if (data.containsKey('nfcf')) types.add('NFC-F (JIS 6319-4)');
      if (data.containsKey('nfcv')) types.add('NFC-V (ISO 15693 / Type 5)');
      if (data.containsKey('isodep')) types.add('IsoDep');
      if (data.containsKey('mifareclassic')) types.add('MifareClassic');
      if (data.containsKey('mifareultralight')) types.add('MifareUltralight');
    }

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

    final data = _tagDataMap(tag);
    if (data != null) {
      details['technologies'] = data.keys.toList();
    }

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
    if (data != null && data.containsKey('nfcv')) {
      final nfcvData = data['nfcv'] as Map;
      details['nfcv'] = {
        'dsfId': nfcvData['dsfId'],
        'responseFlags': nfcvData['responseFlags'],
      };
    }

    return details;
  }
}
