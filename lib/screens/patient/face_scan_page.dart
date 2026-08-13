// Place this file at:
// lib/screens/patient/face_scan_page.dart

import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import '../../models/memory_model.dart';
import '../../services/patient_data_service.dart';
import '../../services/face_recognition_service.dart';

enum _ScanState {
  idle,
  scanning,
  matched,
  noMatch,
  error,
}

class FaceScanPage extends StatefulWidget {
  const FaceScanPage({super.key});

  @override
  State<FaceScanPage> createState() => _FaceScanPageState();
}

class _FaceScanPageState extends State<FaceScanPage> {
  _ScanState state = _ScanState.idle;

  String? errorMessage;
  FaceMatch? result;

  List<CameraDescription> _cameras = [];
  CameraController? _controller;

  CameraLensDirection _lensDirection =
      CameraLensDirection.back;

  Future<void>? _initFuture;

  bool _isSwitchingCamera = false;

  @override
  void initState() {
    super.initState();

    _initFuture = _setupCamera();
  }

  // ===========================================================================
  // CAMERA SETUP
  // ===========================================================================

  Future<void> _setupCamera() async {
    try {
      _cameras = await availableCameras();

      debugPrint(
        'Available cameras: '
        '${_cameras.map((camera) => camera.lensDirection).toList()}',
      );

      if (_cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      final camera = _cameras.firstWhere(
        (camera) =>
            camera.lensDirection == _lensDirection,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
      });
    } catch (e) {
      debugPrint('Camera setup error: $e');

      if (!mounted) return;

      setState(() {
        state = _ScanState.error;
        errorMessage =
            "Couldn't access the camera. "
            "Check camera permission and try again.";
      });
    }
  }

  // ===========================================================================
  // CHECK BOTH CAMERAS
  // ===========================================================================

  bool get _hasBothCameras {
    final hasFront = _cameras.any(
      (camera) =>
          camera.lensDirection ==
          CameraLensDirection.front,
    );

    final hasBack = _cameras.any(
      (camera) =>
          camera.lensDirection ==
          CameraLensDirection.back,
    );

    return hasFront && hasBack;
  }

  // ===========================================================================
  // SWITCH CAMERA
  // ===========================================================================

  Future<void> _switchCamera() async {
    if (_isSwitchingCamera) return;

    if (!_hasBothCameras) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This device does not have both front and back cameras.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSwitchingCamera = true;
    });

    try {
      // Store the old controller.
      final oldController = _controller;

      // Remove it from the widget first.
      if (mounted) {
        setState(() {
          _controller = null;
        });
      } else {
        _controller = null;
      }

      // Completely dispose the old camera before
      // opening the new camera.
      await oldController?.dispose();

      // Switch direction.
      _lensDirection =
          _lensDirection == CameraLensDirection.back
              ? CameraLensDirection.front
              : CameraLensDirection.back;

      debugPrint(
        'Switching camera to: $_lensDirection',
      );

      // Initialize the new camera.
      await _setupCamera();
    } catch (e) {
      debugPrint('Camera switch error: $e');

      if (!mounted) return;

      setState(() {
        state = _ScanState.error;
        errorMessage =
            "Couldn't switch camera. Please try again.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSwitchingCamera = false;
        });
      }
    }
  }

  // ===========================================================================
  // DISPOSE CAMERA
  // ===========================================================================

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // ===========================================================================
  // START FACE SCAN
  // ===========================================================================

  Future<void> _startScan() async {
    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    setState(() {
      state = _ScanState.scanning;
      errorMessage = null;
      result = null;
    });

    try {
      if (!FaceRecognitionService.isReady) {
        await FaceRecognitionService.init();
      }

      final shot = await controller.takePicture();

      final embedding =
          await FaceRecognitionService
              .generateEmbeddingFromFile(
        File(shot.path),
      );

      if (embedding == null) {
        if (!mounted) return;

        setState(() {
          state = _ScanState.noMatch;
        });

        return;
      }

      final patientId =
          PatientDataService.getActivePatientId();

      final memories = patientId == null
          ? <MemoryModel>[]
          : PatientDataService.getMemories(patientId);

      final match =
          FaceRecognitionService.findBestMatch(
        embedding,
        memories,
      );

      if (!mounted) return;

      setState(() {
        result = match;

        state = match != null
            ? _ScanState.matched
            : _ScanState.noMatch;
      });
    } catch (e) {
      debugPrint('Face scan error: $e');

      if (!mounted) return;

      setState(() {
        state = _ScanState.error;
        errorMessage =
            'Something went wrong. Please try again.';
      });
    }
  }

  // ===========================================================================
  // RESET SCAN
  // ===========================================================================

  void _reset() {
    setState(() {
      state = _ScanState.idle;
      result = null;
      errorMessage = null;
    });
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Who Is This?',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).maybePop();
          },
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // =================================================================
            // CAMERA AREA
            // =================================================================

            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // -----------------------------------------------------------
                  // CAMERA PREVIEW
                  // -----------------------------------------------------------

                  FutureBuilder<void>(
                    future: _initFuture,
                    builder: (context, snapshot) {
                      final controller = _controller;

                      if (controller == null ||
                          !controller.value.isInitialized) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.grey.shade900,
                                Colors.black,
                              ],
                            ),
                          ),
                          child: _isSwitchingCamera
                              ? const Center(
                                  child:
                                      CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        );
                      }

                      return CameraPreview(
                        controller,
                      );
                    },
                  ),

                  // -----------------------------------------------------------
                  // FACE FRAME
                  // -----------------------------------------------------------

                  Center(
                    child: Container(
                      width: 280,
                      height: 340,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              state == _ScanState.matched
                                  ? AppColors.success
                                  : Colors.white
                                      .withOpacity(0.7),
                          width: 3,
                        ),
                        borderRadius:
                            BorderRadius.circular(170),
                      ),
                    ),
                  ),

                  // -----------------------------------------------------------
                  // SCANNING INDICATOR
                  // -----------------------------------------------------------

                  if (state == _ScanState.scanning)
                    const Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child:
                                CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Scanning…',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // -----------------------------------------------------------
                  // SWITCH CAMERA BUTTON
                  // -----------------------------------------------------------

                  Positioned(
                    top: 16,
                    right: 16,
                    child: SafeArea(
                      bottom: false,
                      child: GestureDetector(
                        onTap: _isSwitchingCamera
                            ? null
                            : _switchCamera,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color:
                                Colors.black.withOpacity(0.45),
                            shape: BoxShape.circle,
                          ),
                          child: _isSwitchingCamera
                              ? const Padding(
                                  padding:
                                      EdgeInsets.all(12),
                                  child:
                                      CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Icon(
                                  Icons
                                      .flip_camera_ios_rounded,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // =================================================================
            // BOTTOM PANEL
            // =================================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                24,
                24,
                24,
                32,
              ),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: _buildBottomPanel(context),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BOTTOM PANEL
  // ===========================================================================

  Widget _buildBottomPanel(BuildContext context) {
    switch (state) {
      case _ScanState.matched:
        if (result == null) {
          return const SizedBox.shrink();
        }

        return _MatchResult(
          memory: result!.memory,
          onScanAgain: _reset,
        );

      case _ScanState.noMatch:
        return _NoMatchResult(
          onScanAgain: _reset,
        );

      case _ScanState.error:
        return _ErrorResult(
          message:
              errorMessage ??
              'Something went wrong.',
          onRetry: () {
            _reset();

            setState(() {
              _initFuture = _setupCamera();
            });
          },
        );

      case _ScanState.idle:
      case _ScanState.scanning:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Point the camera at the person's face "
              "and tap scan.",
              textAlign: TextAlign.center,
              style:
                  Theme.of(context).textTheme.bodyLarge,
            ),

            const SizedBox(height: 20),

            BigPrimaryButton(
              label: state == _ScanState.scanning
                  ? 'Scanning…'
                  : 'Scan Face',
              icon: Icons.camera_alt_rounded,
              color: AppColors.danger,
              onTap:
                  state == _ScanState.scanning
                      ? () {}
                      : _startScan,
            ),
          ],
        );
    }
  }
}

// =============================================================================
// MATCH RESULT
// =============================================================================

class _MatchResult extends StatefulWidget {
  final MemoryModel memory;
  final VoidCallback onScanAgain;

  const _MatchResult({
    required this.memory,
    required this.onScanAgain,
  });

  @override
  State<_MatchResult> createState() =>
      _MatchResultState();
}

class _MatchResultState extends State<_MatchResult> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    _audioPlayer.onPlayerStateChanged.listen(
      (playerState) {
        if (!mounted) return;

        setState(() {
          _isPlaying =
              playerState == PlayerState.playing;
        });
      },
    );
  }

  // ===========================================================================
  // PLAY / STOP VOICE INFO
  // ===========================================================================

  Future<void> _playInfo() async {
    final voicePath =
        widget.memory.voiceNotePath;

    // No voice recording saved.
    if (voicePath == null ||
        voicePath.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No voice information is available '
            'for this person.',
          ),
        ),
      );

      return;
    }

    final file = File(voicePath);

    // Voice file no longer exists.
    if (!await file.exists()) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The saved voice recording could not '
            'be found.',
          ),
        ),
      );

      return;
    }

    try {
      // Stop currently playing audio.
      if (_isPlaying) {
        await _audioPlayer.stop();
        return;
      }

      // Play the saved local recording.
      await _audioPlayer.play(
        DeviceFileSource(voicePath),
      );
    } catch (e) {
      debugPrint(
        'Error playing voice information: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not play the voice information.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photoPath = widget.memory.photoPath;

    final hasPhoto =
        photoPath != null &&
        File(photoPath).existsSync();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ---------------------------------------------------------------------
        // PERSON INFORMATION
        // ---------------------------------------------------------------------

        Row(
          children: [
            hasPhoto
                ? ClipRRect(
                    borderRadius:
                        BorderRadius.circular(16),
                    child: Image.file(
                      File(photoPath!),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  )
                : const IconBadge(
                    icon: Icons.face_rounded,
                    color: AppColors.accent,
                    background:
                        AppColors.accentLight,
                    size: 72,
                  ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons
                            .check_circle_rounded,
                        color:
                            AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Match found',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium,
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  Text(
                    widget.memory.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium,
                  ),

                  Text(
                    widget.memory.relation,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ---------------------------------------------------------------------
        // PLAY INFO
        // ---------------------------------------------------------------------

        Row(
          children: [
            Expanded(
              child: BigPrimaryButton(
                label: _isPlaying
                    ? 'Stop Info'
                    : 'Play Info',
                icon: _isPlaying
                    ? Icons.stop_rounded
                    : Icons.volume_up_rounded,
                color: AppColors.primary,
                onTap: _playInfo,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ---------------------------------------------------------------------
        // SCAN AGAIN
        // ---------------------------------------------------------------------

        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: widget.onScanAgain,
            child: const Text(
              'Scan Again',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// NO MATCH RESULT
// =============================================================================

class _NoMatchResult extends StatelessWidget {
  final VoidCallback onScanAgain;

  const _NoMatchResult({
    required this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.help_outline_rounded,
          color: AppColors.textSecondary,
          size: 48,
        ),

        const SizedBox(height: 12),

        Text(
          "We couldn't find a match for this person.",
          textAlign: TextAlign.center,
          style:
              Theme.of(context).textTheme.bodyLarge,
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: BigPrimaryButton(
            label: 'Scan Again',
            icon: Icons.camera_alt_rounded,
            color: AppColors.danger,
            onTap: onScanAgain,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// ERROR RESULT
// =============================================================================

class _ErrorResult extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorResult({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style:
              Theme.of(context).textTheme.bodyLarge,
        ),

        const SizedBox(height: 16),

        BigPrimaryButton(
          label: 'Try Again',
          icon: Icons.refresh_rounded,
          color: AppColors.danger,
          onTap: onRetry,
        ),
      ],
    );
  }
}