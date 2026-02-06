import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../services/nfc_service.dart';

class NfcScreen extends StatefulWidget {
  const NfcScreen({super.key});

  @override
  State<NfcScreen> createState() => _NfcScreenState();
}

class _NfcScreenState extends State<NfcScreen> {
  final NfcService _nfcService = NfcService();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _uriController = TextEditingController();

  bool _isNfcAvailable = false;
  bool _isReading = false;
  bool _isWriting = false;
  String? _errorMessage;
  Map<String, dynamic>? _tagData;
  Map<String, dynamic>? _tagDetails;
  String? _tagId;
  String? _tagType;

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    final isAvailable = await _nfcService.isNfcAvailable();
    setState(() {
      _isNfcAvailable = isAvailable;
      if (!isAvailable) {
        _errorMessage = 'NFC is not available on this device';
      }
    });
  }

  Future<void> _startReading() async {
    setState(() {
      _isReading = true;
      _errorMessage = null;
      _tagData = null;
      _tagDetails = null;
      _tagId = null;
      _tagType = null;
    });

    try {
      await _nfcService.startReading(
        onDiscovered: (tag) {
          setState(() {
            _tagId = _nfcService.getTagId(tag);
            _tagType = _nfcService.getTagType(tag);
            _tagData = _nfcService.readNdefMessage(tag);
            _tagDetails = _nfcService.getTagDetails(tag);
            _isReading = false;
          });
          _nfcService.stopReading();
        },
        onError: (error) {
          setState(() {
            _errorMessage = error.toString();
            _isReading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isReading = false;
      });
    }
  }

  Future<void> _startWritingText() async {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter text to write')),
      );
      return;
    }
    await _startWriting(
      writeAction: (tag) => _nfcService.writeNdefMessage(
        tag: tag,
        text: _textController.text,
      ),
      successMessage: 'Text written to tag successfully',
    );
  }

  Future<void> _startWritingUri() async {
    if (_uriController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter URI to write')),
      );
      return;
    }
    await _startWriting(
      writeAction: (tag) => _nfcService.writeUri(
        tag: tag,
        uri: _uriController.text,
      ),
      successMessage: 'URI written to tag successfully',
    );
  }

  Future<void> _startWriting({
    required Future<bool> Function(NfcTag tag) writeAction,
    required String successMessage,
  }) async {
    setState(() {
      _isWriting = true;
      _errorMessage = null;
    });

    try {
      await _nfcService.startReading(
        onDiscovered: (tag) async {
          try {
            final success = await writeAction(tag);
            if (mounted) {
              setState(() => _isWriting = false);
              _nfcService.stopReading();
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(successMessage)),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _errorMessage = e.toString();
                _isWriting = false;
              });
              _nfcService.stopReading();
            }
          }
        },
        onError: (error) {
          setState(() {
            _errorMessage = error.toString();
            _isWriting = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isWriting = false;
      });
    }
  }

  void _cancelOperation() {
    _nfcService.stopReading();
    setState(() {
      _isReading = false;
      _isWriting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // NFC Availability Status
            Card(
              color: _isNfcAvailable ? Colors.green.shade100 : Colors.red.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _isNfcAvailable ? Icons.check_circle : Icons.error,
                      color: _isNfcAvailable ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isNfcAvailable
                          ? 'NFC is available'
                          : 'NFC is not available',
                      style: TextStyle(
                        color: _isNfcAvailable ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.red.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            if (_errorMessage != null) const SizedBox(height: 16),

            // Read Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Read NFC Tag',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isNfcAvailable && !_isReading && !_isWriting
                          ? _startReading
                          : null,
                      icon: Icon(_isReading ? Icons.stop : Icons.nfc),
                      label: Text(_isReading ? 'Reading...' : 'Start Reading'),
                    ),
                    if (_isReading) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      const Text(
                        'Hold your device near an NFC tag',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _cancelOperation,
                        child: const Text('Cancel'),
                      ),
                    ],
                    if (_tagDetails != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      if (_tagId != null) ...[
                        Text('Tag ID: $_tagId',
                            style: const TextStyle(fontFamily: 'monospace')),
                        const SizedBox(height: 8),
                      ],
                      if (_tagType != null) ...[
                        Text('Tag Type: $_tagType',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                      ],
                      Text('Technologies: ${(_tagDetails!['technologies'] as List).join(', ')}'),
                      const SizedBox(height: 8),
                      Text('NDEF Formatted: ${_tagDetails!['isNdefFormatted']}'),
                      if (_tagDetails!['ndef'] != null) ...[
                        const SizedBox(height: 8),
                        Text('Writable: ${_tagDetails!['ndef']['isWritable']}'),
                        Text('Max Size: ${_tagDetails!['ndef']['maxSize']} bytes'),
                      ],
                      if (_tagDetails!['nfcv'] != null) ...[
                        const SizedBox(height: 8),
                        const Text('ISO 15693 Details:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('DSF ID: ${_tagDetails!['nfcv']['dsfId']}'),
                        Text('Response Flags: ${_tagDetails!['nfcv']['responseFlags']}'),
                      ],
                    ],
                    if (_tagData != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      Text(
                        'NDEF Records: ${(_tagData!['records'] as List).length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if ((_tagData!['records'] as List).isEmpty)
                        const Text('No NDEF records found on this tag')
                      else
                        ...(_tagData!['records'] as List).map((record) {
                          return Card(
                            color: Colors.blue.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TNF: ${record['typeNameFormat']}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (record['payloadAsString'] != null)
                                    Text(
                                      'Data: ${record['payloadAsString']}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Write Text Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Write Text to Tag',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        labelText: 'Text to write',
                        hintText: 'Enter text...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isNfcAvailable && !_isReading && !_isWriting
                          ? _startWritingText
                          : null,
                      icon: const Icon(Icons.edit),
                      label: Text(_isWriting ? 'Writing...' : 'Write Text'),
                    ),
                    if (_isWriting) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      const Text(
                        'Hold your device near an NFC tag',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _cancelOperation,
                        child: const Text('Cancel'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Write URI Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Write URI to Tag',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _uriController,
                      decoration: const InputDecoration(
                        labelText: 'URI to write',
                        hintText: 'https://example.com',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isNfcAvailable && !_isReading && !_isWriting
                          ? _startWritingUri
                          : null,
                      icon: const Icon(Icons.link),
                      label: Text(_isWriting ? 'Writing...' : 'Write URI'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  @override
  void dispose() {
    _nfcService.stopReading();
    _textController.dispose();
    _uriController.dispose();
    super.dispose();
  }
}
