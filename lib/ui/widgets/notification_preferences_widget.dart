import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../l10n/app_localizations.dart';

class NotificationPreferencesWidget extends StatefulWidget {
  final NotificationPreferences preferences;
  final Function(NotificationPreferences) onChanged;

  const NotificationPreferencesWidget({
    super.key,
    required this.preferences,
    required this.onChanged,
  });

  @override
  State<NotificationPreferencesWidget> createState() => _NotificationPreferencesWidgetState();
}

class _NotificationPreferencesWidgetState extends State<NotificationPreferencesWidget> {
  late NotificationPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _prefs = widget.preferences;
  }

  void _updatePrefs(NotificationPreferences newPrefs) {
    setState(() {
      _prefs = newPrefs;
    });
    widget.onChanged(newPrefs);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.get('notifications'),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: Text(l10n.get('push_notifications')),
          value: _prefs.pushEnabled,
          onChanged: (val) => _updatePrefs(_prefs.copyWith(pushEnabled: val)),
          secondary: const Icon(Icons.notifications_active_outlined),
        ),
        SwitchListTile(
          title: Text(l10n.get('email_notifications')),
          value: _prefs.emailEnabled,
          onChanged: (val) => _updatePrefs(_prefs.copyWith(emailEnabled: val)),
          secondary: const Icon(Icons.email_outlined),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.get('notification_events'),
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._prefs.events.keys.map((eventKey) {
          return CheckboxListTile(
            title: Text(l10n.get('notify_$eventKey')),
            value: _prefs.events[eventKey],
            onChanged: (val) {
              final newEvents = Map<String, bool>.from(_prefs.events);
              newEvents[eventKey] = val ?? false;
              _updatePrefs(_prefs.copyWith(events: newEvents));
            },
            controlAffinity: ListTileControlAffinity.leading,
          );
        }).toList(),
      ],
    );
  }
}
