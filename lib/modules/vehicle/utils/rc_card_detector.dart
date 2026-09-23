import 'dart:math' as math;
import 'dart:ui';

/// Live feedback the OCR scanner shows while tracking the RC card against
/// the guide frame (CamScanner-style). Ordered roughly worst-to-best so a
/// caller can treat a later state as "closer to ready".
enum RcDetectionState {
  searching, // Nothing card-shaped in view yet.
  outsideFrame, // Text detected, but not inside the guide box.
  partiallyOutside, // Straddling the guide box edge.
  tooFar, // Inside the box but too small — text too sparse/small.
  tooClose, // Text bounds blow past the guide box.
  tilted, // Bounding shape is skewed beyond a sane aspect ratio.
  fitting, // Inside, sized right, not yet stable.
  ready, // Stable — about to auto-capture.
}

class RcDetectionResult {
  const RcDetectionResult({required this.state, required this.cardRect});

  final RcDetectionState state;

  /// The detected text cluster's bounding box, in image-preview
  /// coordinates, or null when nothing was found. Used to draw a
  /// tracking outline that follows the card.
  final Rect? cardRect;
}

/// Evaluates one frame's recognized-text block boxes against the guide
/// frame and decides where the card stands relative to it. Pure/stateless
/// — stability across frames is tracked by the caller ([RcCardTracker]).
///
/// [textBlockRects] and [guideRect] must already be in the SAME coordinate
/// space (the on-screen "display" orientation) — the caller is
/// responsible for rotating raw camera-sensor boxes into that space first
/// (see `_rotateRectToDisplay` in `ScanController`), since ML Kit returns
/// bounding boxes in the original, un-rotated sensor buffer.
RcDetectionResult evaluateRcCardFrame({
  required List<Rect> textBlockRects,
  required Rect guideRect,
}) {
  if (textBlockRects.isEmpty) {
    return const RcDetectionResult(
      state: RcDetectionState.searching,
      cardRect: null,
    );
  }

  // Merge every text block's box into one cluster — a card/plate is a
  // dense group of nearby text lines, so its union approximates the card.
  Rect? union;
  for (final box in textBlockRects) {
    union = union == null ? box : union.expandToInclude(box);
  }
  if (union == null || union.width <= 0 || union.height <= 0) {
    return const RcDetectionResult(
      state: RcDetectionState.searching,
      cardRect: null,
    );
  }

  final cardRect = union;
  final aspectRatio = cardRect.width / cardRect.height;

  // A card/plate is a wide rectangle; a near-square or very thin sliver of
  // text (e.g. one stray line) isn't the whole document — treat as tilted
  // only once it's already roughly guide-sized, otherwise keep searching.
  final coverageOfGuide =
      _intersectionArea(cardRect, guideRect) /
      guideRect.width /
      guideRect.height;

  if (coverageOfGuide < 0.05) {
    return RcDetectionResult(
      state: RcDetectionState.outsideFrame,
      cardRect: cardRect,
    );
  }

  final containsCard =
      guideRect.contains(Offset(cardRect.left, cardRect.top)) &&
      guideRect.contains(Offset(cardRect.right, cardRect.bottom));

  if (!containsCard && coverageOfGuide < 0.6) {
    return RcDetectionResult(
      state: RcDetectionState.partiallyOutside,
      cardRect: cardRect,
    );
  }

  if (aspectRatio < 1.1 || aspectRatio > 3.4) {
    return RcDetectionResult(
      state: RcDetectionState.tilted,
      cardRect: cardRect,
    );
  }

  final sizeRatio =
      (cardRect.width * cardRect.height) / (guideRect.width * guideRect.height);
  if (sizeRatio < 0.28) {
    return RcDetectionResult(
      state: RcDetectionState.tooFar,
      cardRect: cardRect,
    );
  }
  if (sizeRatio > 1.35) {
    return RcDetectionResult(
      state: RcDetectionState.tooClose,
      cardRect: cardRect,
    );
  }

  return RcDetectionResult(state: RcDetectionState.fitting, cardRect: cardRect);
}

double _intersectionArea(Rect a, Rect b) {
  final left = math.max(a.left, b.left);
  final top = math.max(a.top, b.top);
  final right = math.min(a.right, b.right);
  final bottom = math.min(a.bottom, b.bottom);
  if (right <= left || bottom <= top) return 0;
  return (right - left) * (bottom - top);
}

/// Requires "fitting" for [requiredStableFrames] consecutive analyzed
/// frames before declaring [RcDetectionState.ready] — avoids capturing the
/// instant the card first slides into place, which is usually still
/// mid-motion and blurry.
class RcCardTracker {
  RcCardTracker({this.requiredStableFrames = 6});

  final int requiredStableFrames;
  int _stableCount = 0;

  RcDetectionResult update(RcDetectionResult frame) {
    if (frame.state == RcDetectionState.fitting) {
      _stableCount++;
      if (_stableCount >= requiredStableFrames) {
        return RcDetectionResult(
          state: RcDetectionState.ready,
          cardRect: frame.cardRect,
        );
      }
      return frame;
    }
    _stableCount = 0;
    return frame;
  }

  void reset() => _stableCount = 0;
}

String messageForRcDetectionState(RcDetectionState state) {
  switch (state) {
    case RcDetectionState.searching:
      return 'Point the camera at the RC card';
    case RcDetectionState.outsideFrame:
      return 'Move the card inside the frame';
    case RcDetectionState.partiallyOutside:
      return 'Fit the entire card inside the frame';
    case RcDetectionState.tooFar:
      return 'Move closer';
    case RcDetectionState.tooClose:
      return 'Move slightly back';
    case RcDetectionState.tilted:
      return 'Hold the card straight';
    case RcDetectionState.fitting:
      return 'Hold steady…';
    case RcDetectionState.ready:
      return 'Capturing…';
  }
}
