// lib/features/coffee/coffee_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/coffee_api.dart';
import '../../models/coffee_reading.dart';
import 'coffee_payment_screen.dart';

class CoffeeScreen extends StatefulWidget {
  const CoffeeScreen({super.key});

  @override
  State<CoffeeScreen> createState() => _CoffeeScreenState();
}

class _CoffeeScreenState extends State<CoffeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController(text: 'Genel');
  final _questionController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<File> _photos = [];

  bool _loading = false;

  @override
  void dispose() {
    _topicController.dispose();
    _questionController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGalleryMulti() async {
    // Multi image picker (galeri) - desktop/phone destekli
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;

    setState(() {
      for (final x in picked) {
        if (_photos.length >= 5) break;
        _photos.add(File(x.path));
      }
    });
  }

  Future<void> _pickFromCamera() async {
    if (_photos.length >= 5) return;
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null) return;
    setState(() => _photos.add(File(picked.path)));
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_photos.length < 3 || _photos.length > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen 3 ile 5 fotoğraf ekle.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final CoffeeReading reading = await CoffeeApi.start(
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        topic: _topicController.text.trim(),
        question: _questionController.text.trim(),
      );

      await CoffeeApi.uploadPhotos(
        readingId: reading.id,
        imageFiles: _photos,
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CoffeePaymentScreen(readingId: reading.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _photoGrid() {
    if (_photos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Column(
          children: const [
            Icon(Icons.coffee_outlined, size: 48),
            SizedBox(height: 10),
            Text(
              '3-5 foto ekle:\n(1) fincan içi, (2) tabak, (3) üstten',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _photos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, i) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _photos[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: InkWell(
                  onTap: () => _removePhoto(i),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.close, size: 16),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kahve Falı'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _photoGrid(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _pickFromCamera,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Kamera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _pickFromGalleryMulti,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galeri (çoklu)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _topicController,
                    decoration: const InputDecoration(labelText: 'Konu (Aşk/İş/Para/Genel)'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _questionController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Sorun / odak noktan'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'İsim'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Yaş (opsiyonel)'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Fal Başlat (Ödeme Adımına Geç)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
