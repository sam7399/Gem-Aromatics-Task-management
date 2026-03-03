import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../../org/providers/org_provider.dart';

class TaskCreatePage extends ConsumerStatefulWidget {
  const TaskCreatePage({super.key});

  @override
  ConsumerState<TaskCreatePage> createState() => _TaskCreatePageState();
}

class _TaskCreatePageState extends ConsumerState<TaskCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _priority = 'normal';
  int? _assignedTo;
  int? _departmentId;
  int? _locationId;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 3));
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final data = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'priority': _priority,
      'assigned_to': _assignedTo,
      'department_id': _departmentId,
      'location_id': _locationId,
      'due_date': _dueDate.toIso8601String(),
    };

    final ok = await ref.read(taskProvider.notifier).createTask(data);
    if (mounted) {
      if (ok) {
        context.go('/tasks');
      } else {
        setState(() {
          _loading = false;
          _error = 'Failed to create task. Please check all fields.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(allUsersProvider).maybeWhen(data: (d) => d, orElse: () => <OrgItem>[]);
    final depts = ref.watch(departmentsProvider(null)).maybeWhen(data: (d) => d, orElse: () => <OrgItem>[]);
    final locs = ref.watch(locationsProvider(null)).maybeWhen(data: (d) => d, orElse: () => <OrgItem>[]);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                    onPressed: () => context.go('/tasks'),
                    icon: const Icon(Icons.arrow_back)),
                const SizedBox(width: 8),
                Text('Create Task',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              constraints: const BoxConstraints(maxWidth: 700),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8)
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Title *',
                          border: OutlineInputBorder()),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),

                    // Priority
                    DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder()),
                      items: ['low', 'normal', 'high', 'urgent']
                          .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(
                                  p[0].toUpperCase() + p.substring(1))))
                          .toList(),
                      onChanged: (v) => setState(() => _priority = v!),
                    ),
                    const SizedBox(height: 16),

                    // Assign To
                    DropdownButtonFormField<int>(
                      value: _assignedTo,
                      decoration: const InputDecoration(
                          labelText: 'Assign To *',
                          border: OutlineInputBorder()),
                      isExpanded: true,
                      items: users
                          .map((u) => DropdownMenuItem(
                              value: u.id, child: Text(u.name, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) => setState(() => _assignedTo = v),
                      validator: (v) =>
                          v == null ? 'Please select a user' : null,
                    ),
                    const SizedBox(height: 16),

                    // Department & Location
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _departmentId,
                            decoration: const InputDecoration(
                                labelText: 'Department *',
                                border: OutlineInputBorder()),
                            isExpanded: true,
                            items: depts
                                .map((d) => DropdownMenuItem(
                                    value: d.id,
                                    child: Text(d.name,
                                        overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _departmentId = v),
                            validator: (v) =>
                                v == null ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _locationId,
                            decoration: const InputDecoration(
                                labelText: 'Location *',
                                border: OutlineInputBorder()),
                            isExpanded: true,
                            items: locs
                                .map((l) => DropdownMenuItem(
                                    value: l.id,
                                    child: Text(l.name,
                                        overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _locationId = v),
                            validator: (v) =>
                                v == null ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Due Date
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                          'Due Date: ${DateFormat('MMM dd, yyyy').format(_dueDate)}'),
                      onPressed: _pickDate,
                      style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14)),
                    ),
                    const SizedBox(height: 24),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(_error!,
                            style: TextStyle(
                                color: Colors.red.shade700, fontSize: 13)),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                            onPressed: () => context.go('/tasks'),
                            child: const Text('Cancel')),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Text('Create Task'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
