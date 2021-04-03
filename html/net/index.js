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
						delay: 2000
					}
				}],
				yAxes: [{
					scaleLabel: {
						display: true,
						labelString: 'Bytes per second'
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
	var incomingCtx = document.getElementById('incomingChart').getContext('2d')
	var outgoingCtx = document.getElementById('outgoingChart').getContext('2d')
	window.incomingChart = new Chart(incomingCtx, getConfig("Incoming Data", chartColors.red))
	window.outgoingChart = new Chart(outgoingCtx, getConfig("Outgoing Data", chartColors.yellow))
}

/*
function startPlot() {
    window.myChart.options.plugins.streaming.pause = false
}


function stopPlot() {
    window.myChart.options.plugins.streaming.pause = true
}*/

function addIncomingData(bytes) {
    window.incomingChart.config.data.datasets[0].data.push({
        x: Date.now(),
        y: bytes
    })
	window.incomingChart.update()
}

function addOutgoingData(bytes) {
    window.outgoingChart.config.data.datasets[0].data.push({
        x: Date.now(),
        y: bytes
    })
	window.outgoingChart.update()
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

function updateTableRows(table, rows, tableMessages, idPrefix) {
	const newMessages = new Set([])
	rows.forEach(row => {
		if (tableMessages.has(row[0])) {
			updateTableRow(table, row, idPrefix)
		} else {
			addTableRow(table, row, idPrefix)
		}
		newMessages.add(row[0])
	});
	tableMessages.forEach(message => {
		if (!newMessages.has(message)) {
			removeTableRow(table, message, idPrefix)
		}
	})
	tableMessages = newMessages
	table.draw()
	return newMessages
}

let incomingTableMessages = new Set([])
let outgoingTableMessages = new Set([])

function updateIncomingTableRows(rows) {
	incomingTableMessages = updateTableRows($('#incomingNetTable').DataTable(), rows, incomingTableMessages, "in_")
}

function updateOutgoingTableRows(rows) {
	outgoingTableMessages = updateTableRows($('#outgoingNetTable').DataTable(), rows, outgoingTableMessages, "out_")
}

$(function() {
	$('#incomingNetTable').DataTable({
		rowId: function(a) { return "in_" + a[0] }
	});
	$('#outgoingNetTable').DataTable({
		rowId: function(a) { return "out_" + a[0] }
	});
})