import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide typography tokens. Sizes/weights/spacing live here so every
/// screen pulls from the same scale instead of calling [GoogleFonts]
/// inline; color stays with the caller (via [AppColors] or `.copyWith`)
/// so one text role can still render in different colors per screen.
class AppTextStyles {
  AppTextStyles._();

  // Space Grotesk — headings / wordmarks.
  static TextStyle get displayLg => GoogleFonts.spaceGrotesk(
    fontWeight: FontWeight.w700,
    fontSize: 36,
    letterSpacing: -0.7,
  );

  static TextStyle get headingLg => GoogleFonts.spaceGrotesk(
    fontWeight: FontWeight.w700,
    fontSize: 28,
    letterSpacing: -0.28,
  );

  static TextStyle get headingSm => GoogleFonts.spaceGrotesk(
    fontWeight: FontWeight.w700,
    fontSize: 18,
    letterSpacing: -0.36,
  );

  /// Manrope in its default weight/size — for spots that only need the
  /// family locked in (e.g. an input hint) without adopting a full token's
  /// weight/size.
  static TextStyle get manropeBase => GoogleFonts.manrope();

  // Manrope — body copy, labels, controls.
  static TextStyle get tagline => GoogleFonts.manrope(
    fontWeight: FontWeight.w600,
    fontSize: 14,
    letterSpacing: 0.3,
  );

  static TextStyle get subtitle =>
      GoogleFonts.manrope(fontWeight: FontWeight.w500, fontSize: 14, height: 1.5);

  static TextStyle get caption =>
      GoogleFonts.manrope(fontWeight: FontWeight.w500, fontSize: 12, height: 1.5);

  static TextStyle get label => GoogleFonts.manrope(
    fontWeight: FontWeight.w600,
    fontSize: 12,
    letterSpacing: 0.5,
  );

  static TextStyle get overline => GoogleFonts.manrope(
    fontWeight: FontWeight.w600,
    fontSize: 11,
    letterSpacing: 1.5,
  );

  static TextStyle get fieldValue =>
      GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 15);

  static TextStyle get phoneValue =>
      GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 16);

  static TextStyle get buttonLabel =>
      GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 16);

  static TextStyle get linkText =>
      GoogleFonts.manrope(fontWeight: FontWeight.w500, fontSize: 14);

  static TextStyle get linkTextEmphasis =>
      GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14);
}
