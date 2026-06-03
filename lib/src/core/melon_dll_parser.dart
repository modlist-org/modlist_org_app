import 'dart:convert';
import 'dart:io';

class SectionHeader {
  final String name;
  final int virtualSize;
  final int virtualAddress;
  final int sizeOfRawData;
  final int pointerToRawData;

  SectionHeader({
    required this.name,
    required this.virtualSize,
    required this.virtualAddress,
    required this.sizeOfRawData,
    required this.pointerToRawData,
  });
}

class MelonInfo {
  final String name;
  final String version;
  final String author;

  MelonInfo({required this.name, required this.version, required this.author});

  @override
  String toString() => 'Name: $name, Version: $version, Author: $author';
}

class MelonDllParser {
  static MelonInfo? parse(String dllPath) {
    final file = File(dllPath);
    if (!file.existsSync()) return null;

    final raf = file.openSync(mode: FileMode.read);
    try {
      // 1. PE Header parsing
      raf.setPositionSync(0x3C);
      final peOffset = readUint32(raf);
 
      raf.setPositionSync(peOffset);
      final peSig = readUint32(raf);
      if (peSig != 0x00004550) { // "PE\0\0"
        return null;
      }
 
      // COFF Header
      readUint16(raf); // machine (unused)
      final numberOfSections = readUint16(raf);
      raf.setPositionSync(raf.positionSync() + 12); // skip TimeDateStamp, PointerToSymbolTable, NumberOfSymbols
      final sizeOfOptionalHeader = readUint16(raf);
      readUint16(raf); // characteristics (unused)
 
      // Optional Header
      final optHeaderPos = raf.positionSync();
      final magic = readUint16(raf);
      final is64 = magic == 0x020B; // PE32+
 
      // CLR Runtime Header Directory is at index 14
      // PE32: offset 208 from optional header start (size 8)
      // PE32+: offset 224 from optional header start (size 8)
      final clrDirOffset = optHeaderPos + (is64 ? 224 : 208);
      raf.setPositionSync(clrDirOffset);
      final clrRva = readUint32(raf);
      final clrSize = readUint32(raf);

      if (clrRva == 0 || clrSize == 0) {
        return null;
      }

      // Section Headers
      final sectionHeadersPos = optHeaderPos + sizeOfOptionalHeader;
      raf.setPositionSync(sectionHeadersPos);
      final sections = <SectionHeader>[];
      for (var i = 0; i < numberOfSections; i++) {
        final nameBytes = raf.readSync(8);
        var name = utf8.decode(nameBytes.where((b) => b != 0).toList());
        final virtualSize = readUint32(raf);
        final virtualAddress = readUint32(raf);
        final sizeOfRawData = readUint32(raf);
        final pointerToRawData = readUint32(raf);
        raf.setPositionSync(raf.positionSync() + 12); // skip PointerToRelocations, PointerToLinenumbers, NumberOfRelocations, NumberOfLinenumbers, Characteristics
        
        sections.add(SectionHeader(
          name: name,
          virtualSize: virtualSize,
          virtualAddress: virtualAddress,
          sizeOfRawData: sizeOfRawData,
          pointerToRawData: pointerToRawData,
        ));
      }

      int rvaToOffset(int rva) {
        for (final sec in sections) {
          if (rva >= sec.virtualAddress && rva < sec.virtualAddress + sec.virtualSize) {
            return sec.pointerToRawData + (rva - sec.virtualAddress);
          }
        }
        return 0;
      }

      // 2. CLR Runtime Header
      final clrOffset = rvaToOffset(clrRva);
      if (clrOffset == 0) return null;
 
      raf.setPositionSync(clrOffset + 8); // Skip cb (size), MajorRuntimeVersion, MinorRuntimeVersion
      final metadataRva = readUint32(raf);
      final metadataSize = readUint32(raf);
 
      if (metadataRva == 0 || metadataSize == 0) return null;
 
      final metadataOffset = rvaToOffset(metadataRva);
      if (metadataOffset == 0) return null;
 
      // Metadata Root
      raf.setPositionSync(metadataOffset);
      final metaSig = readUint32(raf);
      if (metaSig != 0x424A5342) { // "BSJB"
        return null;
      }
 
      raf.setPositionSync(metadataOffset + 12); // skip MajorVersion, MinorVersion, Extra
      final versionLength = readUint32(raf);
      // Padded to 4-byte boundary
      final versionLengthPadded = ((versionLength + 3) ~/ 4) * 4;
      raf.setPositionSync(raf.positionSync() + versionLengthPadded); // skip version string
 
      readUint16(raf); // flags (unused)
      final streamsCount = readUint16(raf);
 
      var stringsOffset = 0;
      var stringsSize = 0;
      var blobOffset = 0;
      var tablesOffset = 0;

      for (var i = 0; i < streamsCount; i++) {
        final offset = readUint32(raf);
        final size = readUint32(raf);
        
        // Read stream name
        final nameBytes = <int>[];
        while (true) {
          final b = raf.readByteSync();
          if (b == 0 || b == -1) break;
          nameBytes.add(b);
        }
        final name = utf8.decode(nameBytes);
        // Align stream name position to 4-byte boundary
        final nameLength = nameBytes.length + 1;
        final namePadding = ((nameLength + 3) ~/ 4) * 4 - nameLength;
        if (namePadding > 0) {
          raf.readSync(namePadding);
        }

        final streamFileOffset = metadataOffset + offset;
        if (name == '#Strings') {
          stringsOffset = streamFileOffset;
          stringsSize = size;
        } else if (name == '#Blob') {
          blobOffset = streamFileOffset;
        } else if (name == '#~' || name == '#-') {
          tablesOffset = streamFileOffset;
        }
      }

      if (stringsOffset == 0 || blobOffset == 0 || tablesOffset == 0) {
        return null;
      }

      // Read String from #Strings heap
      String readStringsHeap(int offset) {
        if (offset < 0 || offset >= stringsSize) return '';
        final currentPos = raf.positionSync();
        raf.setPositionSync(stringsOffset + offset);
        final bytes = <int>[];
        while (true) {
          final b = raf.readByteSync();
          if (b == 0 || b == -1) break;
          bytes.add(b);
        }
        raf.setPositionSync(currentPos);
        return utf8.decode(bytes, allowMalformed: true);
      }
 
      // 3. Tables stream parsing
      raf.setPositionSync(tablesOffset);
      readUint32(raf); // reserved1 (unused)
      raf.readByteSync(); // majorVersion (unused)
      raf.readByteSync(); // minorVersion (unused)
      final heapSizes = raf.readByteSync();
      raf.readByteSync(); // reserved2 (unused)
      final validMask = readUint64(raf);
      readUint64(raf); // sortedMask (unused)

      // Count number of rows in each present table
      final tableRows = List<int>.filled(64, 0);
      for (var i = 0; i < 64; i++) {
        if ((validMask & (1 << i)) != 0) {
          tableRows[i] = readUint32(raf);
        }
      }

      final stringIndexSize = (heapSizes & 0x01) != 0 ? 4 : 2;
      final guidIndexSize = (heapSizes & 0x02) != 0 ? 4 : 2;
      final blobIndexSize = (heapSizes & 0x04) != 0 ? 4 : 2;

      int getTableIndexSize(int tableId) {
        return tableRows[tableId] >= 65536 ? 4 : 2;
      }

      int getCodedIndexSize(List<int> tables, int bits) {
        var maxRows = 0;
        for (final tid in tables) {
          if (tid != -1 && tableRows[tid] > maxRows) {
            maxRows = tableRows[tid];
          }
        }
        return maxRows >= (1 << (16 - bits)) ? 4 : 2;
      }

      // Sizes of Coded Indices
      final typeDefOrRefSize = getCodedIndexSize([0x02, 0x01, 0x1B], 2); // TypeDef, TypeRef, TypeSpec
      final resolutionScopeSize = getCodedIndexSize([0x00, 0x1A, 0x23, 0x01], 2); // Module, ModuleRef, AssemblyRef, TypeRef
      final memberRefParentSize = getCodedIndexSize([0x02, 0x01, 0x1A, 0x06, 0x1B], 3); // TypeDef, TypeRef, ModuleRef, MethodDef, TypeSpec
      final hasCustomAttributeSize = getCodedIndexSize([
        0x06, 0x04, 0x01, 0x02, 0x08, 0x09, 0x0A, 0x00, 0x0E, 0x17, 0x14, 0x11, 0x1A, 0x1B, 0x20, 0x23, 0x26, 0x27, 0x28
      ], 5);
      final customAttributeTypeSize = getCodedIndexSize([-1, -1, 0x06, 0x0A, -1], 3); // MethodDef, MemberRef

      // Calculate row sizes of all tables
      final tableRowSizes = List<int>.filled(64, 0);
      tableRowSizes[0x00] = 2 + stringIndexSize + 3 * guidIndexSize; // Module
      tableRowSizes[0x01] = resolutionScopeSize + 2 * stringIndexSize; // TypeRef
      tableRowSizes[0x02] = 4 + 2 * stringIndexSize + typeDefOrRefSize + getTableIndexSize(0x04) + getTableIndexSize(0x06); // TypeDef
      tableRowSizes[0x04] = 2 + stringIndexSize + blobIndexSize; // Field
      tableRowSizes[0x06] = 8 + stringIndexSize + blobIndexSize + getTableIndexSize(0x08); // MethodDef
      tableRowSizes[0x08] = 4 + stringIndexSize; // Param
      tableRowSizes[0x09] = getTableIndexSize(0x02) + typeDefOrRefSize; // InterfaceImpl
      tableRowSizes[0x0A] = memberRefParentSize + stringIndexSize + blobIndexSize; // MemberRef
      tableRowSizes[0x0B] = 2 + getCodedIndexSize([0x04, 0x08, 0x17], 2) + blobIndexSize; // Constant
      tableRowSizes[0x0C] = hasCustomAttributeSize + customAttributeTypeSize + blobIndexSize; // CustomAttribute
      tableRowSizes[0x20] = 16 + stringIndexSize + blobIndexSize; // Assembly
 
      // Parse TypeRef to find any of "MelonInfoAttribute", "MelonModAttribute", or "MelonPluginAttribute"
      final melonInfoTypeRefIndices = <int>{};
      
      // The tables data starts after the 24-byte header and the row counts for each present table
      final tableDataStart = tablesOffset + 24 + (validMask.bitCount() * 4);
      
      // Let's search TypeRef table precisely by iterating
      var pTypeRef = tableDataStart;
      for (var i = 0; i < 64; i++) {
        if (((validMask >> i) & 1) != 0) {
          if (i == 0x01) break;
          pTypeRef += tableRows[i] * tableRowSizes[i];
        }
      }

      for (var row = 1; row <= tableRows[0x01]; row++) {
        raf.setPositionSync(pTypeRef + (row - 1) * tableRowSizes[0x01]);
        raf.readSync(resolutionScopeSize); // Skip ResolutionScope
        final typeNameIndex = readIndex(raf, stringIndexSize);
        final typeNamespaceIndex = readIndex(raf, stringIndexSize);
        final typeName = readStringsHeap(typeNameIndex);
        final typeNamespace = readStringsHeap(typeNamespaceIndex);
        if ((typeName == 'MelonInfoAttribute' ||
             typeName == 'MelonModAttribute' ||
             typeName == 'MelonPluginAttribute') &&
            typeNamespace == 'MelonLoader') {
          melonInfoTypeRefIndices.add(row);
        }
      }

      if (melonInfoTypeRefIndices.isEmpty) {
        return null;
      }

      // Parse MemberRef to find constructor of the attribute
      // Coded index CustomAttributeType points to MethodDef (tag 2) or MemberRef (tag 3)
      final melonInfoCtorMemberRefIndices = <int>{};
      var pMemberRef = tableDataStart;
      for (var i = 0; i < 64; i++) {
        if (((validMask >> i) & 1) != 0) {
          if (i == 0x0A) break;
          pMemberRef += tableRows[i] * tableRowSizes[i];
        }
      }

      for (var row = 1; row <= tableRows[0x0A]; row++) {
        raf.setPositionSync(pMemberRef + (row - 1) * tableRowSizes[0x0A]);
        final classCoded = readIndex(raf, memberRefParentSize);
        final classTag = classCoded & 7;
        final classRow = classCoded >> 3;

        // tag 1 is TypeRef
        if (classTag == 1 && melonInfoTypeRefIndices.contains(classRow)) {
          final nameIndex = readIndex(raf, stringIndexSize);
          final name = readStringsHeap(nameIndex);
          if (name == '.ctor') {
            melonInfoCtorMemberRefIndices.add(row);
          }
        }
      }

      if (melonInfoCtorMemberRefIndices.isEmpty) {
        return null;
      }

      // Parse CustomAttribute table to find the one matching this constructor
      var pCustomAttribute = tableDataStart;
      for (var i = 0; i < 64; i++) {
        if (((validMask >> i) & 1) != 0) {
          if (i == 0x0C) break;
          pCustomAttribute += tableRows[i] * tableRowSizes[i];
        }
      }

      var melonInfoBlobOffset = -1;
      for (var row = 1; row <= tableRows[0x0C]; row++) {
        raf.setPositionSync(pCustomAttribute + (row - 1) * tableRowSizes[0x0C]);
        final parentCoded = readIndex(raf, hasCustomAttributeSize);
        // Parent should be Assembly (tag 14)
        final parentTag = parentCoded & 31;
        
        if (parentTag == 14) { // Assembly level attribute
          final typeCoded = readIndex(raf, customAttributeTypeSize);
          final typeTag = typeCoded & 7;
          final typeRow = typeCoded >> 3;

          // typeTag 3 is MemberRef
          if (typeTag == 3 && melonInfoCtorMemberRefIndices.contains(typeRow)) {
            melonInfoBlobOffset = readIndex(raf, blobIndexSize);
            break;
          }
        }
      }

      if (melonInfoBlobOffset == -1) {
        return null;
      }

      // 4. Parse custom attribute blob in #Blob
      final blobPos = blobOffset + melonInfoBlobOffset;
      raf.setPositionSync(blobPos);
      
      // Read packed size of blob
      readBlobSize(raf); // blobSizeVal (unused)
 
      // Custom Attribute Prolog is 0x0001
      final prolog = readUint16(raf);
      if (prolog != 1) return null;
 
      // MelonInfo(Type type, string name, string version, string author, string downloadUrl = null)
      // Arguments order: Type (System.Type is serialized as string name), Name (string), Version (string), Author (string)
      readSerString(raf); // typeName (unused)
      final name = readSerString(raf);
      final version = readSerString(raf);
      final author = readSerString(raf);

      if (name != null && version != null && author != null) {
        return MelonInfo(name: name, version: version, author: author);
      }
    } catch (_) {} finally {
      raf.closeSync();
    }
    return null;
  }

  static int readUint16(RandomAccessFile raf) {
    final bytes = raf.readSync(2);
    if (bytes.length < 2) throw Exception('Unexpected EOF');
    return bytes[0] | (bytes[1] << 8);
  }

  static int readUint32(RandomAccessFile raf) {
    final bytes = raf.readSync(4);
    if (bytes.length < 4) throw Exception('Unexpected EOF');
    return bytes[0] | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24);
  }

  static int readUint64(RandomAccessFile raf) {
    final bytes = raf.readSync(8);
    if (bytes.length < 8) throw Exception('Unexpected EOF');
    var val = 0;
    for (var i = 0; i < 8; i++) {
      val |= (bytes[i] << (i * 8));
    }
    return val;
  }

  static int readIndex(RandomAccessFile raf, int size) {
    if (size == 4) {
      return readUint32(raf);
    } else {
      return readUint16(raf);
    }
  }

  static int readBlobSize(RandomAccessFile raf) {
    final b1 = raf.readByteSync();
    if (b1 == -1) return 0;
    if ((b1 & 0x80) == 0) {
      return b1;
    } else if ((b1 & 0xC0) == 0x80) {
      final b2 = raf.readByteSync();
      if (b2 == -1) return 0;
      return ((b1 & 0x3F) << 8) | b2;
    } else {
      final b2 = raf.readByteSync();
      final b3 = raf.readByteSync();
      final b4 = raf.readByteSync();
      if (b2 == -1 || b3 == -1 || b4 == -1) return 0;
      return ((b1 & 0x1F) << 24) | (b2 << 16) | (b3 << 8) | b4;
    }
  }

  static String? readSerString(RandomAccessFile raf) {
    final b = raf.readByteSync();
    if (b == -1 || b == 0xFF) return null; // null SerString / EOF
    if (b == 0x00) return '';   // empty SerString
    
    // Read packed length
    raf.setPositionSync(raf.positionSync() - 1);
    final length = readBlobSize(raf);
    if (length <= 0 || length > 1024 * 1024) return null; // safety check
    final bytes = raf.readSync(length);
    return utf8.decode(bytes);
  }
}
 
extension IntExtensions on int {
  int bitCount() {
    var v = this;
    v = v - ((v >> 1) & 0x5555555555555555);
    v = (v & 0x3333333333333333) + ((v >> 2) & 0x3333333333333333);
    return (((v + (v >> 4)) & 0xF0F0F0F0F0F0F0F) * 0x101010101010101) >> 56;
  }
}

