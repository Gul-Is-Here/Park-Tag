import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/routes/app_routes.dart';

/// Drives the OCR/RC-card scanner — opened ONLY from the "Add Vehicle"
/// button. Delegates the whole capture step to ML Kit's Document Scanner,
/// which runs as Google Play services' own fullscreen flow: automatic
/// document detection, edge-accurate cropping, rotation correction and
/// shadow/stain removal, then hands back a cropped JPEG. ML Kit text
/// recognition runs afterwards, in [ReviewVehicleController], on that
/// cropped image.
///
/// Android-only by nature — the plugin's iOS side is a stub, so on iOS
/// this screen offers the gallery/manual-entry fallbacks instead (see
/// [isScannerUnavailable]).
///
/// Completely isolated from the QR scanner: no shared imports, no shared
/// state, a different package (`google_mlkit_document_scanner` here vs.
/// `mobile_scanner` there).
class ScanController extends GetxController {
  final _picker = ImagePicker();

  /// True while Google's scanner flow is being launched/running.
  final isLaunching = false.obs;

  /// True when there's no document scanner on this platform (iOS) — the
  /// screen then shows gallery import and manual entry instead.
  final isScannerUnavailable = false.obs;

  final errorMessage = RxnString();

  @override
  void onReady() {
    super.onReady();
    // Launched from onReady rather than onInit so the route transition has
    // settled before Google's activity takes over the screen.
    launchScanner();
  }

  Future<void> launchScanner() async {
    if (!Platform.isAndroid) {
      isScannerUnavailable.value = true;
      return;
    }
    if (isLaunching.value) return;

    isLaunching.value = true;
    errorMessage.value = null;

    final scanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormats: const {DocumentFormat.jpeg},
        pageLimit: 1,
        // `full` enables Google's ML-backed cleanup (shadow/stain removal)
        // plus crop/rotate editing — the cleaner the page, the better the
        // text recognition that runs on it next.
        mode: ScannerMode.full,
        isGalleryImport: true,
      ),
    );

    try {
      final result = await scanner.scanDocument();
      final path = result.images?.isNotEmpty ?? false ? result.images!.first : null;
      if (path == null) {
        errorMessage.value = "That scan didn't produce an image. Please try again.";
        return;
      }
      // offNamed, not toNamed: this screen is just a launcher, so Back from
      // the Review screen should return to the dashboard rather than
      // re-triggering the scanner.
      Get.offNamed(AppRoutes.addVehicleReview, arguments: {'rcCardPath': path});
    } on PlatformException catch (e) {
      // The plugin reports a user cancel as an error, so it has to be told
      // apart from a real failure — backing out of the scanner should just
      // return to the dashboard, not show an error.
      if ((e.message ?? '').toLowerCase().contains('cancel')) {
        Get.back();
        return;
      }
      errorMessage.value = "Couldn't open the scanner. Please try again, or enter the details manually.";
    } on MissingPluginException {
      isScannerUnavailable.value = true;
    } catch (_) {
      errorMessage.value = "Something went wrong while scanning. Please try again.";
    } finally {
      isLaunching.value = false;
      await scanner.close();
    }
  }

  /// Gallery fallback — the same OCR pipeline, just sourced from an
  /// existing photo. The resident is never trapped behind the scanner.
  Future<void> pickFromGallery() async {
    final photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (photo == null) return;
    Get.offNamed(AppRoutes.addVehicleReview, arguments: {'rcCardPath': photo.path});
  }

  void enterManually() {
    Get.offNamed(AppRoutes.addVehicleReview, arguments: const {'rcCardPath': null});
  }
}
