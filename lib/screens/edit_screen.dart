import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ad.dart';
import '../providers/ad_provider.dart';

class EditAdScreen extends StatefulWidget {
  final Ad ad;
  final String phoneNumber; // Added phoneNumber

  const EditAdScreen({super.key, required this.ad, required this.phoneNumber});

  @override
  _EditAdScreenState createState() => _EditAdScreenState();
}

class _EditAdScreenState extends State<EditAdScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.ad.title);
    _descriptionController = TextEditingController(text: widget.ad.description);
    _priceController =
        TextEditingController(text: widget.ad.price?.toString() ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final adProvider = Provider.of<AdProvider>(context, listen: false);
      try {
        await adProvider.updateAd(
          adId: widget.ad.adId,
          title: _titleController.text,
          description: _descriptionController.text,
          price: _priceController.text.isNotEmpty
              ? int.parse(_priceController.text)
              : null,
          phoneNumber: widget.phoneNumber, // Pass phoneNumber
        );
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('آگهی با موفقیت ویرایش شد')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ویرایش آگهی: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ویرایش آگهی'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان آگهی',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'لطفاً عنوان آگهی را وارد کنید';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'لطفاً توضیحات را وارد کنید';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'قیمت (تومان)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (int.tryParse(value) == null || int.parse(value) < 0) {
                        return 'لطفاً یک عدد معتبر وارد کنید';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('ذخیره تغییرات'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
