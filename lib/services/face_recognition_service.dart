// Place this file at: lib/services/face_recognition_service.dart
//
// Wraps google_ml_kit (face *detection*, i.e. finding a face in a frame)
// and tflite_flutter running a MobileFaceNet model (face *recognition*,
// i.e. turning a cropped face into a 192-d embedding vector). The rest
// of the app never touches ML Kit or tflite directly — it just calls:
//
//   FaceRecognitionService.generateEmbeddingFromFile(photoFile)
//   FaceRecognitionService.findBestMatch(embedding, memories)
//
// ─────────────────────────────────────────────────────────────────────
// SETUP CHECKLIST (do this before this file will compile/run):
//
// 1. pubspec.yaml — add dependencies:
//      dependencies:
//        google_mlkit_face_detection: ^0.10.0   # check latest
//        tflite_flutter: ^0.10.4                # check latest
//        image: ^4.2.0                          # check latest
//        camera: ^0.10.5                        # only for live scanning
//
//    NOTE: exact API shapes (InputImage constructors, Interpreter
//    methods, image package's Pixel API) drift between versions. If
//    something here doesn't match what your installed version expects,
//    that's version skew, not a logic error — adjust the call to match
//    your package's current signature.
//
// 2. Get a MobileFaceNet .tflite file (a common, small, on-device face
//    embedding model; 112x112 RGB input, ~192-d output). Place it at:
//      assets/models/mobilefacenet.tflite
//    and register it in pubspec.yaml:
//      flutter:
//        assets:
//          - assets/models/mobilefacenet.tflite
//    Anthropic/Claude did not (and cannot) generate this binary model
//    file for you — download a MobileFaceNet .tflite export from a
//    trusted source, or convert one yourself, then verify its exact
//    input size and output embedding length and adjust `_inputSize`
//    and `_embeddingSize` below to match.
//
// 3. Call `await FaceRecognitionService.init();` once — e.g. in main()
//    right after Hive/PatientDataService are ready — so the model is
//    warm before the patient opens "Who Is This?".
//
// 4. Permissions:
//      Android (android/app/src/main/AndroidManifest.xml):
//        <uses-permission android:name="android.permission.CAMERA"/>
//      iOS (ios/Runner/Info.plist):
//        <key>NSCameraUsageDescription</key>
//        <string>Used to recognize familiar faces for the patient.</string>
// ─────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/memory_model.dart';

/// A memory paired with how confident the match was.
class FaceMatch {
  final MemoryModel memory;
  final double similarity; // cosine similarity in [-1, 1], 1 = identical
  const FaceMatch(this.memory, this.similarity);
}

class FaceRecognitionService {
  FaceRecognitionService._();

  static const int _inputSize = 112; // MobileFaceNet input: 112x112 RGB
  static const int _embeddingSize = 192; // adjust to match your model

  /// Cosine-similarity cutoff to call something a match. This is a
  /// starting point, not a guarantee — test with real patient photos
  /// under real lighting and tune up/down (higher = stricter).
  static const double matchThreshold = 0.60;

  static Interpreter? _interpreter;
  static FaceDetector? _detector;

  static bool get isReady => _interpreter != null && _detector != null;

  static Future<void> init() async {
    if (isReady) return;
    _interpreter = await Interpreter.fromAsset(
      'assets/models/mobilefacenet.tflite',
    );
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.15,
      ),
    );
  }

  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _detector?.close();
    _detector = null;
  }

  // ---------------------------------------------------------------------
  // Embedding from a still photo — used both when a caregiver adds a
  // memory (photo -> embedding, stored once) and when the patient scans
  // (captured frame -> embedding, compared live).
  // ---------------------------------------------------------------------

  /// Detects the (largest) face in [imageFile], crops it, and returns
  /// its embedding. Returns null if no face was found. Call [init]
  /// first — this throws a StateError otherwise.
  static Future<List<double>?> generateEmbeddingFromFile(File imageFile) async {
    _assertReady();

    final inputImage = InputImage.fromFile(imageFile);
    final faces = await _detector!.processImage(inputImage);
    if (faces.isEmpty) return null;

    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    final face = _largestFace(faces);
    final cropped = _cropToFace(decoded, face.boundingBox);
    return _embed(cropped);
  }

  // ---------------------------------------------------------------------
  // Comparing embeddings
  // ---------------------------------------------------------------------

  static double cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0, normA = 0, normB = 0;
    for (var i = 0; i < a.length && i < b.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0;
    return dot / (math.sqrt(normA) * math.sqrt(normB));
  }

  /// Compares [queryEmbedding] against every memory that has a stored
  /// embedding for this patient and returns the closest one — but only
  /// if it clears [matchThreshold]. Returns null otherwise (i.e. "no
  /// match", not "best guess").
  static FaceMatch? findBestMatch(
    List<double> queryEmbedding,
    List<MemoryModel> memories,
  ) {
    FaceMatch? best;
    for (final memory in memories) {
      if (!memory.hasFaceEmbedding) continue;
      final similarity = cosineSimilarity(queryEmbedding, memory.faceEmbedding!);
      if (best == null || similarity > best.similarity) {
        best = FaceMatch(memory, similarity);
      }
    }
    if (best == null || best.similarity < matchThreshold) return null;
    return best;
  }

  // ---------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------

  static void _assertReady() {
    if (!isReady) {
      throw StateError(
        'FaceRecognitionService.init() must complete before use.',
      );
    }
  }

  static Face _largestFace(List<Face> faces) {
    final sorted = [...faces]
      ..sort((a, b) {
        final areaA = a.boundingBox.width * a.boundingBox.height;
        final areaB = b.boundingBox.width * b.boundingBox.height;
        return areaB.compareTo(areaA);
      });
    return sorted.first;
  }

  static img.Image _cropToFace(img.Image source, ui.Rect box) {
    final x = box.left.clamp(0, source.width - 1).toInt();
    final y = box.top.clamp(0, source.height - 1).toInt();
    final w = box.width.clamp(1, source.width - x).toInt();
    final h = box.height.clamp(1, source.height - y).toInt();
    final cropped = img.copyCrop(source, x: x, y: y, width: w, height: h);
    return img.copyResize(cropped, width: _inputSize, height: _inputSize);
  }

  /// Runs MobileFaceNet on a 112x112 face crop and returns the
  /// L2-normalized embedding (so cosine similarity == dot product).
  static List<double> _embed(img.Image face) {
    final input = _toInputTensor(face);
    final output = [List.filled(_embeddingSize, 0.0)];
    _interpreter!.run(input, output);

    final raw = output[0];
    var norm = 0.0;
    for (final v in raw) {
      norm += v * v;
    }
    norm = math.sqrt(norm);
    if (norm == 0) return raw;
    return raw.map((v) => v / norm).toList();
  }

  /// [1, 112, 112, 3] float tensor, values scaled to roughly [-1, 1] —
  /// the normalization MobileFaceNet was trained with. If your model
  /// expects [0, 1] or [0, 255] instead, adjust this formula.
  static List<List<List<List<double>>>> _toInputTensor(img.Image face) {
    return [
      List.generate(_inputSize, (y) {
        return List.generate(_inputSize, (x) {
          final pixel = face.getPixel(x, y);
          return [
            (pixel.r - 127.5) / 128.0,
            (pixel.g - 127.5) / 128.0,
            (pixel.b - 127.5) / 128.0,
          ];
        });
      }),
    ];
  }

  // ---------------------------------------------------------------------
  // Optional: live-stream variant, if you later want continuous scanning
  // instead of tap-to-capture-a-still-frame. Not wired into
  // FaceScanPage by default because takePicture() is far simpler and
  // plenty fast for a "point and tap" flow.
  // ---------------------------------------------------------------------

  static Future<List<double>?> generateEmbeddingFromCameraImage(
    CameraImage cameraImage,
    CameraDescription cameraDescription,
  ) async {
    _assertReady();

    final rotation = InputImageRotationValue.fromRawValue(
          cameraDescription.sensorOrientation,
        ) ??
        InputImageRotation.rotation0deg;
    final format = InputImageFormatValue.fromRawValue(cameraImage.format.raw);
    if (format == null) return null;

    final plane = cameraImage.planes.first;
    final inputImage = InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: ui.Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );

    final faces = await _detector!.processImage(inputImage);
    if (faces.isEmpty) return null;

    final rgb = _yuv420ToImage(cameraImage);
    if (rgb == null) return null;

    final face = _largestFace(faces);
    final cropped = _cropToFace(rgb, face.boundingBox);
    return _embed(cropped);
  }

  /// Manual YUV420 -> RGB conversion. Correct but not fast — fine for
  /// an occasional still capture, not for processing every frame.
  static img.Image? _yuv420ToImage(CameraImage cameraImage) {
    try {
      final width = cameraImage.width;
      final height = cameraImage.height;
      final yPlane = cameraImage.planes[0];
      final uPlane = cameraImage.planes[1];
      final vPlane = cameraImage.planes[2];
      final uvRowStride = uPlane.bytesPerRow;
      final uvPixelStride = uPlane.bytesPerPixel ?? 1;

      final out = img.Image(width: width, height: height);
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
          final yIndex = y * yPlane.bytesPerRow + x;

          final yValue = yPlane.bytes[yIndex];
          final uValue = uPlane.bytes[uvIndex];
          final vValue = vPlane.bytes[uvIndex];

          final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
          final g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
              .clamp(0, 255)
              .toInt();
          final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

          out.setPixelRgb(x, y, r, g, b);
        }
      }
      return out;
    } catch (_) {
      return null;
    }
  }
}