var ws = new WebSocket('ws://cozy.tools:8080/realtime/', "io.cozy.websocket")

ws.onopen = function() {
  var token = document.querySelector('[role=application]').dataset.token
  ws.send(`{"method": "AUTH", "payload": "${token}"}`)
  console.log('Connected')
}

ws.onmessage = function(evt) {
  var out = document.getElementById('realtime')
  out.innerHTML += evt.data + '<br>'
}

var form = document.getElementById('subscribe')
form.addEventListener('submit', function (event) {
  event.preventDefault()
  var type = document.getElementById('doctype')
  ws.send(`{"method": "SUBSCRIBE", "payload": {"type":"${type.value}"} }`)
  type.value = ''
})
