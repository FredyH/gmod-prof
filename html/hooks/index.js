var chartColors = {
	red: 'rgb(255, 99, 132)',
	orange: 'rgb(255, 159, 64)',
	yellow: 'rgb(255, 205, 86)',
	green: 'rgb(75, 192, 192)',
	blue: 'rgb(54, 162, 235)',
	purple: 'rgb(153, 102, 255)',
	grey: 'rgb(201, 203, 207)'
}

function randomScalingFactor() {
	return (Math.random() > 0.5 ? 1.0 : -1.0) * Math.round(Math.random() * 100)
}

var color = Chart.helpers.color

function getConfig(label, col) {
	return {
		type: 'line',
		data: {
			datasets: [{
				label: label,
				backgroundColor: color(col).alpha(0.5).rgbString(),
				borderColor: col,
				fill: false,
				cubicInterpolationMode: 'monotone',
				data: []
			}]
		},
		options: {
			title: {
				display: true,
				text: label
			},
			scales: {
				xAxes: [{
					type: 'realtime',
					realtime: {
						duration: 60000,
						refresh: 1000,
						delay: 5000
					}
				}],
				yAxes: [{
					scaleLabel: {
						display: true,
						labelString: 'Milliseconds per Second'
					}
				}]
			},
			tooltips: {
				mode: 'nearest',
				intersect: false
			},
			hover: {
				mode: 'nearest',
				intersect: false
			}
		}
	}
}

window.onload = function() {
	var hookCtx = document.getElementById('hookChart').getContext('2d')
	window.hookChart = new Chart(hookCtx, getConfig("Hook Duration", chartColors.red))
}

/*
function startPlot() {
    window.myChart.options.plugins.streaming.pause = false
}


function stopPlot() {
    window.myChart.options.plugins.streaming.pause = true
}*/

function addHookDuration(duration) {
    window.hookChart.config.data.datasets[0].data.push({
        x: Date.now(),
        y: duration
    })
	window.hookChart.update()
}

function removeTableRow(table, messageName, idPrefix) {
	table.row("#" + idPrefix + messageName).remove()
}

function updateTableRow(table, row, idPrefix) {
	table.row("#" + idPrefix + row[0]).data(row).draw()
}

function addTableRow(table, row) {
	table.row.add(row)
}

function updateTableRows(table, rows, seenHooks, idPrefix) {
	const newHooks = new Set([])
	rows.forEach(row => {
		if (seenHooks.has(row[0])) {
			updateTableRow(table, row, idPrefix)
		} else {
			addTableRow(table, row, idPrefix)
		}
		newHooks.add(row[0])
	});
	seenHooks.forEach(eventName => {
		if (!newHooks.has(eventName)) {
			removeTableRow(table, eventName, idPrefix)
		}
	})
	seenHooks = newHooks
	table.draw()
	return newHooks
}

let seenHooks = new Set([])

function updateHookTableRows(rows) {
	seenHooks = updateTableRows($('#hookTable').DataTable(), rows, seenHooks, "")
}

$(function() {
	$('#hookTable').DataTable({
		rowId: function(a) { return a[0] }
	});
})