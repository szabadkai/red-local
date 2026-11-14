#!/usr/bin/env python3
"""Summarise how a C64 tune uses its three SID voices, from a register-write log.

Input: the c64 harness's --sid-log format, one write per line:
    cycle frame line rasterCycle reg value      (reg/value hex)
Usage: sidscan.py LOG [--window FRAMES]
"""
import collections
import math
import sys

CLOCK = 985248  # PAL
NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
WAVE = {0: '-', 1: 'tri', 2: 'saw', 3: 'tri+saw', 4: 'pulse', 5: 'tri+pulse', 6: 'saw+pulse',
        7: 'tsp', 8: 'noise'}


def midi(freq_reg):
    if freq_reg == 0:
        return None
    hz = freq_reg * CLOCK / 16777216
    return 69 + 12 * math.log2(hz / 440)


def name(m):
    if m is None:
        return '--'
    n = round(m)
    return f'{NAMES[n % 12]}{n // 12 - 1}'


def wave(ctrl):
    w = WAVE.get(ctrl >> 4, f'w{ctrl >> 4:x}')
    mods = ''.join(c for bit, c in ((2, 's'), (4, 'r'), (8, 't')) if ctrl & bit)
    return w + ('/' + mods if mods else '')


def load(path):
    frames = collections.defaultdict(list)
    for line in open(path):
        p = line.split()
        if len(p) != 6 or not p[0].isdigit():
            continue
        frames[int(p[1])].append((int(p[4], 16), int(p[5], 16)))
    return frames


def scan(path, window):
    frames = load(path)
    first, last = min(frames), max(frames)
    reg = [0] * 32
    notes = [[] for _ in range(3)]  # per voice: dicts
    cur = [None] * 3
    filt = []
    vol_writes = 0
    ctrl_writes = collections.Counter()
    for f in range(first, last + 1):
        gate_on = [False] * 3
        for r, v in frames.get(f, ()):
            if r < 21 and r % 7 == 4:
                ctrl_writes[f] += 1
                if v & 1 and not reg[r] & 1:
                    gate_on[r // 7] = True
            if r == 0x18:
                vol_writes += 1
            reg[r] = v
        for v in range(3):
            b = v * 7
            snap = dict(freq=reg[b] | reg[b + 1] << 8, pw=(reg[b + 2] | reg[b + 3] << 8) & 0xFFF,
                        ctrl=reg[b + 4], ad=reg[b + 5], sr=reg[b + 6])
            if gate_on[v] or cur[v] is None:
                cur[v] = dict(start=f, frames=[])
                notes[v].append(cur[v])
            cur[v]['frames'].append(snap)
        filt.append(dict(cut=reg[0x16] << 3 | reg[0x15] & 7, res=reg[0x17] >> 4, route=reg[0x17] & 7,
                         mode=reg[0x18] >> 4, vol=reg[0x18] & 15))

    nframes = last - first + 1
    print(f'{path}\nframes {first}-{last} ({nframes / 50:.1f} s), {sum(len(w) for w in frames.values())} writes')
    per = collections.Counter(ctrl_writes.values())
    print('control-register writes per frame (count: frames):', dict(sorted(per.items())))
    print(f'$D418 writes per frame: {vol_writes / nframes:.1f}')

    for v in range(3):
        inst = collections.defaultdict(list)
        for n in notes[v]:
            fr = n['frames']
            if not any(s['ctrl'] & 0xF0 for s in fr):
                continue
            sig = ' '.join(wave(s['ctrl']) for s in fr[:4])
            inst[(sig, fr[0]['ad'], fr[0]['sr'])].append(n)
        print(f'\n== voice {v + 1}: {sum(len(x) for x in inst.values())} notes, {len(inst)} instruments')
        for (sig, ad, sr), ns in sorted(inst.items(), key=lambda kv: -len(kv[1])):
            lens = sorted(len(n['frames']) for n in ns)
            pitches = [midi(s['freq']) for n in ns for s in n['frames'] if s['freq']]
            # pitch movement inside notes: semitone jumps per frame (arpeggio) vs small wobble (vibrato)
            jumps = wob = steps = 0
            pwmod = 0
            for n in ns:
                ms = [midi(s['freq']) for s in n['frames']]
                for a, b in zip(ms, ms[1:]):
                    if a is None or b is None:
                        continue
                    steps += 1
                    d = abs(a - b)
                    jumps += d >= 0.9
                    wob += 0.02 < d < 0.9
                pws = {s['pw'] for s in n['frames']}
                pwmod += len(pws) > 2
            tags = []
            if steps and jumps / steps > 0.25:
                tags.append(f'arp {jumps / steps:.0%}')
            if steps and wob / steps > 0.15:
                tags.append(f'vib/slide {wob / steps:.0%}')
            if 'pulse' in sig and pwmod / len(ns) > 0.3:
                tags.append('pwm')
            lo, hi = (name(min(pitches)), name(max(pitches))) if pitches else ('--', '--')
            print(f'  {len(ns):4d}x  [{sig:<42}] AD={ad:02X} SR={sr:02X}  len med {lens[len(lens) // 2]:3d}f'
                  f'  {lo}..{hi}  {", ".join(tags)}')

    routed = collections.Counter(x['route'] for x in filt)
    modes = collections.Counter(x['mode'] & 7 for x in filt)
    cuts = [x['cut'] for x in filt]
    moves = sum(a != b for a, b in zip(cuts, cuts[1:]))
    print('\n== filter')
    print('  routing (bit0=v1 bit1=v2 bit2=v3), frames:', dict(routed.most_common()))
    print('  mode (1=LP 2=BP 4=HP), frames:', dict(modes.most_common()))
    print(f'  cutoff {min(cuts)}..{max(cuts)} of 2047, changes on {moves / max(1, len(cuts) - 1):.0%} of frames')
    print('  resonance:', dict(collections.Counter(x['res'] for x in filt).most_common(4)))

    print(f'\n== timeline, {window}-frame windows: notes per voice / distinct instruments')
    for w0 in range(first, last + 1, window):
        row = []
        for v in range(3):
            ns = [n for n in notes[v] if w0 <= n['start'] < w0 + window and any(s['ctrl'] & 0xF0 for s in n['frames'])]
            kinds = {(' '.join(wave(s['ctrl']) for s in n['frames'][:4]), n['frames'][0]['ad']) for n in ns}
            row.append(f'v{v + 1} {len(ns):3d}/{len(kinds)}')
        print(f'  {w0 / 50:6.1f}s  ' + '   '.join(row))


if __name__ == '__main__':
    win = int(sys.argv[sys.argv.index('--window') + 1]) if '--window' in sys.argv else 400
    scan(sys.argv[1], win)
