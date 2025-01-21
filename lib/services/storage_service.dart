import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/file_item.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;
  static const String _filesKey = 'files';
  static bool _initialized = false;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (!_initialized) {
      _instance = StorageService._();
      try {
        _prefs = await SharedPreferences.getInstance();
        _initialized = true;
      } catch (e) {
        _instance = null;
        debugPrint('SharedPreferences initialization failed: $e');
        rethrow;
      }
    }
    return _instance!;
  }

  Future<void> saveFiles(List<FileItem> files) async {
    if (!_initialized) throw Exception('StorageService not initialized');
    
    try {
      final filesList = files.map((file) => {
        'name': file.name,
        'path': file.path,
        'dateAdded': file.dateAdded.toIso8601String(),
      }).toList();
      
      await _prefs?.setString(_filesKey, jsonEncode(filesList));
    } catch (e) {
      debugPrint('Error saving files: $e');
      rethrow;
    }
  }

  Future<List<FileItem>> loadFiles() async {
    if (!_initialized) throw Exception('StorageService not initialized');
    
    try {
      final filesJson = _prefs?.getString(_filesKey);
      if (filesJson == null) return [];
      
      final filesList = jsonDecode(filesJson) as List;
      return filesList.map((file) => FileItem(
        name: file['name'],
        path: file['path'],
        dateAdded: DateTime.parse(file['dateAdded']),
      )).toList();
    } catch (e) {
      debugPrint('Error loading files: $e');
      return [];
    }
  }
}