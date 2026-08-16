// Read-aloud narration using the browser Web Speech API (speechSynthesis).
// Pure client-side; no server or DB. Big accessibility win for young / non-readers.
// Usage: <button onclick="readAloud('elementId')">🔊 Read aloud</button>
function readAloud(elementId) {
    var el = document.getElementById(elementId);
    if (!el) return;
    if (!('speechSynthesis' in window)) {
        alert('Sorry, your browser cannot read aloud.');
        return;
    }
    var synth = window.speechSynthesis;
    // Click again while speaking = stop.
    if (synth.speaking) {
        synth.cancel();
        return;
    }
    var text = el.innerText || el.textContent || '';
    if (!text.trim()) return;
    var u = new SpeechSynthesisUtterance(text);
    u.rate = 0.95;   // a touch slower for kids
    u.pitch = 1.1;   // slightly friendlier
    synth.speak(u);
}
