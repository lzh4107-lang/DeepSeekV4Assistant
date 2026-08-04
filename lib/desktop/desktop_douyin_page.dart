import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_windows/webview_windows.dart' as winweb;

import '../icons/lucide_adapter.dart' as lucide;
import '../l10n/app_localizations.dart';
import '../shared/widgets/ios_tactile.dart';
import '../shared/widgets/snackbar.dart';
import '../theme/app_font_weights.dart';
import 'douyin_search_url.dart';
import 'hotkeys/chat_action_bus.dart';

class DesktopDouyinPage extends StatefulWidget {
  const DesktopDouyinPage({super.key, required this.onOpenChat});

  final VoidCallback onOpenChat;

  @override
  State<DesktopDouyinPage> createState() => _DesktopDouyinPageState();
}

class _DesktopDouyinPageState extends State<DesktopDouyinPage> {
  final TextEditingController _searchController = TextEditingController();
  winweb.WebviewController? _webviewController;
  StreamSubscription<String>? _urlSubscription;
  StreamSubscription<String>? _titleSubscription;
  StreamSubscription<winweb.LoadingState>? _loadingSubscription;
  StreamSubscription<winweb.HistoryChanged>? _historySubscription;

  String _currentUrl = 'https://www.douyin.com/';
  String _pageTitle = '';
  String _lastQuery = '';
  String? _error;
  bool _isLoading = false;
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    if (!Platform.isWindows) {
      setState(() => _error = AppLocalizations.of(context)!.douyinWindowsOnly);
      return;
    }

    setState(() => _error = null);
    try {
      final controller = winweb.WebviewController();
      await controller.initialize();
      await controller.setPopupWindowPolicy(
        winweb.WebviewPopupWindowPolicy.sameWindow,
      );

      _urlSubscription = controller.url.listen((url) {
        if (!mounted) return;
        setState(() => _currentUrl = url);
      });
      _titleSubscription = controller.title.listen((title) {
        if (!mounted) return;
        setState(() => _pageTitle = title);
      });
      _loadingSubscription = controller.loadingState.listen((state) {
        if (!mounted) return;
        setState(() => _isLoading = state == winweb.LoadingState.loading);
      });
      _historySubscription = controller.historyChanged.listen((history) {
        if (!mounted) return;
        setState(() {
          _canGoBack = history.canGoBack;
          _canGoForward = history.canGoForward;
        });
      });

      _webviewController = controller;
      if (mounted) setState(() {});
      await controller.loadUrl(_currentUrl);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(
          context,
        )!.douyinWebViewInitFailed(error.toString());
        _webviewController = null;
      });
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      showAppSnackBar(
        context,
        message: l10n.douyinSearchEmptyWarning,
        type: NotificationType.warning,
      );
      return;
    }
    _lastQuery = query;
    await _webviewController?.loadUrl(buildDouyinSearchUri(query).toString());
  }

  Future<void> _copyCurrentUrl() async {
    if (_currentUrl.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _currentUrl));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showAppSnackBar(
      context,
      message: l10n.douyinLinkCopied,
      type: NotificationType.success,
    );
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(_currentUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _addToChat() {
    if (_currentUrl.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    ChatTextInsertBus.instance.fire(
      buildDouyinConversationText(
        query: _lastQuery,
        url: _currentUrl,
        title: _pageTitle,
        intro: l10n.douyinConversationIntro,
        queryLabel: l10n.douyinConversationQueryLabel,
        currentPageLabel: l10n.douyinConversationCurrentPageLabel,
        linkLabel: l10n.douyinConversationLinkLabel,
      ),
    );
    widget.onOpenChat();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(lucide.Lucide.Video, size: 19, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.douyinSearchTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: AppFontWeights.emphasis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _ToolbarButton(
                    tooltip: l10n.douyinBackTooltip,
                    icon: lucide.Lucide.ArrowLeft,
                    onPressed: _canGoBack
                        ? () => _webviewController?.goBack()
                        : null,
                  ),
                  _ToolbarButton(
                    tooltip: l10n.douyinForwardTooltip,
                    icon: lucide.Lucide.ArrowRight,
                    onPressed: _canGoForward
                        ? () => _webviewController?.goForward()
                        : null,
                  ),
                  _ToolbarButton(
                    tooltip: l10n.douyinRefreshTooltip,
                    icon: lucide.Lucide.RefreshCw,
                    onPressed: () => _webviewController?.reload(),
                  ),
                  const Spacer(),
                  _ToolbarButton(
                    tooltip: l10n.douyinCopyLinkTooltip,
                    icon: lucide.Lucide.Copy,
                    onPressed: _copyCurrentUrl,
                  ),
                  _ToolbarButton(
                    tooltip: l10n.douyinOpenBrowserTooltip,
                    icon: lucide.Lucide.ExternalLink,
                    onPressed: _openExternally,
                  ),
                  const SizedBox(width: 8),
                  _PrimaryCommandButton(
                    label: l10n.douyinAddToChat,
                    icon: lucide.Lucide.MessageCirclePlus,
                    onTap: _addToChat,
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 64,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: cs.outlineVariant),
                bottom: BorderSide(color: cs.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: l10n.douyinSearchHint,
                      prefixIcon: const Icon(lucide.Lucide.Search, size: 18),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 46,
                  height: 46,
                  child: Tooltip(
                    message: l10n.douyinSearchTooltip,
                    child: IosCardPress(
                      onTap: _search,
                      baseColor: cs.primary,
                      borderRadius: BorderRadius.circular(8),
                      child: Icon(
                        lucide.Lucide.Search,
                        size: 19,
                        color: cs.onPrimary,
                        semanticLabel: l10n.douyinSearchTooltip,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildBrowser(cs)),
        ],
      ),
    );
  }

  Widget _buildBrowser(ColorScheme cs) {
    if (_error != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(lucide.Lucide.Video, size: 34, color: cs.error),
                const SizedBox(height: 14),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                _PrimaryCommandButton(
                  onTap: _initializeWebView,
                  icon: lucide.Lucide.RefreshCw,
                  label: AppLocalizations.of(context)!.douyinRetry,
                ),
              ],
            ),
          ),
        ),
      );
    }
    final controller = _webviewController;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return winweb.Webview(controller);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _urlSubscription?.cancel();
    _titleSubscription?.cancel();
    _loadingSubscription?.cancel();
    _historySubscription?.cancel();
    _webviewController?.dispose();
    super.dispose();
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: Tooltip(
        message: tooltip,
        child: IosIconButton(
          icon: icon,
          size: 18,
          minSize: 38,
          semanticLabel: tooltip,
          enabled: onPressed != null,
          onTap: onPressed,
        ),
      ),
    );
  }
}

class _PrimaryCommandButton extends StatelessWidget {
  const _PrimaryCommandButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: IosCardPress(
        onTap: onTap,
        baseColor: cs.primary,
        borderRadius: BorderRadius.circular(8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: cs.onPrimary),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: cs.onPrimary,
                fontWeight: AppFontWeights.emphasis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
