import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ad.dart';
import '../providers/ad_provider.dart';

class EditAdScreen extends StatefulWidget {
  final Ad ad;
  final String phoneNumber;

  const EditAdScreen({super.key, required this.ad, required this.phoneNumber});

  @override
  _EditAdScreenState createState() => _EditAdScreenState();
}
class _EditAdScreenState extends State<EditAdScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _depositController; // Added for RENT ads
  late TextEditingController _monthlyRentController; // Added for RENT ads

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.ad.title);
    _descriptionController = TextEditingController(text: widget.ad.description);
    _priceController = TextEditingController(
      text: widget.ad.adType == 'REAL_ESTATE' && widget.ad.realEstateType == 'SALE'
          ? widget.ad.totalPrice?.toString() ?? ''
          : widget.ad.adType == 'VEHICLE'
              ? widget.ad.basePrice?.toString() ?? ''
              : widget.ad.price?.toString() ?? '',
    );
    _depositController = TextEditingController(
      text: widget.ad.adType == 'REAL_ESTATE' && widget.ad.realEstateType == 'RENT'
          ? widget.ad.deposit?.toString() ?? ''
          : '',
    );
    _monthlyRentController = TextEditingController(
      text: widget.ad.adType == 'REAL_ESTATE' && widget.ad.realEstateType == 'RENT'
          ? widget.ad.monthlyRent?.toString() ?? ''
          : '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _depositController.dispose(); // Added
    _monthlyRentController.dispose(); // Added
    super.dispose();
  }
Future<void> _submit() async {
  if (_formKey.currentState!.validate()) {
    // Validate realEstateType for REAL_ESTATE ads
    if (widget.ad.adType == 'REAL_ESTATE' && widget.ad.realEstateType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نوع آگهی املاک (فروش یا اجاره) مشخص نشده است')),
      );
      return;
    }

    final adProvider = Provider.of<AdProvider>(context, listen: false);
    try {
      await adProvider.updateAd(
        adId: widget.ad.adId,
        title: _titleController.text,
        description: _descriptionController.text,
        price: widget.ad.adType == 'VEHICLE' ? int.parse(_priceController.text) : null,
        totalPrice: widget.ad.adType == 'REAL_ESTATE' && widget.ad.realEstateType == 'SALE'
            ? int.parse(_priceController.text)
            : null,
        deposit: widget.ad.adType == 'REAL_ESTATE' && widget.ad.realEstateType == 'RENT'
            ? int.parse(_depositController.text)
            : null,
        monthlyRent: widget.ad.adType == 'REAL_ESTATE' && widget.ad.realEstateType == 'RENT'
            ? int.parse(_monthlyRentController.text)
            : null,
        phoneNumber: widget.phoneNumber,
        adType: widget.ad.adType,
        realEstateType: widget.ad.adType == 'REAL_ESTATE' ? widget.ad.realEstateType : null, // Ensure realEstateType is passed
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('آگهی با موفقیت ویرایش شد')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ویرایش آگهی: $e')),
        );
      }
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ویرایش آگهی', style: TextStyle(fontFamily: 'Vazir')),
        centerTitle: true,
        backgroundColor: Colors.red,
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
                    labelStyle: TextStyle(fontFamily: 'Vazir'),
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
                    labelStyle: TextStyle(fontFamily: 'Vazir'),
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
                if (widget.ad.adType != 'REAL_ESTATE' || widget.ad.realEstateType == 'SALE') ...[
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: widget.ad.adType == 'REAL_ESTATE'
                          ? 'قیمت کل (تومان)'
                          : widget.ad.adType == 'VEHICLE'
                              ? 'قیمت پایه (تومان)'
                              : 'قیمت (تومان)',
                      labelStyle: const TextStyle(fontFamily: 'Vazir'),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'لطفاً قیمت را وارد کنید';
                      }
                      final parsedPrice = int.tryParse(value);
                      if (parsedPrice == null || parsedPrice < 0) {
                        return 'لطفاً یک عدد معتبر و غیرمنفی وارد کنید';
                      }
                      return null;
                    },
                  ),
                ],
                if (widget.ad.adType == 'REAL_ESTATE' && widget.ad.realEstateType == 'RENT') ...[
                  TextFormField(
                    controller: _depositController,
                    decoration: const InputDecoration(
                      labelText: 'ودیعه (تومان)',
                      labelStyle: TextStyle(fontFamily: 'Vazir'),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'لطفاً مبلغ ودیعه را وارد کنید';
                      }
                      final parsedDeposit = int.tryParse(value);
                      if (parsedDeposit == null || parsedDeposit < 0) {
                        return 'لطفاً یک عدد معتبر و غیرمنفی وارد کنید';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _monthlyRentController,
                    decoration: const InputDecoration(
                      labelText: 'اجاره ماهیانه (تومان)',
                      labelStyle: TextStyle(fontFamily: 'Vazir'),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'لطفاً مبلغ اجاره ماهیانه را وارد کنید';
                      }
                      final parsedRent = int.tryParse(value);
                      if (parsedRent == null || parsedRent < 0) {
                        return 'لطفاً یک عدد معتبر و غیرمنفی وارد کنید';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text(
                    'ذخیره تغییرات',
                    style: TextStyle(fontFamily: 'Vazir', color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}