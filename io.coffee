#pinoccio = require 'pinoccio'

#api = pinoccio "9eac1527993bc19e64e44270dd420948"

###
command = (cmd, callback) ->
  callback ?= (err) ->
    console.warn err if err
  api.rest {url:"/v1/1/1/command", method:"post", data:{command:cmd}}, callback

stream = api.sync()

stream.on 'data', (data) ->
  console.log data.data
###

{EventEmitter} = require 'events'

triggers = exports.triggers = new EventEmitter()

#triggers.on 'pot', (s) -> console.log s

###
do ->
  setInterval ->
    triggers.emit 'buttons', [1,0,1,0]

  , 100

  setInterval ->
    #triggers.emit 'pot', ((Math.random() * 2)|0) * 1023 #(Math.random() * 1024)|0
    triggers.emit 'pot', (Math.random() * 1024)|0

  , 1000
###

printErr = (err) ->
  console.error err if err

pbridge = require 'pinoccio-bridge'

{Writable} = require 'stream'

commandStream = new Writable {objectMode:true}
commandStream._write = (data, _, callback) ->
  console.log 'command', data.scout, data.cmd

  do retry = ->
    bridge.command data.scout, data.cmd, (err, data) ->
      console.log 'returned', err if err
      if err is 'busy'
        retry()
      else
        callback null, data

command = (scout, cmd, callback) ->
  return console.warn('ignoring', cmd) unless bridge

  callback ?= printErr
  commandStream.write {scout, cmd}, callback
  #bridge.command scout, cmd, callback


bridge = null
pbridge '/dev/cu.usbmodem1411', {}, (err, b) ->
  throw Error err if err
  console.log 'bridge connected'
  bridge = b

  command 3, 'led.purple', (err) ->
    #command 3, 'pin.setmode("d2",2)'
    #command 3, 'pin.setmode("d4",2)'
    #command 3, 'pin.setmode("a7",INPUT)'
    #command 3, 'events.setcycle(100, 100, 60000)'

  bridge.on 'data', (msg) ->
    if msg.type is 'report' and msg.from is 3 and msg.report?.state
      #console.log msg
      state = msg.report.state
      if msg.report.type is 'digital'
        triggers.emit 'buttons', [!state[0], !state[2], !state[4], !state[6]]
        console.log 'button', state
      if msg.report.type is 'analog'
        #console.log state[7]
        triggers.emit 'pot', 1023 - state[7]

  bridge.on 'error', (error) ->
    console.error error.stack || error

  #setInterval ->
  #  command 'pin.read("a7")', (err, data) ->
  #    console.log err,data

  #, 100

lastColor = null
exports.setLed = (val) ->
  color = if !val
    '255,255,255'
  else if val < 0
    '255,0,0'
  else
    '0,255,0'

  if color != lastColor
    command 4, "led.setrgb(#{color})"
    lastColor = color

  #command 2, "led.setrgb(#{color})"
  #command "led.setrgb(255,255,255)"


#exports.setLed = ->

exports.drive = (l, r) ->
  #console.log 'drive', l, r

###
v = false
setInterval ->
  callback = (err) -> console.error err if err
  return unless bridge
  if v
    bridge.command 1, 'led.on', callback
  else
    bridge.command 1, 'led.off', callback
  v = !v


, 1000
###
