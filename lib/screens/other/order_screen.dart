import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final Map<String, dynamic> specialist;

  const OrderScreen({
    super.key,
    required this.service,
    required this.specialist,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _commentController = TextEditingController();

  String? _selectedDuration = '1 час';
  bool _isSubmitting = false;

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _addressController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Необходимо войти в аккаунт')),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    final serviceId = widget.service['id'] as int?;
    final specialistId = widget.specialist['id'] as String?;

    if (serviceId == null || specialistId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка: недостаточно данных об услуге или мастере'),
        ),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      final comment = _commentController.text.trim();
      final duration = _selectedDuration ?? 'Не указано';
      final address = _addressController.text.trim();
      final date = _dateController.text.trim();
      final time = _timeController.text.trim();

      final contractDetails = {
        'address': address,
        'preferred_date': date,
        'preferred_time': time,
        'duration': duration,
        if (comment.isNotEmpty) 'comment': comment,
      };

      await supabase.from('orders').insert({
        'user_id': userId,
        'specialist_id': specialistId,
        'service_id': serviceId,
        'status': 'pending',
        'contract_details': contractDetails,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заказ успешно создан! Мастер свяжется с вами.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при создании заказа: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceName = widget.service['name'] as String? ?? 'Услуга';
    final price = widget.service['price'] as num?;
    final specialistName = widget.specialist['display_name'] ?? 'Мастер';

    return Scaffold(
      appBar: AppBar(title: const Text('Оформление заказа'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Мастер: $specialistName'),
                      const SizedBox(height: 4),
                      if (price != null)
                        Text(
                          'Цена: $price BYN',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        const Text(
                          'Цена: по договорённости',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Адрес выполнения',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Улица, дом, квартира, подъезд',
                ),
                validator: (v) =>
                    v?.trim().isEmpty ?? true ? 'Укажите адрес' : null,
              ),
              const SizedBox(height: 24),

              const Text(
                'Желаемая дата и время',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Дата',
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 1),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null && mounted) {
                          _dateController.text =
                              '${date.day.toString().padLeft(2, '0')}.'
                              '${date.month.toString().padLeft(2, '0')}.${date.year}';
                        }
                      },
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Выберите дату' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _timeController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Время',
                        suffixIcon: const Icon(Icons.access_time),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null && mounted) {
                          _timeController.text = time.format(context);
                        }
                      },
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Выберите время' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Примерная продолжительность',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedDuration,
                items: ['1 час', '2 часа', '3 часа', '4+ часа', 'Другое']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDuration = v),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Дополнительный комментарий',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Подробности, особые пожелания, материалы и т.д.',
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitOrder,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _isSubmitting ? 'Создание заказа...' : 'Подтвердить заказ',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: Text(
                  'После подтверждения мастер получит уведомление и свяжется с вами',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
