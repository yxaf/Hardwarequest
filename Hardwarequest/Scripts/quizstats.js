// Renders the two quiz-stats charts from JSON in the #hfChartData hidden field.
(function () {
  function getField() {
    // Web Forms gives the HiddenField a mangled id; match by suffix.
    var inputs = document.getElementsByTagName('input');
    for (var i = 0; i < inputs.length; i++) {
      if (inputs[i].id && inputs[i].id.indexOf('hfChartData') !== -1) return inputs[i];
    }
    return null;
  }

  document.addEventListener('DOMContentLoaded', function () {
    if (typeof Chart === 'undefined') return; // CDN offline: degrade gracefully
    var field = getField();
    if (!field || !field.value) return;
    var data;
    try { data = JSON.parse(field.value); } catch (e) { return; }

    var dist = document.getElementById('distChart');
    if (dist && data.dist) {
      new Chart(dist, {
        type: 'bar',
        data: {
          labels: ['0%', '25%', '50%', '75%', '100%'],
          datasets: [{ label: 'Students', data: data.dist, backgroundColor: '#2e6950' }]
        },
        options: { scales: { y: { beginAtZero: true, ticks: { precision: 0 } } }, plugins: { legend: { display: false } } }
      });
    }

    var time = document.getElementById('timeChart');
    if (time && data.timeLabels) {
      new Chart(time, {
        type: 'line',
        data: {
          labels: data.timeLabels,
          datasets: [{ label: 'Attempts', data: data.timeCounts, borderColor: '#0d6683', backgroundColor: 'rgba(13,102,131,.2)', fill: true, tension: .25 }]
        },
        options: { scales: { y: { beginAtZero: true, ticks: { precision: 0 } } }, plugins: { legend: { display: false } } }
      });
    }
  });
})();
