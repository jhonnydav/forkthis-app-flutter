# Onboarding And Home Hero Design QA

## Evidence

- Source visual truth: `/var/folders/46/150tzjb937v3lq2kmpm43zzw0000gn/T/codex-clipboard-502a4571-a11d-4628-9e65-94c22aed6beb.png`
- Onboarding step 1: `/private/tmp/nutrition-onboarding-1-final.png`
- Onboarding step 2: `/private/tmp/nutrition-onboarding-2-final.png`
- Onboarding step 3: `/private/tmp/nutrition-onboarding-3-final.png`
- Home hero annotation iteration: `/private/tmp/nutrition-home-half-hero-final.png`
- Combined comparison: `/private/tmp/nutrition-onboarding-home-comparison.jpg`
- Source pixels: 1199 x 588.
- Implementation captures: 498 x 1044 each at browser output density 1x.
- Comparison sheet: 1200 x 1208.
- State: onboarding intro steps 1–3 and completed-onboarding Home.

The source is a palette and illustration-direction board rather than a screen
layout. Color dominance, illustration language, texture, image energy, and crop
quality were compared directly. Product spacing, typography, and interaction were
evaluated against the existing Flutter design system.

## Findings

- No actionable P0, P1, or P2 findings remain.
- Each onboarding promise now has a distinct, relevant visual rather than a reused
  icon tile. All three share the supplied orange, yellow, and red poster language.
- The Home illustration occupies half of the usable viewport above fixed
  navigation. The safe-area greeting and action content use separate off-white
  bands, preserving a clear hierarchy without covering the artwork.
- Standard screen canvases use the shared off-white background. Full-bleed brand
  imagery is reserved for Splash; Home uses a bounded edge-to-edge image band.
- Shared elevated, filled, outlined, and text buttons use stadium shapes;
  shared icon buttons are circular. Touch targets remain large and borderless.
- Final browser console check returned no warnings or errors.

## Required Fidelity Surfaces

- Fonts and typography: Archivo Black remains reserved for campaign-scale headings;
  Manrope handles body copy and controls. All final captures wrap cleanly.
- Spacing and layout rhythm: onboarding uses 24 px side padding, a stable image
  ratio, clear copy gaps, and a fixed bottom action. Home uses an off-white header,
  a half-viewport image, and a separate off-white action band.
- Colors and visual tokens: off-white is the standard canvas; lava red, neon orange,
  and margarine yellow dominate imagery and actions as required.
- Image quality and asset fidelity: all four custom JPEG assets are sharp, correctly
  cropped, free of embedded copy, and loaded from the Flutter asset bundle.
- Copy and content: existing onboarding promises and Home value proposition remain
  intact, with the Home supporting sentence tightened for the full-screen layout.

## Interaction And Accessibility Checks

- Onboarding `Next` advanced from `?step=1` to `?step=2` in the browser.
- Home `Find my restaurant order` opened `#/eat-out` in the browser.
- Primary buttons are at least 56 px high; the Home CTA is 60 px high.
- Text and icons remain high contrast against off-white, lava red, and yellow.
- Flutter large-text smoke coverage passed for Home and all primary product routes.
- Browser warnings/errors after the final clean load: none.

## Comparison History

1. Initial implementation passed layout and image loading checks but inactive
   progress segments were too similar to completed segments, and generated images
   retained small baked corner mattes. Classified P2.
2. Progress was remapped to lava red on a neutral border color. Each onboarding
   illustration was cropped and resampled, then versioned with a new asset filename.
3. The Flutter asset manifest was rebuilt. Captures showed distinct progress,
   clean corners, fixed actions, and the earlier full-height Home hero without
   overlap.
4. Browser annotation feedback requested a shorter Home image and fully rounded
   controls. The hero was split into three stable bands, its image was reduced to
   half the usable viewport, and shared controls were changed to stadium/circle
   shapes. The primary Home action still routes to `#/eat-out`.

## Follow-up Polish

- No P3 follow-up is required for this request.

## Final Result

final result: passed
