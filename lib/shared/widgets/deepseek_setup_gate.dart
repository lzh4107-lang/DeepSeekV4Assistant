import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/settings_provider.dart';
import '../../icons/lucide_adapter.dart' as lucide;
import '../../l10n/app_localizations.dart';
import '../../theme/app_font_weights.dart';

class DeepSeekSetupGate extends StatefulWidget {
  const DeepSeekSetupGate({super.key, required this.child});

  final Widget child;

  @override
  State<DeepSeekSetupGate> createState() => _DeepSeekSetupGateState();
}

class _DeepSeekSetupGateState extends State<DeepSeekSetupGate> {
  bool _scheduled = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    if (settings.isLoaded && !_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final config = context.read<SettingsProvider>().getProviderConfig(
          'DeepSeek',
        );
        if (config.apiKey.trim().isEmpty) {
          unawaited(_showSetupDialog());
        }
      });
    }
    return widget.child;
  }

  Future<void> _showSetupDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DeepSeekApiKeyDialog(),
    );
  }
}

class _DeepSeekApiKeyDialog extends StatefulWidget {
  const _DeepSeekApiKeyDialog();

  @override
  State<_DeepSeekApiKeyDialog> createState() => _DeepSeekApiKeyDialogState();
}

class _DeepSeekApiKeyDialogState extends State<_DeepSeekApiKeyDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final key = _controller.text.trim();
    if (key.length < 8) {
      setState(() => _error = l10n.deepSeekSetupInvalidKey);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final settings = context.read<SettingsProvider>();
    final config = settings.getProviderConfig('DeepSeek');
    await settings.setProviderConfig(
      'DeepSeek',
      config.copyWith(apiKey: key, enabled: true),
    );
    await settings.setCurrentModel('DeepSeek', 'deepseek-v4-flash');
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openApiKeyPage() async {
    await launchUrl(
      Uri.parse('https://platform.deepseek.com/api_keys'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      icon: Icon(lucide.Lucide.KeyRound, color: cs.primary),
      title: Text(l10n.deepSeekSetupTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.deepSeekSetupDescription,
              style: TextStyle(color: cs.onSurfaceVariant, height: 1.45),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _controller,
              autofocus: true,
              obscureText: _obscure,
              enableSuggestions: false,
              autocorrect: false,
              onSubmitted: (_) {
                if (!_saving) unawaited(_save());
              },
              decoration: InputDecoration(
                labelText: l10n.deepSeekSetupApiKeyLabel,
                errorText: _error,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _obscure
                      ? l10n.deepSeekSetupShowKey
                      : l10n.deepSeekSetupHideKey,
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? lucide.Lucide.Eye : lucide.Lucide.EyeOff,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _openApiKeyPage,
              icon: const Icon(lucide.Lucide.ExternalLink, size: 16),
              label: Text(l10n.deepSeekSetupOpenKeyPage),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                textStyle: TextStyle(
                  fontWeight: AppFontWeights.semibold,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.deepSeekSetupLater),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.deepSeekSetupSaveAndStart),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
