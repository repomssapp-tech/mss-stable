import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/voice/recorded_transcription_service.dart';
import '../../../utils/app_spacing.dart';

class ReviewedVoiceInput {
  const ReviewedVoiceInput(this.text, this.language);
  final String text;
  final String language;
}

/// Records a bounded clip in memory. Only reviewed text reaches the assistant.
class RecordedVoiceDialog extends StatefulWidget {
  const RecordedVoiceDialog({
    super.key,
    required this.service,
    this.initialLanguage = 'en-IN',
    this.initialText = '',
    this.recorder,
    this.onSend,
  });
  final RecordedTranscriptionService service;
  final String initialLanguage;
  final String initialText;
  final AudioRecorder? recorder;
  final Future<void> Function(ReviewedVoiceInput)? onSend;

  @override
  State<RecordedVoiceDialog> createState() => _RecordedVoiceDialogState();
}

class _RecordedVoiceDialogState extends State<RecordedVoiceDialog>
    with WidgetsBindingObserver {
  late final AudioRecorder _recorder = widget.recorder ?? AudioRecorder();
  final _text = TextEditingController();
  final _chunks = BytesBuilder(copy: false);
  StreamSubscription<Uint8List>? _subscription;
  Timer? _limit;
  Uint8List? _audio;
  late String _language;
  String? _handle;
  String? _jobLanguage;
  bool _recording = false;
  bool _busy = false;
  bool _sending = false;
  bool _error = false;
  int _generation = 0;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage;
    _text.text = widget.initialText;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _recording) {
      unawaited(_stop(transcribe: false));
    }
  }

  Future<void> _start() async {
    if (_busy || _recording) return;
    setState(() {
      _busy = true;
      _error = false;
    });
    try {
      if (!await _recorder.hasPermission()) {
        throw StateError('Microphone permission required');
      }
      if (!mounted) return;
      _chunks.clear();
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          echoCancel: true,
          noiseSuppress: true,
        ),
      );
      if (!mounted) {
        await _recorder.stop();
        return;
      }
      _subscription = stream.listen(
        (chunk) {
          // Native callbacks may arrive after the timer; keep memory bounded too.
          final remaining = 1920000 - _chunks.length;
          if (remaining > 0) {
            _chunks.add(
              chunk.length > remaining ? chunk.sublist(0, remaining) : chunk,
            );
          }
          if (_chunks.length >= 1920000 && _recording) unawaited(_stop());
        },
        onError: (Object _) {
          unawaited(_stop(transcribe: false));
        },
      );
      _limit = Timer(const Duration(seconds: 60), () => unawaited(_stop()));
      setState(() {
        _recording = true;
        _busy = false;
        _audio = null;
        _handle = null;
        _text.clear();
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = true;
        });
      }
    }
  }

  Future<void> _stop({bool transcribe = true}) async {
    if (!_recording) return;
    _limit?.cancel();
    setState(() {
      _recording = false;
      _busy = true;
    });
    try {
      await _recorder.stop();
      // stop() has flushed the recorder. Cancel callbacks immediately without
      // waiting on platform stream teardown before starting the upload.
      unawaited(_subscription?.cancel());
      _subscription = null;
      _audio = _chunks.takeBytes();
      if (!mounted) return;
      setState(() => _busy = false);
      if (transcribe) await _transcribe();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = true;
        });
      }
    }
  }

  Future<void> _transcribe() async {
    if (_busy || _audio == null) return;
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _error = false;
    });
    try {
      // Retry polling an existing job after network failure. A language change
      // creates a new job from the same clip, without asking the user to repeat.
      if (_handle == null || _jobLanguage != _language) {
        _handle = await widget.service.submit(_audio!, _language);
        _jobLanguage = _language;
      }
      final deadline = DateTime.now().add(const Duration(minutes: 5));
      while (mounted && generation == _generation) {
        final result = await widget.service.poll(_handle!);
        if (!mounted || generation != _generation) return;
        if (result.phase == TranscriptionPhase.completed) {
          setState(() {
            _text.text = result.transcript;
            _busy = false;
          });
          return;
        }
        if (result.phase != TranscriptionPhase.pending) {
          _handle = null;
          throw StateError('No transcript');
        }
        if (DateTime.now().isAfter(deadline)) {
          throw TimeoutException('Transcription pending');
        }
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _busy = false;
          _error = true;
        });
      }
    }
  }

  @override
  void dispose() {
    ++_generation;
    WidgetsBinding.instance.removeObserver(this);
    _limit?.cancel();
    unawaited(_subscription?.cancel());
    unawaited(_recorder.dispose());
    _audio = null;
    _chunks.clear();
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final input = ReviewedVoiceInput(_text.text.trim(), _language);
    setState(() {
      _busy = true;
      _sending = true;
      _error = false;
    });
    try {
      await widget.onSend?.call(input);
      if (mounted) Navigator.of(context).pop(input);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _sending = false;
          _error = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_sending,
      child: AlertDialog(
        title: Text(_l10n.voiceRecordTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_l10n.voiceRecordDisclosure),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _language,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: _l10n.voiceSpokenLanguage,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'en-IN',
                    child: Text('English'), // i18n-ok: language autonym
                  ),
                  DropdownMenuItem(
                    value: 'ta-IN',
                    child: Text('தமிழ்'), // i18n-ok: language autonym
                  ),
                  DropdownMenuItem(
                    value: 'hi-IN',
                    child: Text('हिन्दी'), // i18n-ok: language autonym
                  ),
                  DropdownMenuItem(
                    value: 'mr-IN',
                    child: Text('मराठी'), // i18n-ok: language autonym
                  ), // i18n-ok: language autonym
                ],
                onChanged: _busy || _recording
                    ? null
                    : (value) => setState(() {
                        _language = value!;
                        _text.clear();
                      }),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_busy) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: AppSpacing.sm),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _sending
                        ? _l10n.voiceSendReviewed
                        : _l10n.voiceTranscribingClip,
                  ),
                ),
                if (!_sending)
                  TextButton(
                    onPressed: () => setState(() {
                      ++_generation;
                      _busy = false;
                    }),
                    child: Text(_l10n.voiceTypeInstead),
                  ),
              ],
              if (_recording)
                Semantics(
                  liveRegion: true,
                  child: Text(_l10n.voiceRecordingClip),
                ),
              if (_error)
                Semantics(liveRegion: true, child: Text(_l10n.voiceClipError)),
              if (!_recording) ...[
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _text,
                  minLines: 2,
                  maxLines: 6,
                  maxLength: 2000,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    labelText: _l10n.voiceReviewTranscript,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : _recording
                    ? _stop
                    : _start,
                icon: Icon(_recording ? Icons.stop : Icons.mic),
                label: Text(
                  _recording
                      ? _l10n.voiceStopAndTranscribe
                      : _l10n.voiceRecordClip,
                ),
              ),
              if (_audio != null && !_recording)
                TextButton(
                  onPressed: _busy ? null : _transcribe,
                  child: Text(_l10n.voiceRetryClip),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _sending ? null : () => Navigator.of(context).pop(),
            child: Text(_l10n.dialogCancel),
          ),
          FilledButton(
            onPressed:
                _busy ||
                    _recording ||
                    _text.text.trim().isEmpty ||
                    _text.text.trim().length > 2000
                ? null
                : _send,
            child: Text(_l10n.voiceSendReviewed),
          ),
        ],
      ),
    );
  }
}
