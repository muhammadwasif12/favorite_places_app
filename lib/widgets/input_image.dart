import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class InputImage extends StatefulWidget {
  const InputImage({super.key, required this.onPickedImage});

  final void Function(File image) onPickedImage;
  @override
  State<StatefulWidget> createState() {
    return _InputImageState();
  }
}

class _InputImageState extends State<InputImage> {
  File? _selectedImage;

  void _takePicture() async {
    final imagePicker = ImagePicker();

    final pickedImage = await imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 600,
    );
    if (pickedImage == null) {
      return;
    }
    setState(() {
      _selectedImage = File(pickedImage.path);
    });

    widget.onPickedImage(_selectedImage!);
  }

  @override
  Widget build(BuildContext context) {
    Widget content = TextButton.icon(
      onPressed: _takePicture,
      label: Text("Take Picture"),
      icon: Icon(Icons.camera, size: 20),
    );

    if (_selectedImage != null) {
      setState(() {
        content = GestureDetector(
          onTap: () => _takePicture(),
          child: Image.file(
            _selectedImage!,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            height: double.infinity,
            width: double.infinity,
          ),
        );
      });
    }

    return Container(
      height: 250,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(
          width: 1,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
        ),
      ),
      child: content,
    );
  }
}
