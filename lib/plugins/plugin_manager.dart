import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Declarative plugin metadata. No arbitrary Dart or native code execution.
class ExteramaxPlugin {
  final String id;
  final String name;
  final String version;
  final String description;
  final List<String> permissions;
  final bool enabled;

  const ExteramaxPlugin({required this.id, required this.name,
    required this.version, required this.description,
    required this.permissions, required this.enabled});

  factory ExteramaxPlugin.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final version = json['version'];
    if (id is! String || !RegExp(r'^[a-z0-9][a-z0-9._-]{2,63}$').hasMatch(id) ||
        name is! String || name.trim().isEmpty || name.length > 80 ||
        version is! String || version.length > 40) {
      throw const FormatException('Invalid plugin manifest');
    }
    final permissions = json['permissions'];
    if (permissions != null && (permissions is! List ||
        permissions.any((p) => p is! String))) {
      throw const FormatException('Invalid permissions');
    }
    return ExteramaxPlugin(id:id, name:name, version:version,
      description:(json['description'] as String?) ?? '',
      permissions:List<String>.from(permissions ?? const []),
      enabled:json['enabled'] == true);
  }

  ExteramaxPlugin copyWith({bool? enabled}) => ExteramaxPlugin(
    id:id, name:name, version:version, description:description,
    permissions:permissions, enabled:enabled ?? this.enabled);

  Map<String,dynamic> toJson() => {
    'id':id, 'name':name, 'version':version, 'description':description,
    'permissions':permissions, 'enabled':enabled
  };
}

class ExteramaxPluginManager {
  static const _storageKey = 'exteramax_plugins_v1';
  final SharedPreferences prefs;
  ExteramaxPluginManager(this.prefs);

  List<ExteramaxPlugin> list() {
    final raw = prefs.getString(_storageKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).map((p) =>
        ExteramaxPlugin.fromJson(Map<String,dynamic>.from(p as Map))).toList();
    } catch (_) { return []; }
  }

  Future<void> installManifest(String json) async {
    if (json.length > 32768) throw const FormatException('Manifest too large');
    final plugin = ExteramaxPlugin.fromJson(
      Map<String,dynamic>.from(jsonDecode(json) as Map));
    final plugins = list()..removeWhere((p) => p.id == plugin.id);
    // Every installation and update starts disabled; no implicit permission grants.
    plugins.add(plugin.copyWith(enabled:false));
    await _save(plugins);
  }

  Future<void> setEnabled(String id, bool enabled) async {
    final plugins = list();
    final index = plugins.indexWhere((p) => p.id == id);
    if (index < 0) throw StateError('Plugin not found');
    // A future permissions UI must grant capabilities before enabling them.
    if (enabled && plugins[index].permissions.isNotEmpty) {
      throw StateError('Permissions must be approved before activation');
    }
    plugins[index] = plugins[index].copyWith(enabled:enabled);
    await _save(plugins);
  }

  Future<void> uninstall(String id) async {
    await _save(list()..removeWhere((p) => p.id == id));
  }

  Future<void> _save(List<ExteramaxPlugin> plugins) =>
    prefs.setString(_storageKey, jsonEncode(plugins.map((p) => p.toJson()).toList()));
}
