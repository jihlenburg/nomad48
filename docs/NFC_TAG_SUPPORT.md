# NFC Tag Support

This document describes the NFC tag types supported by the NOMAD48 application.

## Supported Tag Types

### ISO/IEC 15693 (NFC Forum Type 5)
**Status: ✅ Fully Supported**

ISO/IEC 15693 tags, also known as NFC-V or NFC Forum Type 5 tags, are fully supported for both reading and writing operations.

#### Characteristics
- **Technology**: NFC-V (Vicinity)
- **Operating Frequency**: 13.56 MHz
- **Read Range**: Up to 1.5 meters (longer than other NFC types)
- **Common Use Cases**: Inventory management, library systems, access control
- **Memory**: Varies by manufacturer (typically 256 bytes to 8 KB)

#### Supported Operations
- ✅ Read tag identifier (UID)
- ✅ Read NDEF messages (if NDEF formatted)
- ✅ Write NDEF messages (text, URI)
- ✅ Detect tag type and technology
- ✅ Read DSF ID and response flags
- ✅ Check if tag is writable

#### Popular ISO 15693 Tags
- **ICODE SLI/SLIX** (NXP)
- **Tag-it HF-I** (Texas Instruments)
- **MB89R118** (Fujitsu)
- **LRI512/LRI2K** (STMicroelectronics)

### NFC Forum Type 1 (Topaz)
**Status: ⚠️ Limited Support**

Based on ISO/IEC 14443-A.
- Common chips: Innovision Topaz
- Memory: 96 bytes (Topaz 96), 512 bytes (Topaz 512)

### NFC Forum Type 2
**Status: ✅ Supported**

Based on ISO/IEC 14443-A (NFC-A).
- Common chips: NTAG, MIFARE Ultralight
- Memory: 48 bytes to 888 bytes
- Most common consumer NFC tags

### NFC Forum Type 3
**Status: ✅ Supported**

Based on JIS X 6319-4 (NFC-F).
- Common chips: FeliCa
- Popular in Japan (transit cards, payment)

### NFC Forum Type 4
**Status: ✅ Supported**

Based on ISO/IEC 14443-A/B (IsoDep).
- Common chips: MIFARE DESFire
- Higher security, used in payment and access control

## NDEF Format Support

All tag types can store NDEF (NFC Data Exchange Format) messages if properly formatted.

### Supported NDEF Record Types
- ✅ **Text Records**: Plain text in various languages
- ✅ **URI Records**: Web links, email, phone numbers
- ⚠️ **Smart Poster**: Partially supported (basic URIs)
- ⚠️ **MIME**: Not yet implemented
- ⚠️ **External Type**: Not yet implemented

## Testing Your Tag

To verify your tag is supported:

1. Open the NOMAD48 app
2. Navigate to the NFC tab
3. Tap "Start Reading"
4. Hold your tag near the device's NFC antenna
5. Check the displayed information:
   - **Tag ID**: Unique identifier
   - **Tag Type**: Should show "NFC-V (ISO 15693 / Type 5)" for your tag
   - **Technologies**: Lists all available technologies
   - **NDEF Formatted**: Shows if tag contains NDEF data

## Reading ISO 15693 Tags

Your ISO/IEC 15693 / Type 5 tag will:
- Display its unique identifier (8 bytes, shown as hex)
- Show ISO 15693-specific details (DSF ID, response flags)
- Show NDEF records if the tag is NDEF formatted
- Display memory capacity and write status

## Writing to ISO 15693 Tags

To write to your tag:

1. Ensure the tag is NDEF formatted
2. Use the "Write Text to Tag" or "Write URI to Tag" sections
3. Enter your data
4. Tap "Write Text" or "Write URI"
5. Hold the tag near your device until writing completes

### Notes
- Some tags may be locked (read-only)
- Check "Writable: true" in tag details before writing
- Ensure your message fits within the tag's capacity
- Writing requires the tag to be unlocked

## Troubleshooting

### Tag Not Detected
- Ensure NFC is enabled on your device
- Hold the tag close to the NFC antenna (usually top-center of phone)
- Try different positions and orientations
- Some metal cases can interfere with NFC

### Cannot Write to Tag
- Check if tag is write-protected
- Verify tag has sufficient memory
- Some tags require authentication (not yet supported)

### Tag Shows "Unknown Type"
- Tag may use a non-standard format
- Tag may not be NDEF formatted
- Try formatting the tag with a dedicated NFC tool first

## Platform-Specific Notes

### iOS
- Requires iPhone 7 or newer
- NFC antenna located at the top of the device
- Tap-to-scan workflow required by iOS
- App must be in foreground for NFC operations

### Android
- NFC hardware required
- Some Android devices have better NFC range than others
- Can read tags when app is in background (with intent filters)
- Location varies by device (usually near the camera)

## References

- [ISO/IEC 15693 Standard](https://www.iso.org/standard/43467.html)
- [NFC Forum Type 5 Specification](https://nfc-forum.org/our-work/specification-releases/specifications/nfc-forum-technical-specifications/)
- [NDEF Specification](https://nfc-forum.org/our-work/specifications-and-application-documents/specifications/nfc-forum-technical-specifications/)
