// Chiptune synth. Two ways to voice a channel:
//   - NES/VRC6 style: channel names pulse1-4, tri, saw, noise1-2 pick a fixed waveform.
//   - C64 SID style: `inst` definitions with per-frame tables, selected in MML with @name.
// Node:    node chip.js song.mml [out.wav]
// Browser: <script src="chip.js"> then Chip.play(text, audioContext)
//
// Song text, one statement per line (';' starts a comment):
//   tempo 116 | swing 56 (16th swing, 50 = straight) | bars 24 (fixed length) | loop 2
//   meter 3 (quarter-note beats per bar, default 4; 3 for 3/4 and 6/8)
//   drive 2 (master saturation: louder and denser at the same peak; 0 = clean, default 2)
//   <channel>: <mml>     repeated lines append; any name works, the prefixes above set a waveform
//   $name: <mml>         macro, used as $name inside channels or other macros
//   inst <name> key=value ...   instrument; tables step once per 1/60 s frame:
//       wave=n,p        waveform per frame (p pulse, s saw, t tri, n noise), last one holds
//       arp=12,0|0,4,7  semitone offset per frame; the part after | loops, else last holds
//       pw=50 | pw=15-60/1.5    pulse width %, fixed or sweeping back and forth at %/frame
//       adsr=0,10,9,2   attack frames, decay frames, sustain 0-15, release frames
//       vib=0.25        vibrato depth in semitones (starts 0.25 s into the note)
//       slide=-7/14     start 7 semitones low and glide to pitch over 14 frames
//       detune=8        cents
//       ring=2.76       ring-modulate with a square at 2.76x the pitch (bells, metal)
//       filter=lp|bp|hp  cut=800 | cut=250-1800/25 (free-running sweep, Hz/frame)
//                        | cut=2400>300/80 (per-note sweep)  res=0..1
// MML: c d e f g a b (+/# sharp, - flat), r rest, optional length (4 = quarter, 8. = dotted
// eighth), o4 octave, > < octave up/down, l8 default length, v0-15 volume, @0-3 duty
// (12.5/25/50/75 %), @name instrument, q1-8 gate (note sounds for q/8 of its length),
// {ceg}4 arpeggio cycling at 60 Hz, [ ... ]4 repeat (nestable), | bar line (checked
// against the meter, otherwise ignored).
// noise* channels without an instrument: k kick, s snare, c clap, h closed hat, p open hat.
(function (root) {
  const SR = 44100, OS = 4, FRAME = 1 / 60;
  const DUTY = [0.125, 0.25, 0.5, 0.75];
  const DRUMS = { // noise clock Hz (0 = pitched kick), decay s, gain
    k: [0, 0.11, 1.5], s: [5500, 0.1, 1], c: [3500, 0.08, 1], h: [16000, 0.025, 0.55], p: [16000, 0.12, 0.55],
  };
  const SEMI = { c: 0, d: 2, e: 4, f: 5, g: 7, a: 9, b: 11 };
  const GAIN = { pulse: 0.13, saw: 0.12, tri: 0.32, noise: 0.25 };
  const WAVES = { p: 'pulse', s: 'saw', t: 'tri', n: 'noise' };
  const TRI = Array.from({ length: 32 }, (_, i) => (i < 16 ? 15 - i : i - 16) / 7.5 - 1);

  const nums = (s) => s.split(',').filter(Boolean).map(Number);
  const bounce = (lo, hi, rate, t) => {
    const span = hi - lo;
    if (span <= 0 || !rate) return lo;
    const x = (t * rate) % (2 * span);
    return lo + (x < span ? x : 2 * span - x);
  };

  function parseInst(name, spec) {
    const inst = { wave: ['pulse'], arp: [0], loop: [], pw: [0.5, 0.5, 0], adsr: [0, 0, 15, 0], vib: 0, slide: [0, 0], detune: 0, ring: 0, filter: null, cut: [800, 800, 0, false], res: 0.5 };
    for (const kv of spec.trim().split(/\s+/)) {
      const [k, v = ''] = kv.split('=');
      let m;
      if (k === 'wave' && v.split(',').every((w) => WAVES[w])) inst.wave = v.split(',').map((w) => WAVES[w]);
      else if (k === 'arp') { const [pre, loop = ''] = v.split('|'); inst.arp = nums(pre); inst.loop = nums(loop); }
      else if (k === 'pw' && (m = /^([\d.]+)(?:-([\d.]+)\/([\d.]+))?$/.exec(v))) inst.pw = [m[1] / 100, (m[2] ?? m[1]) / 100, (m[3] ?? 0) / 100];
      else if (k === 'adsr' && nums(v).length === 4) inst.adsr = nums(v);
      else if (k === 'vib') inst.vib = +v;
      else if (k === 'detune') inst.detune = +v;
      else if (k === 'ring') inst.ring = +v;
      else if (k === 'slide' && (m = /^(-?[\d.]+)\/([\d.]+)$/.exec(v))) inst.slide = [+m[1], +m[2]];
      else if (k === 'filter' && /^(lp|bp|hp)$/.test(v)) inst.filter = v;
      else if (k === 'cut' && (m = /^([\d.]+)(?:([->])([\d.]+)\/([\d.]+))?$/.exec(v))) inst.cut = [+m[1], +(m[3] ?? m[1]), +(m[4] ?? 0), m[2] === '>'];
      else if (k === 'res') inst.res = +v;
      else throw new Error(`inst ${name}: bad setting '${kv}'`);
    }
    return inst;
  }

  function parseSong(text) {
    const song = { tempo: 120, swing: 50, bars: 0, meter: 4, drive: 2, loop: 1, channels: {}, insts: {} };
    const macros = {};
    for (const raw of text.toLowerCase().split('\n')) {
      const line = raw.replace(/;.*/, '').trim();
      if (!line) continue;
      const opt = /^(tempo|swing|bars|meter|drive|loop)\s+([\d.]+)$/.exec(line);
      if (opt) { song[opt[1]] = +opt[2]; continue; }
      const inst = /^inst\s+(\w+)\s+(.*)$/.exec(line);
      if (inst) { song.insts[inst[1]] = parseInst(inst[1], inst[2]); continue; }
      const def = /^(\$\w+|[a-z]\w*)\s*:(.*)$/.exec(line);
      if (!def) throw new Error(`bad line: ${line}`);
      const into = def[1][0] === '$' ? macros : song.channels;
      into[def[1]] = (into[def[1]] || '') + ' ' + def[2];
    }
    for (const name in song.channels) {
      let mml = song.channels[name];
      for (let depth = 0; mml.includes('$'); depth++) {
        if (depth > 16) throw new Error(`${name}: macros nest too deep`);
        mml = mml.replace(/\$\w+/g, (m) => {
          if (!(m in macros)) throw new Error(`${name}: unknown macro ${m}`);
          return macros[m];
        });
      }
      song.channels[name] = mml;
    }
    return song;
  }

  function parseChannel(mml, name, insts) {
    const rep = /\[([^\[\]]*)\](\d+)/;
    while (rep.test(mml)) mml = mml.replace(rep, (_, body, n) => (body + ' ').repeat(+n));
    const ev = [], marks = [];
    let i = 0, t = 0, oct = 4, len = 4, vol = 12, duty = 2, q = 7, inst = null;
    const match = (re) => {
      re.lastIndex = i;
      const m = re.exec(mml);
      if (!m) return null;
      i = re.lastIndex;
      return m[0];
    };
    const num = () => { const m = match(/\d+/y); return m === null ? null : +m; };
    const beats = () => {
      let b = 4 / (num() ?? len);
      if (mml[i] === '.') { i++; b *= 1.5; }
      return b;
    };
    const pitch = (c) => {
      let p = 12 * (oct + 1) + SEMI[c];
      for (; mml[i] === '+' || mml[i] === '#' || mml[i] === '-'; i++) p += mml[i] === '-' ? -1 : 1;
      return p;
    };
    while (i < mml.length) {
      const c = mml[i++];
      const drums = !inst && name.startsWith('noise');
      if (drums && DRUMS[c]) { const d = beats(); ev.push({ t, d, drum: c, vol, q: 8 }); t += d; }
      else if (!drums && c in SEMI) { const notes = [pitch(c)], d = beats(); ev.push({ t, d, notes, vol, duty, q, inst }); t += d; }
      else if (!drums && c === '{') {
        const save = oct, notes = [];
        while (i < mml.length && mml[i] !== '}') {
          const k = mml[i++];
          if (k in SEMI) notes.push(pitch(k)); else if (k === '>') oct++; else if (k === '<') oct--;
        }
        i++; oct = save;
        const d = beats();
        if (notes.length) ev.push({ t, d, notes, vol, duty, q, inst });
        t += d;
      }
      else if (c === 'r') t += beats();
      else if (c === 'o') oct = num();
      else if (c === '>') oct++;
      else if (c === '<') oct--;
      else if (c === 'l') len = num();
      else if (c === 'v') vol = num();
      else if (c === 'q') q = num();
      else if (c === '@') {
        const id = match(/[a-z_]\w*/y);
        if (id === null) { duty = num(); inst = null; }
        else if (!insts[id]) throw new Error(`${name}: unknown instrument @${id}`);
        else inst = insts[id];
      }
      else if (c === '|') marks.push(t);
      else if (!/\s/.test(c)) throw new Error(`${name}: unexpected '${c}'`);
    }
    return { ev, beats: t, marks };
  }

  function envAt([a, d, s], t) {
    const ta = a * FRAME, sus = s / 15;
    if (t < ta) return t / ta;
    return d ? sus + (1 - sus) * Math.exp(-3 * (t - ta) / (d * FRAME)) : sus;
  }

  function voice(out, kind, e, t0, dur) {
    const inst = e.inst;
    const start = Math.round(t0 * SR);
    const gate = dur * e.q / 8;
    const rel = inst ? inst.adsr[3] * FRAME : 0;
    const len = Math.min(Math.floor((gate + rel) * SR), out.length - start);
    const drum = e.drum && DRUMS[e.drum];
    const envGate = inst && envAt(inst.adsr, gate);
    let phase = 0.25, phase2 = 0, lfsr = 1, low = 0, band = 0;
    for (let s = 0; s < len; s++) {
      const time = s / SR, fr = Math.floor(time / FRAME);
      let freq, env, w = kind, duty = DUTY[e.duty], gain = GAIN[kind];
      if (drum) {
        freq = drum[0] || 45 + 140 * Math.exp(-time / 0.025);
        env = e.drum === 'c' && time < 0.03 ? Math.exp(-(time % 0.01) / 0.004) : Math.exp(-time / drum[1]);
        gain *= drum[2];
        if (e.drum === 'k') w = 'tri';
      } else if (inst) {
        w = inst.wave[Math.min(fr, inst.wave.length - 1)];
        gain = GAIN[w];
        const pre = inst.arp, loop = inst.loop;
        let note = e.notes[fr % e.notes.length]
          + (fr < pre.length ? pre[fr] : loop.length ? loop[(fr - pre.length) % loop.length] : pre[pre.length - 1] ?? 0);
        note += inst.detune / 100;
        if (time < inst.slide[1] * FRAME) note += inst.slide[0] * (1 - time / (inst.slide[1] * FRAME));
        if (inst.vib && time > 0.25) note += inst.vib * Math.sin(2 * Math.PI * 5.5 * (time - 0.25));
        freq = 440 * 2 ** ((note - 69) / 12);
        if (w === 'noise') freq *= 16; // SID noise clocks 16x per oscillator cycle
        env = time <= gate ? envAt(inst.adsr, time) : envGate * Math.exp(-3 * (time - gate) / rel);
        duty = bounce(inst.pw[0], inst.pw[1], inst.pw[2], (t0 + time) / FRAME);
      } else {
        let note = e.notes[fr % e.notes.length];
        if (e.notes.length === 1 && time > 0.25) note += 0.2 * Math.sin(2 * Math.PI * 5.5 * (time - 0.25));
        freq = 440 * 2 ** ((note - 69) / 12);
        env = 1 - 0.5 * time / gate;
      }
      // The 2A03 triangle has no volume control; everything else has 16 levels.
      const amp = kind === 'tri' && !inst ? 1 : Math.round(e.vol * env) / 15;
      const inc = Math.min(0.99, freq / (SR * OS));
      let acc = 0;
      for (let k = 0; k < OS; k++) {
        phase += inc;
        if (phase >= 1) {
          phase -= 1;
          lfsr = (lfsr >> 1) | (((lfsr ^ (lfsr >> 1)) & 1) << 14);
        }
        const x = w === 'pulse' ? (phase < duty ? 1 : -1)
          : w === 'saw' ? 2 * phase - 1
          : w === 'tri' ? TRI[(phase * 32) | 0]
          : (lfsr & 1 ? 1 : -1);
        if (inst && inst.ring) {
          phase2 = (phase2 + inc * inst.ring) % 1;
          acc += phase2 < 0.5 ? x : -x;
        } else acc += x;
      }
      let y = acc / OS;
      if (inst && inst.filter) { // state-variable filter
        const [a, b, rate, oneShot] = inst.cut;
        const cut = oneShot ? a + Math.sign(b - a) * Math.min(Math.abs(b - a), rate * time / FRAME)
          : bounce(Math.min(a, b), Math.max(a, b), rate, (t0 + time) / FRAME);
        const f = 2 * Math.sin(Math.PI * Math.max(30, Math.min(5000, cut)) / SR);
        low += f * band;
        const high = y - low - (1.8 - 1.7 * inst.res) * band;
        band += f * high;
        y = inst.filter === 'lp' ? low : inst.filter === 'bp' ? band : high;
      }
      const edge = Math.min(1, s / 64, (len - s) / 64); // declick
      out[start + s] += gain * amp * edge * y;
    }
  }

  function render(text) {
    const song = parseSong(text);
    const spb = 60 / song.tempo, sw = song.swing / 100;
    const warp = (t) => { // delay every second 16th
      const p = t * 2, i = Math.floor(p), f = p - i;
      return (i + (f < 0.5 ? f * 2 * sw : sw + (f - 0.5) * 2 * (1 - sw))) / 2;
    };
    const chans = Object.entries(song.channels).map(([name, mml]) => [name, parseChannel(mml, name, song.insts)]);
    const beats = song.bars * song.meter || Math.max(0, ...chans.map(([, c]) => c.beats));
    const warnings = [];
    for (const [name, c] of chans) {
      const bad = c.marks.findIndex((t) => Math.abs(t / song.meter - Math.round(t / song.meter)) > 1e-6);
      if (bad >= 0) warnings.push(`${name}: bar line ${bad + 1} falls at beat ${c.marks[bad]}, not on a bar`);
      if (c.beats > beats + 1e-6) warnings.push(`${name}: ${c.beats} beats, song is ${beats}`);
    }
    const out = new Float32Array(Math.ceil(beats * spb * SR));
    for (const [name, c] of chans) {
      const prefix = name.replace(/\d+$/, '');
      const kind = prefix in GAIN ? prefix : 'pulse';
      for (const e of c.ev) {
        const t0 = warp(e.t) * spb;
        voice(out, kind, e, t0, warp(e.t + e.d) * spb - t0);
      }
    }
    const peak = out.reduce((m, v) => Math.max(m, Math.abs(v)), 0) || 1;
    const drive = song.drive, top = drive ? Math.tanh(drive) : 1; // soft clip, like the SID's overdriven output stage
    for (let i = 0; i < out.length; i++) {
      const x = out[i] / peak;
      out[i] = 0.9 * (drive ? Math.tanh(drive * x) / top : x);
    }
    return { samples: out, song, warnings, peak, events: Object.fromEntries(chans.map(([n, c]) => [n, c.ev])), beats: Object.fromEntries(chans.map(([n, c]) => [n, c.beats])) };
  }

  function play(text, ctx) {
    const { samples } = render(text);
    const buf = ctx.createBuffer(1, samples.length, SR);
    buf.copyToChannel(samples, 0);
    const node = ctx.createBufferSource();
    node.buffer = buf;
    node.loop = true;
    node.connect(ctx.destination);
    node.start();
    return node;
  }

  root.Chip = { render, play, SR };

  if (typeof require !== 'undefined' && require.main === module) {
    const fs = require('fs');
    const [src, dst = src.replace(/\.\w+$/, '') + '.wav'] = process.argv.slice(2);
    const { samples, song, warnings } = render(fs.readFileSync(src, 'utf8'));
    const n = samples.length * song.loop;
    const buf = Buffer.alloc(44 + n * 2);
    buf.write('RIFF', 0); buf.writeUInt32LE(36 + n * 2, 4); buf.write('WAVEfmt ', 8);
    buf.writeUInt32LE(16, 16); buf.writeUInt16LE(1, 20); buf.writeUInt16LE(1, 22);
    buf.writeUInt32LE(SR, 24); buf.writeUInt32LE(SR * 2, 28); buf.writeUInt16LE(2, 32); buf.writeUInt16LE(16, 34);
    buf.write('data', 36); buf.writeUInt32LE(n * 2, 40);
    for (let i = 0; i < n; i++) buf.writeInt16LE(Math.round(samples[i % samples.length] * 32767), 44 + i * 2);
    fs.writeFileSync(dst, buf);
    console.log(`${dst}: ${(n / SR).toFixed(1)}s${warnings.map((w) => '\n  warning: ' + w).join('')}`);
  }
})(typeof module !== 'undefined' && module.exports ? module.exports : globalThis);
