import 'package:flutter/material.dart';

import '../../../services/namecoin/namecoin.dart';
import '../../../utils/utils.dart';

class NamecoinSettingsView extends StatefulWidget {
  const NamecoinSettingsView({super.key});

  @override
  State<NamecoinSettingsView> createState() => _NamecoinSettingsViewState();
}

class _NamecoinSettingsViewState extends State<NamecoinSettingsView> {
  late NamecoinSettings _settings;
  final _serverController = TextEditingController();
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _settings = namecoinService.settings;
  }

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

  void _updateSettings(NamecoinSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    namecoinService.updateSettings(newSettings);
    namecoinPreferences.save(newSettings);
  }

  void _toggleEnabled(bool enabled) {
    _updateSettings(_settings.copyWith(enabled: enabled));
  }

  void _addServer() {
    final input = _serverController.text.trim();
    if (input.isEmpty) {
      setState(() => _validationError = 'Enter a server address');
      return;
    }
    final parsed = NamecoinSettings.parseServerString(input);
    if (parsed == null) {
      setState(
        () => _validationError = 'Invalid format. Use host:port or host:port:tcp',
      );
      return;
    }
    if (_settings.customServers.contains(input)) {
      setState(() => _validationError = 'Server already added');
      return;
    }
    setState(() => _validationError = null);
    _serverController.clear();
    _updateSettings(
      _settings.copyWith(
        customServers: [..._settings.customServers, input],
      ),
    );
  }

  void _removeServer(String server) {
    _updateSettings(
      _settings.copyWith(
        customServers:
            _settings.customServers.where((s) => s != server).toList(),
      ),
    );
  }

  void _resetToDefaults() {
    _updateSettings(NamecoinSettings.defaultSettings);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Namecoin Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Enable/disable toggle ───────────────────────────────
          _buildHeader(theme),
          const SizedBox(height: 16),

          if (_settings.enabled) ...[
            // ── Explanation ───────────────────────────────────────
            Text(
              'Namecoin names (.bit, d/, id/) are resolved via ElectrumX '
              'servers. By default, public community servers are used. '
              'For maximum privacy, add your own server below — when '
              'custom servers are set, the defaults are completely ignored.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 20),

            // ── Active servers ────────────────────────────────────
            _buildActiveServers(theme),
            const Divider(height: 32),

            // ── Custom servers list ──────────────────────────────
            _buildCustomServersList(theme),
            const SizedBox(height: 12),

            // ── Add server input ─────────────────────────────────
            _buildAddServerInput(theme),
            const SizedBox(height: 16),

            // ── Reset button ─────────────────────────────────────
            if (_settings.hasCustomServers) _buildResetButton(theme),

            const SizedBox(height: 24),

            // ── Test lookup section ──────────────────────────────
            _TestLookupSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        const Icon(
          Icons.lock_outline,
          color: Color(0xFF4A90D9),
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Namecoin Resolution',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Blockchain identity lookups (.bit)',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: _settings.enabled,
          onChanged: _toggleEnabled,
        ),
      ],
    );
  }

  Widget _buildActiveServers(ThemeData theme) {
    final servers =
        _settings.toElectrumxServers() ?? defaultElectrumxServers;
    final isCustom = _settings.hasCustomServers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active servers',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isCustom
                    ? const Color(0xFF4A90D9).withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isCustom ? 'CUSTOM' : 'DEFAULT',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isCustom
                      ? const Color(0xFF4A90D9)
                      : theme.hintColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...servers.map(
          (server) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Text(
                  '•',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF2E8B57),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${server.host}:${server.port}'
                  ' ${server.useSsl ? "(tls)" : "(tcp)"}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomServersList(ThemeData theme) {
    if (_settings.customServers.isEmpty) {
      return Text(
        'No custom servers configured',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.hintColor.withOpacity(0.6),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom servers (used exclusively)',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        ..._settings.customServers.map(
          (server) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    server,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: theme.colorScheme.error,
                    size: 16,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () => _removeServer(server),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddServerInput(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _serverController,
            decoration: InputDecoration(
              labelText: 'Add ElectrumX server',
              hintText: 'host:port or host:port:tcp',
              errorText: _validationError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
            onChanged: (_) {
              if (_validationError != null) {
                setState(() => _validationError = null);
              }
            },
            onSubmitted: (_) => _addServer(),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: IconButton(
            onPressed: _addServer,
            icon: const Icon(Icons.add),
            style: IconButton.styleFrom(
              backgroundColor:
                  theme.colorScheme.primary.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton(ThemeData theme) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: _resetToDefaults,
        icon: const Icon(Icons.refresh, size: 16),
        label: const Text('Reset to defaults'),
      ),
    );
  }
}

/// A small test-lookup widget that lets users try resolving a .bit name.
class _TestLookupSection extends StatefulWidget {
  @override
  State<_TestLookupSection> createState() => _TestLookupSectionState();
}

class _TestLookupSectionState extends State<_TestLookupSection> {
  final _testController = TextEditingController();
  String? _testResult;
  bool _isLoading = false;

  @override
  void dispose() {
    _testController.dispose();
    super.dispose();
  }

  Future<void> _performTestLookup() async {
    final input = _testController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _isLoading = true;
      _testResult = null;
    });

    try {
      final outcome = await namecoinService.resolveDetailed(input);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (outcome is NamecoinResolveSuccess) {
          final r = outcome.result;
          _testResult =
              '✅ Found!\n'
              'Pubkey: ${r.pubkey.substring(0, 16)}…\n'
              'Name: ${r.namecoinName}\n'
              'Local: ${r.localPart}'
              '${r.relays.isNotEmpty ? '\nRelays: ${r.relays.join(", ")}' : ''}';
        } else if (outcome is NamecoinNameNotFound) {
          _testResult = '❌ Name not found: ${outcome.name}';
        } else if (outcome is NamecoinNoNostrField) {
          _testResult =
              '⚠️ Name exists but has no "nostr" field: ${outcome.name}';
        } else if (outcome is NamecoinServersUnreachable) {
          _testResult =
              '🔌 All servers unreachable: ${outcome.message}';
        } else if (outcome is NamecoinInvalidIdentifier) {
          _testResult =
              '❓ Not a valid Namecoin identifier: ${outcome.identifier}';
        } else if (outcome is NamecoinTimeout) {
          _testResult = '⏱️ Lookup timed out';
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _testResult = '❌ Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text(
          'Test Lookup',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Try resolving a Namecoin name to verify your setup.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.hintColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _testController,
                decoration: InputDecoration(
                  hintText: 'e.g. example.bit or alice@example.bit',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
                style: theme.textTheme.bodySmall,
                onSubmitted: (_) => _performTestLookup(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _performTestLookup,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Resolve'),
            ),
          ],
        ),
        if (_testResult != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _testResult!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ],
    );
  }
}
