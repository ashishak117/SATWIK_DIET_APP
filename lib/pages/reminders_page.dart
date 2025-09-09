// lib/pages/reminders_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/reminder.dart';
import '../services/reminder_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final _service = ReminderService();
  final _user = FirebaseAuth.instance.currentUser;
  List<Reminder> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_user == null) {
      setState(() {
        _items = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final items = await _service.getReminders(_user!.uid);
      items.sort((a, b) {
        final aMinutes = a.hour * 60 + a.minute;
        final bMinutes = b.hour * 60 + b.minute;
        return aMinutes.compareTo(bMinutes);
      });
      if (mounted) setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('RemindersPage._load error: $e\n$st');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load reminders: $e")),
        );
      }
    }
  }

  Future<void> _showEditor({Reminder? existing}) async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please sign in to manage reminders.")),
      );
      return;
    }

    String title = existing?.title ?? 'Reminder';
    String body = existing?.body ?? '';
    int hour = existing?.hour ?? 8;
    int minute = existing?.minute ?? 0;
    String type = existing?.type ?? 'meal';
    bool repeatDaily = existing?.repeatDaily ?? true;
    bool enabled = existing?.enabled ?? true;
    int intervalHours = existing?.intervalHours ?? 2;

    final titleCtrl = TextEditingController(text: title);
    final bodyCtrl = TextEditingController(text: body);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      existing == null ? 'New reminder' : 'Edit reminder',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 12),
                TextField(controller: bodyCtrl, decoration: const InputDecoration(labelText: 'Body (optional)')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Time:', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay(hour: hour, minute: minute),
                        );
                        if (t != null) {
                          setState(() {
                            hour = t.hour;
                            minute = t.minute;
                          });
                        }
                      },
                      child: Text('${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          if (type == 'meal') {
                            hour = 8;
                            minute = 0;
                          } else if (type == 'hydration') {
                            hour = 9;
                            minute = 0;
                          } else {
                            hour = 18;
                            minute = 0;
                          }
                        });
                      },
                      icon: const Icon(Icons.schedule),
                      label: const Text('Preset'),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'meal', child: Text('Meal')),
                    DropdownMenuItem(value: 'hydration', child: Text('Hydration')),
                    DropdownMenuItem(value: 'custom', child: Text('Custom')),
                  ],
                  onChanged: (v) => setState(() => type = v ?? 'custom'),
                ),
                const SizedBox(height: 12),
                if (type == 'hydration')
                  TextFormField(
                    initialValue: intervalHours.toString(),
                    decoration: const InputDecoration(labelText: 'Interval hours (e.g., 2)'),
                    keyboardType: TextInputType.number,
                    onChanged: (s) {
                      final parsed = int.tryParse(s) ?? intervalHours;
                      setState(() => intervalHours = parsed);
                    },
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(value: repeatDaily, onChanged: (v) => setState(() => repeatDaily = v ?? true)),
                    const SizedBox(width: 6),
                    const Text('Repeat daily'),
                    const Spacer(),
                    Checkbox(value: enabled, onChanged: (v) => setState(() => enabled = v ?? true)),
                    const SizedBox(width: 6),
                    const Text('Enabled'),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final userId = _user!.uid;
                          final docId = existing?.id ?? '';
                          final rem = Reminder(
                            id: docId,
                            title: titleCtrl.text.trim().isEmpty ? 'Reminder' : titleCtrl.text.trim(),
                            body: bodyCtrl.text.trim(),
                            hour: hour,
                            minute: minute,
                            repeatDaily: repeatDaily,
                            enabled: enabled,
                            type: type,
                            intervalHours: intervalHours,
                          );

                          try {
                            await _service.saveReminder(userId, rem);
                            if (mounted) {
                              Navigator.of(ctx).pop();
                              await _load();
                            }
                          } on FirebaseException catch (fe) {
                            final msg = fe.code == 'permission-denied'
                                ? 'Permission denied: check Firestore rules or ensure you are signed in with the correct account.'
                                : 'Failed to save reminder: ${fe.message ?? fe.code}';
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                            }
                          } catch (e, st) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save reminder: $e')));
                            }
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text('Save', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(Reminder r) {
    final cs = Theme.of(context).colorScheme;
    final leading = _leadingIcon(r.type);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Text(
            leading,
            style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(r.title, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        subtitle: Text('${r.type.toUpperCase()} • ${r.hour.toString().padLeft(2,'0')}:${r.minute.toString().padLeft(2,'0')}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: r.enabled,
              onChanged: (v) async {
                if (_user == null) return;
                try {
                  await _service.toggleReminderEnabled(_user!.uid, r, v);
                  await _load();
                } on FirebaseException catch (fe) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Toggle failed: ${fe.message ?? fe.code}')));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Toggle failed: $e')));
                }
              },
            ),
            IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditor(existing: r)),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                if (_user == null) return;
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (dctx) => AlertDialog(
                    title: const Text('Delete reminder'),
                    content: const Text('Are you sure you want to delete this reminder?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(dctx).pop(false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.of(dctx).pop(true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (ok == true) {
                  try {
                    await _service.deleteReminder(_user!.uid, r.id);
                    await _load();
                  } on FirebaseException catch (fe) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: ${fe.message ?? fe.code}')));
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _leadingIcon(String type) {
    switch (type) {
      case 'hydration':
        return '💧';
      case 'meal':
        return '🍽';
      default:
        return '🔔';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.alarm, size: 80, color: cs.primary),
              const SizedBox(height: 12),
              Text('No reminders yet', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Add meal or hydration reminders so Satwik Diet can notify you at the right time.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _showEditor(),
                icon: const Icon(Icons.add),
                label: const Text('Add first reminder'),
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _items.length,
          itemBuilder: (_, i) => _tile(_items[i]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
