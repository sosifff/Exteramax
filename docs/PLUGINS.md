# Exteramax plugin system (foundation)

This initial version supports declarative plugin manifests and local lifecycle
management. It deliberately does **not** execute untrusted Dart, JavaScript,
native libraries, or remote code. Installing a manifest does not grant access
to user messages, credentials, contacts, or networking.

Example manifest:

```json
{
  "id": "example.theme",
  "name": "Example theme",
  "version": "1.0.0",
  "description": "Example metadata-only extension",
  "permissions": []
}
```

Use `ExteramaxPluginManager(SharedPreferences)` from a future Flutter
plugin-management screen. `installManifest`, `list`, `setEnabled`,
and `uninstall` persist the lifecycle state.

Next steps: integrate a settings page, define vetted capability handlers,
build a permission consent flow, and test platform-specific behavior.
This is not yet a runnable third-party plugin runtime.
