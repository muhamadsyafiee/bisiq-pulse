"""Generate original offline cue tones (16-bit mono PCM WAV, no dependencies)."""
import math
from pathlib import Path
import struct
import wave

OUTPUT = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
CUES = {
    'countdown': [(880, .11)],
    'start': [(660, .12), (990, .24)],
    'rest': [(660, .16), (440, .26)],
    'finished': [(660, .15), (830, .15), (990, .35)],
}
OUTPUT.mkdir(parents=True, exist_ok=True)
for name, notes in CUES.items():
    samples = []
    for frequency, duration in notes:
        count = int(44100 * duration)
        for i in range(count):
            fade = min(1, i / 220, (count - 1 - i) / 440)
            samples.append(int(11000 * fade * math.sin(2 * math.pi * frequency * i / 44100)))
        samples.extend([0] * 1764)
    with wave.open(str(OUTPUT / f'{name}.wav'), 'wb') as output:
        output.setparams((1, 2, 44100, 0, 'NONE', 'not compressed'))
        output.writeframes(struct.pack(f'<{len(samples)}h', *samples))
