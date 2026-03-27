import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/trip_provider.dart';

class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({super.key});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _startDate, _endDate;
  int _groupSize = 4;
  double _entryFee = 0;
  String? _category;
  bool _loading = false;
  int _step = 0;

  final _categories = [
    'Adventure',
    'Cultural',
    'Leisure',
    'Wildlife',
    'Beach',
    'Mountains'
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(createTripProvider.notifier).create(
            title: _titleCtrl.text,
            destination: _destCtrl.text,
            description: _descCtrl.text,
            startDate: _startDate!,
            endDate: _endDate!,
            maxMembers: _groupSize,
            entryFeeInr: _entryFee,
            category: _category,
          );
      if (mounted) context.go('/trips');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to create trip: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: Text('Create Trip', style: PlutoTextStyles.headlineSmall),
        actions: [
          if (_step < 2)
            TextButton(
              onPressed: () => setState(() => _step++),
              child: const Text('Next',
                  style: TextStyle(
                      color: PlutoColors.travel,
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step indicator
              Row(
                children: List.generate(
                    3,
                    (i) => Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                            decoration: BoxDecoration(
                              color: i <= _step
                                  ? PlutoColors.travel
                                  : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        )),
              ),
              const SizedBox(height: 24),

              if (_step == 0) ...[
                Text('Where are you going?',
                    style: PlutoTextStyles.headlineLarge),
                const SizedBox(height: 20),

                // Destination
                TextFormField(
                  controller: _destCtrl,
                  decoration: const InputDecoration(
                    prefixIcon:
                        Icon(Icons.location_on, color: PlutoColors.travel),
                    hintText: 'Search destination (e.g. Manali, Bali)',
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),

                Text('When?', style: PlutoTextStyles.headlineSmall),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _DatePicker(
                      label: 'Start Date',
                      date: _startDate,
                      onPicked: (d) => setState(() => _startDate = d),
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _DatePicker(
                      label: 'End Date',
                      date: _endDate,
                      onPicked: (d) => setState(() => _endDate = d),
                    )),
                  ],
                ),
              ],

              if (_step == 1) ...[
                Text('Tell us the plan', style: PlutoTextStyles.headlineLarge),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                      hintText: 'Trip title (e.g. Rishikesh Rafting Weekend)'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                      hintText:
                          'Describe your itinerary, activities, and what kind of travel buddies you\'re looking for...'),
                ),
                const SizedBox(height: 16),
                Text('Category', style: PlutoTextStyles.titleLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories
                      .map((c) => ChoiceChip(
                            label: Text(c),
                            selected: _category == c,
                            selectedColor: PlutoColors.travel,
                            labelStyle: TextStyle(
                              color: _category == c ? Colors.white : null,
                              fontFamily: 'Outfit',
                            ),
                            onSelected: (_) => setState(() => _category = c),
                          ))
                      .toList(),
                ),
              ],

              if (_step == 2) ...[
                Text('Group Details', style: PlutoTextStyles.headlineLarge),
                const SizedBox(height: 20),

                Text('Group size', style: PlutoTextStyles.titleMedium),
                const SizedBox(height: 4),
                Text('Maximum fellow travelers',
                    style:
                        PlutoTextStyles.bodySmall.copyWith(color: Colors.grey)),
                const SizedBox(height: 12),

                Row(
                  children: [
                    const Spacer(),
                    IconButton(
                      onPressed: () => setState(() {
                        if (_groupSize > 2) _groupSize--;
                      }),
                      icon: const Icon(Icons.remove_circle_outline,
                          color: PlutoColors.travel, size: 30),
                    ),
                    const SizedBox(width: 12),
                    Text('$_groupSize', style: PlutoTextStyles.headlineLarge),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => setState(() {
                        if (_groupSize < 50) _groupSize++;
                      }),
                      icon: const Icon(Icons.add_circle,
                          color: PlutoColors.travel, size: 30),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 20),

                // Entry fee
                Row(
                  children: [
                    const Icon(Icons.currency_rupee,
                        color: PlutoColors.travel, size: 20),
                    const SizedBox(width: 8),
                    Text('Entry fee', style: PlutoTextStyles.titleMedium),
                    const Spacer(),
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        initialValue: '${_entryFee.toInt()}',
                        onChanged: (v) => _entryFee = double.tryParse(v) ?? 0,
                        decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: PlutoColors.travel),
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : const Text('Publish Trip ✈️',
                            style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                fontSize: 16)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onPicked;
  const _DatePicker(
      {required this.label, required this.date, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: PlutoColors.travel),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: PlutoTextStyles.bodySmall.copyWith(color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: PlutoColors.travel),
                const SizedBox(width: 6),
                Text(
                  date != null
                      ? '${date!.day}/${date!.month}/${date!.year}'
                      : 'Pick date',
                  style: PlutoTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
