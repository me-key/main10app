import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class StorageService {
  final FirebaseStorage? _storageOverride;

  StorageService({FirebaseStorage? storage}) : _storageOverride = storage;

  FirebaseStorage get _storage {
    if (_storageOverride != null) return _storageOverride!;
    return FirebaseStorage.instance;
  }

  /// Uploads a file to Firebase Storage and returns the download URL.
  Future<String> uploadFile(XFile file, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final ref = _storage.ref().child(folder).child(fileName);
      
      print('StorageService: Starting upload to ${ref.fullPath}');
      
      SettableMetadata? metadata;
      if (kIsWeb) {
        // web needs mime type often for correct serving
        final mimeType = _getMimeType(file.path);
        metadata = SettableMetadata(contentType: mimeType);
      }

      final uploadTask = ref.putData(await file.readAsBytes(), metadata);
      
      // Monitor progress and wait for completion
      final taskSnapshot = await uploadTask;
      
      if (taskSnapshot.state == TaskState.success) {
        print('StorageService: Upload successful, fetching download URL...');
        
        // Sometimes getDownloadURL fails if called too quickly after completion (object-not-found)
        // Adding a small delay and retry logic
        String? url;
        int retries = 3;
        while (retries > 0) {
          try {
            url = await taskSnapshot.ref.getDownloadURL();
            break; 
          } catch (e) {
            print('StorageService: getDownloadURL attempt failed, retrying in 1s... ($retries left)');
            retries--;
            if (retries == 0) rethrow;
            await Future.delayed(const Duration(seconds: 1));
          }
        }
        
        print('StorageService: Got download URL: $url');
        return url!;
      } else {
        throw Exception('Upload failed with state: ${taskSnapshot.state}');
      }
    } catch (e) {
      print('StorageService: Error uploading file: $e');
      rethrow;
    }
  }

  String? _getMimeType(String fileName) {
    if (fileName.endsWith('.png')) return 'image/png';
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) return 'image/jpeg';
    if (fileName.endsWith('.gif')) return 'image/gif';
    return null;
  }

  /// Uploads multiple files and returns a list of download URLs.
  Future<List<String>> uploadFiles(List<XFile> files, String folder) async {
    final List<String> urls = [];
    for (final file in files) {
      final url = await uploadFile(file, folder);
      urls.add(url);
    }
    return urls;
  }

  /// Deletes a file from Firebase Storage given its URL.
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // Log error or ignore if file already deleted
      print('Error deleting file: $e');
    }
  }
}
