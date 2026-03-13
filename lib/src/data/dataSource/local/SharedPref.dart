import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  // Guardar cualquier tipo de dato
  Future<void> save(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
 
    if (value is Map || value is List) {
      await prefs.setString(key, jsonEncode(value));
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else {
      throw Exception(
        'Tipo no soportado para SharedPreferences: ${value.runtimeType}',
      );
    }
  }

  // Leer cualquier tipo de dato
  Future<dynamic> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.get(key);

    // Si es un string, intentar parsearlo como JSON
    if (value is String) {
      try {
        return jsonDecode(value);
      } catch (e) {
        // Si no es JSON válido, devolver el string tal cual
        return value;
      }
    }

    return value;
  }

  // Leer específicamente como Map
  Future<Map<String, dynamic>?> readMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(key);

    if (value == null) {
      return null;
    }

    try {
      return Map<String, dynamic>.from(jsonDecode(value));
    } catch (e) {
      // Error al parsear JSON, retornamos null
      return null;
    }
  }

  // Leer específicamente como String
  Future<String?> readString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // Verificar si existe una key
  Future<bool> contains(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }

  // Eliminar una key
  Future<bool> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(key);
  }

  // Limpiar todo
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }


  
}
