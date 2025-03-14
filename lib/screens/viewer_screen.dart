import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key, this.initialModelPath});

  final String? initialModelPath;

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  List<String> _availableModels = [];
  String? _selectedModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableModels();

    if (widget.initialModelPath != null) {
      _selectedModel = widget.initialModelPath;
    }
  }

  Future<void> _loadAvailableModels() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, we would scan a directory for model files
      // For this sample, we'll provide some sample models

      // Simulate loading delay
      await Future.delayed(const Duration(seconds: 1));

      // Sample model files
      final models = [
        'assets/models/example_scan.glb',
        'assets/models/sample_model_1.usdz',
        'assets/models/sample_model_2.glb',
      ];

      if (mounted) {
        setState(() {
          _availableModels = models;

          // Select the first model if none is selected and we have models
          if (_selectedModel == null && models.isNotEmpty) {
            _selectedModel = models.first;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading models: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Model Viewer'),
        centerTitle: true,
        actions: [
          if (_availableModels.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAvailableModels,
              tooltip: 'Refresh models',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availableModels.isEmpty
              ? _buildEmptyState()
              : _buildModelViewer(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.view_in_ar, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No 3D Models Found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a new scan to generate a 3D model',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildModelViewer() {
    return Column(
      children: [
        // Model selector
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedModel,
                  hint: const Text('Select a model'),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedModel = value;
                      });
                    }
                  },
                  items: _availableModels.map((model) {
                    final name = model.split('/').last;
                    return DropdownMenuItem(
                      value: model,
                      child: Text(name),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),

        // Model viewer
        Expanded(
          child: _selectedModel == null
              ? const Center(child: Text('Select a model to view'))
              : Container(
                  color: Colors.black12,
                  padding: const EdgeInsets.all(8.0),
                  child: ModelViewer(
                    backgroundColor: const Color.fromARGB(
                      0xFF,
                      0xEE,
                      0xEE,
                      0xEE,
                    ),
                    src: _selectedModel!,
                    alt: 'A 3D model',
                    ar: true,
                    arModes: const ['scene-viewer', 'webxr', 'quick-look'],
                    autoRotate: true,
                    cameraControls: true,
                    shadowIntensity: 1,
                  ),
                ),
        ),

        // Model controls
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: Icons.open_in_browser,
                label: 'AR View',
                onPressed: () {
                  // In a real app, this would open the AR view of the model
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('AR View not implemented in sample'),
                      ),
                    );
                  }
                },
              ),
              _buildControlButton(
                icon: Icons.share,
                label: 'Share',
                onPressed: () {
                  // In a real app, this would share the model file
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sharing not implemented in sample'),
                      ),
                    );
                  }
                },
              ),
              _buildControlButton(
                icon: Icons.delete,
                label: 'Delete',
                onPressed: () {
                  // In a real app, this would delete the model file
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Delete not implemented in sample'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: Icon(icon), onPressed: onPressed),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
