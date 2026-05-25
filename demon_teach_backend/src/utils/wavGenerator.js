const fs = require('fs');

/**
 * Generates a 16-bit PCM Mono WAV buffer.
 * @param {number} sampleRate - e.g., 44100
 * @param {Float32Array|number[]} samples - array of floats in range [-1.0, 1.0]
 * @returns {Buffer}
 */
function createWavBuffer(sampleRate, samples) {
  const numSamples = samples.length;
  const subChunk2Size = numSamples * 2; // 16-bit = 2 bytes per sample
  const chunkSize = 36 + subChunk2Size;
  
  const buffer = Buffer.alloc(44 + subChunk2Size);
  
  // RIFF header
  buffer.write('RIFF', 0);
  buffer.writeUInt32LE(chunkSize, 4);
  buffer.write('WAVE', 8);
  
  // fmt subchunk
  buffer.write('fmt ', 12);
  buffer.writeUInt32LE(16, 16); // subchunk1Size
  buffer.writeUInt16LE(1, 20);  // audioFormat (1 = PCM)
  buffer.writeUInt16LE(1, 22);  // numChannels (1 = Mono)
  buffer.writeUInt32LE(sampleRate, 24); // sampleRate
  buffer.writeUInt32LE(sampleRate * 2, 28); // byteRate
  buffer.writeUInt16LE(2, 32);  // blockAlign
  buffer.writeUInt16LE(16, 34); // bitsPerSample
  
  // data subchunk
  buffer.write('data', 36);
  buffer.writeUInt32LE(subChunk2Size, 40);
  
  // Write PCM audio data
  for (let i = 0; i < numSamples; i++) {
    // Clamp sample to [-1, 1]
    let s = Math.max(-1, Math.min(1, samples[i]));
    // Convert to 16-bit signed integer
    const val = s < 0 ? s * 0x8000 : s * 0x7FFF;
    buffer.writeInt16LE(Math.floor(val), 44 + i * 2);
  }
  
  return buffer;
}

/**
 * Generates a specific synthesizer sound effect.
 * @param {string} type - 'crystal', 'rune', 'whisper', 'victory'
 * @returns {Buffer}
 */
function generateSfx(type) {
  const sampleRate = 44100;
  let duration = 0.5;
  let samples;

  if (type === 'crystal') {
    duration = 0.4;
    const numSamples = Math.floor(sampleRate * duration);
    samples = new Float32Array(numSamples);
    
    for (let i = 0; i < numSamples; i++) {
      const t = i / sampleRate;
      // High frequency chime
      const freq = 1200 + 400 * Math.sin(2 * Math.PI * 1.5 * t);
      // Exponential decay
      const envelope = Math.exp(-7 * t);
      
      // Combine principal frequency and some crystalline high harmonics
      const val = 0.6 * Math.sin(2 * Math.PI * freq * t) +
                  0.3 * Math.sin(2 * Math.PI * freq * 2.1 * t) +
                  0.1 * Math.sin(2 * Math.PI * freq * 3.5 * t);
                  
      samples[i] = val * envelope;
    }
  } else if (type === 'rune') {
    duration = 0.5;
    const numSamples = Math.floor(sampleRate * duration);
    samples = new Float32Array(numSamples);
    
    for (let i = 0; i < numSamples; i++) {
      const t = i / sampleRate;
      // Low mystical pitch sliding down with LFO frequency modulation
      const lfo = Math.sin(2 * Math.PI * 8 * t);
      const freq = 160 - 40 * t + 10 * lfo;
      
      // Rise quickly, decay exponentially
      const envelope = (t < 0.05) ? (t / 0.05) : Math.exp(-4 * (t - 0.05));
      
      // Base frequency + subharmonic + spooky overtones
      const val = 0.5 * Math.sin(2 * Math.PI * freq * t) +
                  0.3 * Math.sin(2 * Math.PI * (freq / 2) * t) +
                  0.2 * Math.sin(2 * Math.PI * freq * 1.5 * t);
                  
      samples[i] = val * envelope;
    }
  } else if (type === 'whisper') {
    duration = 0.3;
    const numSamples = Math.floor(sampleRate * duration);
    samples = new Float32Array(numSamples);
    
    let lastNoise = 0;
    for (let i = 0; i < numSamples; i++) {
      const t = i / sampleRate;
      // White noise generator
      const noise = Math.random() * 2 - 1;
      
      // Filter noise to sound soft/airy (simple low-pass filter)
      lastNoise = lastNoise * 0.9 + noise * 0.1;
      
      const envelope = Math.exp(-6 * t);
      // Soft high-frequency sine wave mixed in
      const hum = 0.15 * Math.sin(2 * Math.PI * 3000 * t);
      
      samples[i] = (lastNoise + hum) * envelope;
    }
  } else if (type === 'victory') {
    duration = 0.8;
    const numSamples = Math.floor(sampleRate * duration);
    samples = new Float32Array(numSamples);
    
    // Play 3 notes rising: C5 (523Hz), E5 (659Hz), G5 (784Hz)
    const noteDurations = [0.15, 0.15, 0.5];
    const freqs = [523.25, 659.25, 783.99];
    
    let noteStartIdx = 0;
    for (let noteIdx = 0; noteIdx < 3; noteIdx++) {
      const noteSamples = Math.floor(sampleRate * noteDurations[noteIdx]);
      const freq = freqs[noteIdx];
      
      for (let j = 0; j < noteSamples; j++) {
        const i = noteStartIdx + j;
        if (i >= numSamples) break;
        
        const t = j / sampleRate;
        const totalT = i / sampleRate;
        
        // Decay within the note
        const env = noteIdx === 2 
          ? Math.exp(-3 * t) // Last note decays longer
          : Math.exp(-10 * t); // Staccato for first two notes
          
        const val = 0.5 * Math.sin(2 * Math.PI * freq * t) +
                    0.25 * Math.sin(2 * Math.PI * freq * 2 * t) +
                    0.15 * Math.sin(2 * Math.PI * freq * 3 * t);
                    
        samples[i] = val * env;
      }
      noteStartIdx += noteSamples;
    }
  } else {
    // Default click
    duration = 0.1;
    const numSamples = Math.floor(sampleRate * duration);
    samples = new Float32Array(numSamples);
    for (let i = 0; i < numSamples; i++) {
      const t = i / sampleRate;
      samples[i] = Math.sin(2 * Math.PI * 1000 * t) * Math.exp(-20 * t);
    }
  }

  return createWavBuffer(sampleRate, samples);
}

module.exports = {
  generateSfx
};
