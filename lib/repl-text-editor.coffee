{Task} = require 'atom'
path = require 'path'
ReplProcess = require.resolve './repl-process'

module.exports =
class ReplTextEditor
  # This is set to some string to strip out of the text displayed. It is used to remove code that
  # is sent to the repl because the repl will print the code that was sent to it.
  textToIgnore: null

  constructor: ->
    projectPath = atom.project.getPaths()[0]

    closingHandler =  =>
      try
        @process.send event: 'input', text: "(System/exit 0)\n"
      catch error
        console.log("Warning error while closing: " + error)

    atom.workspace.open("Clojure REPL", split:'right').done (textEditor) =>
      @textEditor = textEditor
      @textEditor.onDidDestroy(closingHandler)
      @textEditor.insertText("Loading REPL...\n")

    @process = Task.once ReplProcess,
                         path.resolve(projectPath),
                         atom.config.get('proto-repl.leinPath'),
                         atom.config.get('proto-repl.leinArgs').split(" ")
    @attachListeners()

  strToBytes: (s)->
    s.charCodeAt(n) for n in [0..s.length]

  autoscroll: ->
    if atom.config.get('proto-repl.autoScroll')
      @textEditor.scrollToBottom()

  attachListeners: ->
    @process.on 'proto-repl-process:data', (data) =>
      @textEditor.getBuffer().append(data)
      @autoscroll()

    @process.on 'proto-repl-process:exit', ()=>
      @textEditor.getBuffer().append("REPL Closed")
      @autoscroll()

  sendToRepl: (text)->
    @process.send event: 'input', text: text + "\n"
