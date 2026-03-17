import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final faqs = [
      {
        'question': 'How long does delivery take?',
        'answer': 'Most deliveries are completed within 30-60 minutes depending on your location and the store\'s preparation time.'
      },
      {
        'question': 'What are the delivery hours?',
        'answer': 'Delivery hours vary by store and are subject to South African liquor laws. Generally, alcohol delivery is available during legal trading hours.'
      },
      {
        'question': 'Is there a minimum order amount?',
        'answer': 'Yes, most stores have a minimum order amount of R150 to qualify for delivery.'
      },
      {
        'question': 'How do I track my order?',
        'answer': 'Once your order is confirmed, you can track it in real-time from the "Active Orders" section on your dashboard or under the "Orders" tab.'
      },
      {
        'question': 'What if my items are missing or damaged?',
        'answer': 'Please contact our support team immediately through the app or call our hotline. We will investigate and process a refund or replacement as needed.'
      },
      {
        'question': 'Do I need to show my ID?',
        'answer': 'Yes, South African law requires us to verify that the recipient is 18 years or older. Our drivers will ask to see a valid South African ID or Passport upon delivery.'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & FAQ'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: Text(
                faq['question']!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    faq['answer']!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
