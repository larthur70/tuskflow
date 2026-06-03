import 'package:flutter/material.dart';
import 'package:tuskflow/features/notifications/notification_service.dart';
import 'package:tuskflow/features/notifications/services/notification_banner_service.dart';

class NotificationDisabledBanner extends StatefulWidget {
  const NotificationDisabledBanner({
    super.key,
    required this.placement,
    this.refreshToken = 0,
  });

  final NotificationBannerPlacement placement;
  final int refreshToken;

  @override
  State<NotificationDisabledBanner> createState() =>
      _NotificationDisabledBannerState();
}

class _NotificationDisabledBannerState extends State<NotificationDisabledBanner>
    with WidgetsBindingObserver {
  final NotificationBannerService _bannerService = NotificationBannerService();
  bool _visible = false;

  static const Color _bannerRed = Color(0xFFD32F2F);
  static const Color _buttonRed = Color(0xFFB71C1C);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshVisibility();
  }

  @override
  void didUpdateWidget(NotificationDisabledBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _refreshVisibility();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshVisibility();
    }
  }

  Future<void> _refreshVisibility() async {
    final shouldShow =
        await _bannerService.shouldShowBanner(widget.placement);
    if (!mounted) return;
    setState(() => _visible = shouldShow);
  }

  Future<void> _onActivateNotifications() async {
    await NotificationService.instance.openDeviceNotificationSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final padding = widget.placement == NotificationBannerPlacement.home
        ? const EdgeInsets.fromLTRB(16, 8, 16, 0)
        : EdgeInsets.zero;

    return Padding(
      padding: padding,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _bannerRed,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Notificações desativadas',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'O Tusk não consegue avisar você sobre tarefas e prazos importantes.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: _buttonRed,
                  shape: const StadiumBorder(),
                ),
                onPressed: _onActivateNotifications,
                child: const Text(
                  'Ativar notificações',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
