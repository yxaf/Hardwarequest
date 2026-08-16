// Client-side quiz question editor for Quiz/Builder.aspx.
// The DOM is the source of truth: cards are rendered from window.HQ_QUIZ
// (or the posted hidden field after a failed server validation), edited in
// place, and serialised back to JSON in the hidden field on submit.
var HQBuilder = (function () {
    'use strict';
    var cfg, list, seq = 0;
    var WEIGHTS = { Easy: 1, Medium: 2, Hard: 3 };
    var LETTERS = ['A', 'B', 'C', 'D'];

    function init(options) {
        cfg = options;
        list = document.getElementById(cfg.listId);
        document.getElementById(cfg.addBtnId).addEventListener('click', function () { addCard(); });
        document.getElementById(cfg.ddlId).addEventListener('change', updateSummary);
        list.addEventListener('input', updateSummary);

        var hid = document.getElementById(cfg.hidId);
        var data = [];
        if (hid.value) {
            try { data = JSON.parse(hid.value); } catch (e) { data = []; }
        } else if (window.HQ_QUIZ && HQ_QUIZ.questions) {
            data = HQ_QUIZ.questions;
        }
        for (var i = 0; i < data.length; i++) addCard(data[i]);
        updateSummary();
    }

    function optionRow(id, letter, placeholder) {
        return '<div class="input-group input-group-sm mb-1">' +
            '<div class="input-group-text"><input type="radio" class="form-check-input mt-0 hq-radio-' + letter + '"' +
            ' name="hqc-' + id + '" value="' + letter + '" title="Correct answer"></div>' +
            '<span class="input-group-text">' + letter + '</span>' +
            '<input type="text" class="form-control hq-opt-' + letter + '" maxlength="200" placeholder="' + placeholder + '">' +
            '</div>';
    }

    function addCard(q) {
        q = q || {};
        var id = ++seq;
        var card = document.createElement('div');
        card.className = 'card p-3 mb-2 hq-qcard';
        card.innerHTML =
            '<div class="d-flex justify-content-between align-items-start mb-2">' +
            '  <strong class="hq-qnum"></strong>' +
            '  <button type="button" class="btn btn-sm btn-outline-danger hq-del" title="Remove question">&times;</button>' +
            '</div>' +
            '<textarea class="form-control mb-2 hq-qtext" rows="2" maxlength="400" placeholder="Type the question here"></textarea>' +
            optionRow(id, 'A', 'Option A (required)') +
            optionRow(id, 'B', 'Option B (required)') +
            optionRow(id, 'C', 'Option C (optional)') +
            optionRow(id, 'D', 'Option D (optional)') +
            '<small class="text-muted">Tick the radio beside the correct answer.</small>';

        card.querySelector('.hq-qtext').value = q.text || '';
        LETTERS.forEach(function (L) {
            card.querySelector('.hq-opt-' + L).value = q[L.toLowerCase()] || '';
            if ((q.correct || '').toUpperCase() === L) card.querySelector('.hq-radio-' + L).checked = true;
        });
        card.querySelector('.hq-del').addEventListener('click', function () {
            card.remove(); renumber(); updateSummary();
        });
        list.appendChild(card);
        renumber();
        updateSummary();
    }

    function cards() { return Array.prototype.slice.call(list.querySelectorAll('.hq-qcard')); }

    function renumber() {
        cards().forEach(function (c, i) { c.querySelector('.hq-qnum').textContent = 'Q' + (i + 1); });
    }

    function collect() {
        return cards().map(function (c) {
            var correct = '';
            LETTERS.forEach(function (L) { if (c.querySelector('.hq-radio-' + L).checked) correct = L; });
            return {
                text: c.querySelector('.hq-qtext').value.trim(),
                a: c.querySelector('.hq-opt-A').value.trim(),
                b: c.querySelector('.hq-opt-B').value.trim(),
                c: c.querySelector('.hq-opt-C').value.trim(),
                d: c.querySelector('.hq-opt-D').value.trim(),
                correct: correct
            };
        });
    }

    // Mirrors the server-side rules exactly (defence in depth).
    function validate(mustHaveQuestion) {
        var errors = [];
        var all = cards();
        all.forEach(function (c) { c.classList.remove('border-danger'); });
        collect().forEach(function (q, i) {
            var bad = [];
            if (!q.text) bad.push('text is required');
            if (!q.a) bad.push('option A is required');
            if (!q.b) bad.push('option B is required');
            if (!q.correct) bad.push('tick the correct answer');
            else if (!q[q.correct.toLowerCase()]) bad.push('the correct answer points at an empty option');
            if (bad.length) {
                errors.push('Question ' + (i + 1) + ': ' + bad.join(', ') + '.');
                all[i].classList.add('border-danger');
            }
        });
        if (mustHaveQuestion && all.length === 0)
            errors.push('Add at least one question before publishing.');
        return errors;
    }

    function updateSummary() {
        var w = WEIGHTS[document.getElementById(cfg.ddlId).value] || 1;
        var n = cards().length;
        document.getElementById(cfg.summaryId).textContent =
            n + ' question' + (n === 1 ? '' : 's') + ' · max ' + (n * w) + ' points';
    }

    function esc(s) { var d = document.createElement('div'); d.textContent = s; return d.innerHTML; }

    // Called from the Save/Publish buttons' OnClientClick before the postback.
    // isToggle: true when the button flips the published state.
    function beforeSubmit(isToggle) {
        var resultingPublished = isToggle ? !cfg.publishedNow : cfg.publishedNow;
        var errors = validate(resultingPublished);
        var box = document.getElementById(cfg.errorsId);
        if (errors.length) {
            box.innerHTML = errors.map(esc).join('<br>');
            box.style.display = 'block';
            box.scrollIntoView({ behavior: 'smooth', block: 'center' });
            return false;
        }
        box.innerHTML = '';
        box.style.display = 'none';
        document.getElementById(cfg.hidId).value = JSON.stringify(collect());
        return true;
    }

    return { init: init, beforeSubmit: beforeSubmit };
})();
