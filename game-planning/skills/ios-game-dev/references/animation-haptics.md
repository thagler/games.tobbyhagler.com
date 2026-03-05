# Animation and Haptics

## Animation Stack

- Core gameplay animation: sprite atlases and action timelines.
- Effects: particle systems and targeted shader accents.
- UI/overlay animation: use vector or timeline runtimes only where they do not impact frame pacing.

## Feel Tuning

- Trigger feedback within ~50 ms of meaningful player action.
- Distinguish feedback intensity by event class (light tap, hit confirm, fail, reward).
- Avoid constant high-intensity effects during long loops.

## Haptics

- Use Core Haptics patterns for custom cues.
- Provide graceful fallback on devices without advanced haptics.
- Validate haptic behavior on real hardware; simulator checks are not sufficient for feel tuning.
