// mobile/lib/features/hand/hand_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/hand_reading.dart';
import '../../services/device_id_service.dart';
import '../../services/hand_api.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/mystic_scaffold.dart';
import 'hand_payment_screen.dart';

class HandScreen extends StatefulWidget {
  const HandScreen({super.key});

  @override
  State<HandScreen> createState() => _HandScreenState();
}

class _HandScreenState extends State<HandScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController(text: 'Genel');
  final _questionController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  String? _dominantHand; // right/left
  String? _photoHand; // right/left

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
    final picked = await _picker.pickMultiImage(imageQuality: 88);
    if (picked.isEmpty) return;

    setState(() {
      for (final x in picked) {
        if (_photos.length >= 3) break;
        _photos.add(File(x.path));
      }
    });
  }

  Future<void> _pickFromCamera() async {
    if (_photos.length >= 3) return;
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 88);
    if (picked == null) return;
    setState(() => _photos.add(File(picked.path)));
  }

  void _removePhoto(int index) => setState(() => _photos.removeAt(index));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_photos.length < 1 || _photos.length > 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen 1 ile 3 el fotoğrafı ekle.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // ✅ device id tek sefer al, tüm çağrılarda kullan
      final deviceId = await DeviceIdService.getOrCreate();

      // 1) start
      final HandReading reading = await HandApi.start(
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        topic: _topicController.text.trim(),
        question: _questionController.text.trim(),
        dominantHand: _dominantHand,
        photoHand: _photoHand,
        deviceId: deviceId,
      );

      // 2) upload (backend validasyon burada patlayabilir)
      await HandApi.uploadImages(
        readingId: reading.id,
        files: _photos,
        deviceId: deviceId,
      );

      if (!mounted) return;

      // 3) ödeme ekranı
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => HandPaymentScreen(readingId: reading.id)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _photoArea() {
    if (_photos.isEmpty) {
      return GlassCard(
        child: Column(
          children: const [
            Icon(Icons.pan_tool_alt_outlined, size: 44, color: Colors.white),
            SizedBox(height: 10),
            Text(
              '1-3 foto ekle:\n(avuç içi net, ışık iyi, çizgiler görünür)',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _photos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, i) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_photos[i], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: InkWell(
                  onTap: () => _removePhoto(i),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _handPickers() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('El Bilgisi (yorum kalitesi için)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _dominantHand,
                  decoration: const InputDecoration(labelText: 'Baskın el (opsiyonel)'),
                  items: const [
                    DropdownMenuItem(value: 'right', child: Text('Sağ el')),
                    DropdownMenuItem(value: 'left', child: Text('Sol el')),
                  ],
                  onChanged: (v) => setState(() => _dominantHand = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _photoHand,
                  decoration: const InputDecoration(labelText: 'Fotoğraftaki el (opsiyonel)'),
                  items: const [
                    DropdownMenuItem(value: 'right', child: Text('Sağ el')),
                    DropdownMenuItem(value: 'left', child: Text('Sol el')),
                  ],
                  onChanged: (v) => setState(() => _photoHand = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MysticScaffold(
      scrimOpacity: 0.82,
      patternOpacity: 0.18,
      appBar: AppBar(title: const Text('El Falı')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _photoArea(),
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
            _handPickers(),
            const SizedBox(height: 18),
            GlassCard(
              child: Form(
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
            ),
            const SizedBox(height: 18),
            GradientButton(
              text: _loading ? 'Yükleniyor...' : 'Fal Başlat (Ödeme Adımına Geç)',
              onPressed: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
