/* ═══════════════════════════════════════════════════════════════════════
   🔊 SHINE SOUND LAB — PROCEDURAL WEBAUDIO SYNTHESIZER
   Emulating Looping v2.6 audio.tone(freq, ms) & 8-bit sound effects
   Coki Studios & Holo Entertainment © 2026
   ═══════════════════════════════════════════════════════════════════════ */

(function () {
    let audioCtx = null;
    let analyser = null;
    let animId = null;

    function getAudioContext() {
        if (!audioCtx) {
            const AudioContextClass = window.AudioContext || window.webkitAudioContext;
            audioCtx = new AudioContextClass();
            analyser = audioCtx.createAnalyser();
            analyser.fftSize = 256;
            analyser.connect(audioCtx.destination);
            startVisualizer();
        }
        if (audioCtx.state === 'suspended') {
            audioCtx.resume();
        }
        return audioCtx;
    }

    function playTone(freq, durationMs, type = 'sine', sweepToFreq = null) {
        const ctx = getAudioContext();
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();

        osc.type = type;
        osc.frequency.setValueAtTime(freq, ctx.currentTime);

        if (sweepToFreq !== null) {
            osc.frequency.exponentialRampToValueAtTime(Math.max(10, sweepToFreq), ctx.currentTime + durationMs / 1000);
        }

        gain.gain.setValueAtTime(0.2, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + durationMs / 1000);

        osc.connect(gain);
        gain.connect(analyser);

        osc.start();
        osc.stop(ctx.currentTime + durationMs / 1000);
    }

    function playNoise(durationMs) {
        const ctx = getAudioContext();
        const bufferSize = ctx.sampleRate * (durationMs / 1000);
        const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
        const data = buffer.getChannelData(0);

        for (let i = 0; i < bufferSize; i++) {
            data[i] = Math.random() * 2 - 1;
        }

        const noise = ctx.createBufferSource();
        noise.buffer = buffer;

        const filter = ctx.createBiquadFilter();
        filter.type = 'lowpass';
        filter.frequency.setValueAtTime(800, ctx.currentTime);
        filter.frequency.exponentialRampToValueAtTime(100, ctx.currentTime + durationMs / 1000);

        const gain = ctx.createGain();
        gain.gain.setValueAtTime(0.3, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + durationMs / 1000);

        noise.connect(filter);
        filter.connect(gain);
        gain.connect(analyser);

        noise.start();
        noise.stop(ctx.currentTime + durationMs / 1000);
    }

    window.triggerSoundEffect = function (effect) {
        switch (effect) {
            case 'jump':
                playTone(180, 160, 'square', 450);
                break;
            case 'coin':
                playTone(987, 80, 'sine');
                setTimeout(() => playTone(1318, 180, 'sine'), 90);
                break;
            case 'powerup':
                const notes = [523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6
                notes.forEach((f, idx) => {
                    setTimeout(() => playTone(f, 90, 'triangle'), idx * 70);
                });
                break;
            case 'laser':
                playTone(1200, 150, 'sawtooth', 120);
                break;
            case 'shield':
                playTone(440, 250, 'sine');
                playTone(554.37, 250, 'sine');
                playTone(659.25, 250, 'sine');
                break;
            case 'hit':
                playNoise(220);
                break;
            default:
                playTone(440, 100, 'sine');
        }
    };

    function startVisualizer() {
        const canvas = document.getElementById('sound-visualizer-canvas');
        if (!canvas || !analyser) return;
        const ctx = canvas.getContext('2d');
        const bufferLength = analyser.frequencyBinCount;
        const dataArray = new Uint8Array(bufferLength);

        function draw() {
            animId = requestAnimationFrame(draw);
            analyser.getByteTimeDomainData(dataArray);

            ctx.fillStyle = '#020409';
            ctx.fillRect(0, 0, canvas.width, canvas.height);

            ctx.lineWidth = 2;
            ctx.strokeStyle = '#f59e0b';
            ctx.beginPath();

            const sliceWidth = canvas.width / bufferLength;
            let x = 0;

            for (let i = 0; i < bufferLength; i++) {
                const v = dataArray[i] / 128.0;
                const y = (v * canvas.height) / 2;

                if (i === 0) {
                    ctx.moveTo(x, y);
                } else {
                    ctx.lineTo(x, y);
                }
                x += sliceWidth;
            }

            ctx.lineTo(canvas.width, canvas.height / 2);
            ctx.stroke();
        }

        draw();
    }

    document.addEventListener('DOMContentLoaded', () => {
        document.querySelectorAll('.cs-sound-pad').forEach(pad => {
            pad.addEventListener('click', () => {
                const effect = pad.dataset.sound;
                window.triggerSoundEffect(effect);
            });
        });
    });
})();
