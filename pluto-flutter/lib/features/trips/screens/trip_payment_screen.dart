import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/workflow_provider.dart';

class TripPaymentScreen extends ConsumerStatefulWidget {
  final String applicationId;
  final String tripId;
  const TripPaymentScreen({super.key, required this.applicationId, required this.tripId});

  @override
  ConsumerState<TripPaymentScreen> createState() => _TripPaymentScreenState();
}

class _TripPaymentScreenState extends ConsumerState<TripPaymentScreen> {
  final _promoCtrl = TextEditingController();
  bool _success = false;

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyPromo() async {
    final promo = _promoCtrl.text.trim();
    if (promo.isEmpty) return;
    
    try {
      await ref.read(workflowActionProvider.notifier).payWithPromo(widget.applicationId, widget.tripId, promo);
      setState(() => _success = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(workflowActionProvider);

    if (_success) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              Text('You\'re in!', style: PlutoTextStyles.displayMedium),
              const SizedBox(height: 8),
              const Text('Welcome to the trip buddy community! 🎉'),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/trips/${widget.tripId}'),
                child: const Text('Back to Trip Details'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Finalize Joining')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.stars, color: Colors.orange, size: 40),
            const SizedBox(height: 16),
            Text('Travel Buddy Entry', style: PlutoTextStyles.displaySmall),
            const SizedBox(height: 8),
            const Text('To finalize your membership, please pay the entry fee of ₹11 or use a promo code.'),
            const Divider(height: 48),

            const Text('Enter Promo Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _promoCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. NEWAPP',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: actionState.isLoading ? null : _applyPromo,
                ),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 8),
            Text('Use code NEWAPP for a free entry!', style: TextStyle(color: Colors.grey[600], fontSize: 13)),

            const SizedBox(height: 60),
            if (actionState.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PlutoColors.travel,
                  minimumSize: const Size(double.infinity, 54),
                ),
                onPressed: null, // Disabled until payment gateway is added
                child: const Text('Pay ₹11 with UPI/Card (Next Update)', style: TextStyle(color: Colors.white70)),
              ),
          ],
        ),
      ),
    );
  }
}
