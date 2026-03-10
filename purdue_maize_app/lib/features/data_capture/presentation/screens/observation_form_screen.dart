import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/purdue_theme.dart';
import '../../../../core/database/app_database.dart';
import '../../data/observation_repository.dart';
import '../../data/disease_provider.dart';

const _uuid = Uuid();

/// Módulo 2 — Formulario completo de captura de datos.
/// - Dropdown real de enfermedades (diseasesStreamProvider → SQLite cache)
/// - Incidencia / severidad con 3 escalas seleccionables
/// - Contexto agronómico
/// - Imágenes (cámara / galería)
/// - Grabación de audio con package:record + reproducción con just_audio
class ObservationFormScreen extends ConsumerStatefulWidget {
  const ObservationFormScreen({super.key, required this.samplingPointId});
  final String samplingPointId;

  @override
  ConsumerState<ObservationFormScreen> createState() => _ObservationFormScreenState();
}

class _ObservationFormScreenState extends ConsumerState<ObservationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cultivarCtrl = TextEditingController();
  final _stageCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool? _irrigation;
  bool? _fungicide;
  bool _isSaving = false;

  final List<_DiseaseEntry> _entries = [_DiseaseEntry()];
  final List<File> _images = [];

  String? _audioPath; // ruta local del archivo de audio grabado

  @override
  void dispose() {
    _cultivarCtrl.dispose();
    _stageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diseasesAsync = ref.watch(diseasesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva observación'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: PurdueColors.boilermakerGold),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.check), onPressed: _submit, tooltip: 'Guardar'),
        ],
      ),
      body: diseasesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error cargando enfermedades: $e')),
        data: (diseases) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                title: 'Contexto agronómico',
                icon: Icons.grass,
                children: [
                  TextFormField(
                    controller: _cultivarCtrl,
                    decoration: const InputDecoration(labelText: 'Cultivar / variedad'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _stageCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Estadio fenológico',
                      hintText: 'Ej: V6, VT, R1',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _BoolChipRow(
                    label: 'Riego',
                    value: _irrigation,
                    onChange: (v) => setState(() => _irrigation = v),
                  ),
                  const SizedBox(height: 8),
                  _BoolChipRow(
                    label: 'Fungicida aplicado',
                    value: _fungicide,
                    onChange: (v) => setState(() => _fungicide = v),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _SectionCard(
                title: 'Enfermedades',
                icon: Icons.bug_report_outlined,
                trailing: TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar'),
                  onPressed: () => setState(() => _entries.add(_DiseaseEntry())),
                ),
                children: _entries.asMap().entries.map((e) => _DiseaseEntryCard(
                  key: ValueKey(e.key),
                  entry: e.value,
                  index: e.key,
                  diseases: diseases,
                  onRemove: _entries.length > 1 ? () => setState(() => _entries.removeAt(e.key)) : null,
                )).toList(),
              ),

              const SizedBox(height: 16),

              _SectionCard(
                title: 'Evidencia visual',
                icon: Icons.photo_camera_outlined,
                children: [
                  _ImageGrid(
                    images: _images,
                    onAdd: _pickImage,
                    onRemove: (i) => setState(() => _images.removeAt(i)),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _SectionCard(
                title: 'Nota de voz',
                icon: Icons.mic_outlined,
                children: [
                  _AudioRecorderWidget(
                    onRecordingComplete: (path) => setState(() => _audioPath = path),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas generales',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 28),
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Guardar observación'),
                onPressed: _isSaving ? null : _submit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await _askImageSource();
    if (source == null || !mounted) return;
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: source, imageQuality: 85);
    if (xFile != null && mounted) setState(() => _images.add(File(xFile.path)));
  }

  Future<ImageSource?> _askImageSource() => showModalBottomSheet<ImageSource>(
        context: context,
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final validEntries = _entries.where((e) => e.diseaseId != null).toList();
    if (validEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una enfermedad')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final repo = ref.read(observationRepositoryProvider);

    try {
      for (final entry in validEntries) {
        final obs = await repo.saveObservation(
          samplingPointId: widget.samplingPointId,
          diseaseId: entry.diseaseId!,
          incidencePct: double.tryParse(entry.incidenceCtrl.text),
          severityValue: double.tryParse(entry.severityCtrl.text),
          severityScale: entry.severityScale,
          cultivar: _cultivarCtrl.text.isEmpty ? null : _cultivarCtrl.text,
          phenologicalStage: _stageCtrl.text.isEmpty ? null : _stageCtrl.text,
          irrigation: _irrigation,
          fungicideApplied: _fungicide,
          notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
          observedAt: DateTime.now(),
        );

        // Adjuntar imágenes
        for (final img in _images) {
          await repo.attachMedia(
            observationId: obs.id,
            file: img,
            mediaType: 'image',
            mimeType: 'image/jpeg',
          );
        }

        // Adjuntar audio
        if (_audioPath != null) {
          final audioFile = File(_audioPath!);
          if (await audioFile.exists()) {
            await repo.attachMedia(
              observationId: obs.id,
              file: audioFile,
              mediaType: 'audio',
              mimeType: 'audio/m4a',
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Observación guardada — pendiente de sincronización'),
            backgroundColor: PurdueColors.riskLow,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: PurdueColors.riskHigh),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ── DiseaseEntry ───────────────────────────────────────────────────────────────

class _DiseaseEntry {
  int? diseaseId;
  String severityScale = 'percentage';
  final incidenceCtrl = TextEditingController();
  final severityCtrl = TextEditingController();
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.children, this.trailing});
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: PurdueColors.agedGold),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (trailing != null) ...[const Spacer(), trailing!],
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DiseaseEntryCard extends StatefulWidget {
  const _DiseaseEntryCard({
    super.key, required this.entry, required this.index,
    required this.diseases, this.onRemove,
  });
  final _DiseaseEntry entry;
  final int index;
  final List<LocalDisease> diseases;
  final VoidCallback? onRemove;

  @override
  State<_DiseaseEntryCard> createState() => _DiseaseEntryCardState();
}

class _DiseaseEntryCardState extends State<_DiseaseEntryCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PurdueColors.sandstone.withOpacity(0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PurdueColors.dust),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Enfermedad #${widget.index + 1}',
                  style: Theme.of(context).textTheme.labelLarge),
              const Spacer(),
              if (widget.onRemove != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: widget.onRemove,
                  color: PurdueColors.riskHigh,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Dropdown real conectado a diseasesStreamProvider
          DropdownButtonFormField<int>(
            value: widget.entry.diseaseId,
            decoration: const InputDecoration(labelText: 'Enfermedad', isDense: true),
            hint: const Text('Seleccionar...'),
            isExpanded: true,
            items: widget.diseases.map((d) => DropdownMenuItem<int>(
              value: d.id,
              child: Text(d.commonName ?? d.name, overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (v) => setState(() => widget.entry.diseaseId = v),
            validator: (v) => v == null ? 'Selecciona una enfermedad' : null,
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.entry.incidenceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Incidencia (%)', isDense: true, suffixText: '%'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final val = double.tryParse(v);
                    if (val == null || val < 0 || val > 100) return '0–100';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: widget.entry.severityCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Severidad', isDense: true),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          SegmentedButton<String>(
            selected: {widget.entry.severityScale},
            onSelectionChanged: (s) => setState(() => widget.entry.severityScale = s.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: PurdueColors.boilermakerGold,
              selectedForegroundColor: PurdueColors.black,
              textStyle: Theme.of(context).textTheme.labelSmall,
              visualDensity: VisualDensity.compact,
            ),
            segments: const [
              ButtonSegment(value: 'percentage', label: Text('0–100 %')),
              ButtonSegment(value: '1-9', label: Text('1–9')),
              ButtonSegment(value: '1-5', label: Text('1–5')),
            ],
          ),
        ],
      ),
    );
  }
}

class _BoolChipRow extends StatelessWidget {
  const _BoolChipRow({required this.label, required this.value, required this.onChange});
  final String label;
  final bool? value;
  final void Function(bool?) onChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 160,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        FilterChip(
          label: const Text('Sí'),
          selected: value == true,
          onSelected: (_) => onChange(true),
          selectedColor: PurdueColors.boilermakerGold,
          checkmarkColor: PurdueColors.black,
        ),
        const SizedBox(width: 8),
        FilterChip(
          label: const Text('No'),
          selected: value == false,
          onSelected: (_) => onChange(false),
          selectedColor: PurdueColors.dust,
        ),
      ],
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({required this.images, required this.onAdd, required this.onRemove});
  final List<File> images;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [
        ...images.asMap().entries.map((e) => Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(e.value, width: 80, height: 80, fit: BoxFit.cover),
            ),
            Positioned(
              top: 0, right: 0,
              child: GestureDetector(
                onTap: () => onRemove(e.key),
                child: Container(
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        )),
        InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              border: Border.all(color: PurdueColors.dust, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_outlined, color: PurdueColors.agedGold, size: 26),
                SizedBox(height: 4),
                Text('Foto', style: TextStyle(fontSize: 10, color: PurdueColors.steel)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Audio Recorder ─────────────────────────────────────────────────────────────

class _AudioRecorderWidget extends StatefulWidget {
  const _AudioRecorderWidget({required this.onRecordingComplete});
  final void Function(String? path) onRecordingComplete;

  @override
  State<_AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<_AudioRecorderWidget> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _audioPath;
  Duration _elapsed = Duration.zero;

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      setState(() { _isRecording = false; _audioPath = path; });
      widget.onRecordingComplete(path);
    } else {
      if (!await _recorder.hasPermission()) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de micrófono no concedido')),
        );
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/obs_${_uuid.v4()}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
        path: path,
      );
      setState(() { _isRecording = true; _elapsed = Duration.zero; });
      _tickElapsed();
    }
  }

  void _tickElapsed() async {
    while (_isRecording && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (_isRecording && mounted) setState(() => _elapsed += const Duration(seconds: 1));
    }
  }

  Future<void> _togglePlay() async {
    if (_audioPath == null) return;
    if (_isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
    } else {
      await _player.setFilePath(_audioPath!);
      _player.play();
      setState(() => _isPlaying = true);
      _player.playerStateStream.listen((s) {
        if (s.processingState == ProcessingState.completed && mounted) {
          setState(() => _isPlaying = false);
        }
      });
    }
  }

  void _delete() {
    _player.stop();
    if (_audioPath != null) {
      try { File(_audioPath!).deleteSync(); } catch (_) {}
    }
    setState(() { _audioPath = null; _isPlaying = false; _elapsed = Duration.zero; });
    widget.onRecordingComplete(null);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // Estado: audio grabado
    if (_audioPath != null) {
      return Row(
        children: [
          const Icon(Icons.audio_file_outlined, color: PurdueColors.agedGold, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nota de voz grabada', style: Theme.of(context).textTheme.bodyMedium),
                Text(_fmt(_elapsed), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_isPlaying ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                color: PurdueColors.agedGold, size: 30),
            onPressed: _togglePlay,
            tooltip: _isPlaying ? 'Detener' : 'Reproducir',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: PurdueColors.riskHigh),
            onPressed: _delete,
            tooltip: 'Eliminar nota',
          ),
        ],
      );
    }

    // Estado: grabando o sin grabar
    return Row(
      children: [
        ElevatedButton.icon(
          icon: Icon(_isRecording ? Icons.stop : Icons.mic, size: 20),
          label: Text(_isRecording ? 'Detener  ${_fmt(_elapsed)}' : 'Grabar nota de voz'),
          onPressed: _toggleRecord,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isRecording ? PurdueColors.riskHigh : null,
            foregroundColor: _isRecording ? Colors.white : null,
          ),
        ),
        if (_isRecording) ...[
          const SizedBox(width: 12),
          const _Pulse(),
        ],
      ],
    );
  }
}

/// Punto pulsante rojo mientras se graba.
class _Pulse extends StatefulWidget {
  const _Pulse();
  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
    ..repeat(reverse: true);

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _ctrl,
    child: Container(
      width: 10, height: 10,
      decoration: const BoxDecoration(color: PurdueColors.riskHigh, shape: BoxShape.circle),
    ),
  );
}
