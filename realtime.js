var ws = new WebSocket("ws://cozy.tools:8080/realtime/")

ws.onopen = function() {
  console.log('Connected')
}

ws.onmessage = function(evt) {
  var out = document.getElementById('realtime')
  out.innerHTML += evt.data + '<br>'
}

setTimeout(function() {
  ws.send('{"method": "SUBSCRIBE", "payload": {"type":"io.cozy.files"} }')
}, 1000);
