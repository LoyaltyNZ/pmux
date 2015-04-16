bb = require 'bluebird'
execAsync = bb.promisify require('child_process').exec
program = require('commander');
chalk =  require 'chalk'
exec = (command) ->
  console.log "" if VERBOSE
  console.log "#{chalk.blue("executing")} '#{command}'" if VERBOSE
  execAsync(command)
  .then((out) -> 
    out = out.filter( (x) -> x != '')
    out = out.toString()
    console.log "#{chalk.blue("returned")} '#{out}'" if VERBOSE
    console.log "" if VERBOSE
    out
  )

exec_tmux = (command) ->
  # tmux returns before fully executing command 
  # so tmux commands must be followed by delay to give it time to do its thing
  exec(command)
  .delay(250)

start_tmux = (configuration) ->
  exec_tmux("tmux new-session -d -s PMUX_INIT_SESSION") #force tmux to start if it hasn't yet
  .catch( (e) ->
    #catch error if it has started already
  ) 
  .then( -> exec_tmux("tmux list-sessions"))
  .then( (out) ->
    if out.indexOf(configuration.name) != -1
      exec_tmux("tmux kill-session -t #{configuration.name}")
    else
      true
  )
  .then( (out) ->
    exec_tmux("tmux -2 new-session -d -s #{configuration.name}")
  ).then( (out) ->
    exec_tmux("tmux set -t #{configuration.name} set-remain-on-exit on") #for debugging
  )
  .catch((e) -> 
    console.error "ERROR STARTING PMUX"
    console.error e
    throw e
  )

do_pre_commands = (configuration) ->
  #create a chain of promises to execute the pre-commands synchronously
  pre_commands_promise = bb.try( -> )
  configuration.pre_commands = configuration.pre_commands || []
  for command in configuration.pre_commands
    do (command) ->
      pre_commands_promise = pre_commands_promise.then(-> 
        exec(command)
      )

  pre_commands_promise
  .catch((e) -> 
    console.error "ERROR EXECUTING PRE COMMANDS" 
    console.error e
    throw e
  )

create_windows = (configuration) ->

  promise = bb.try( -> )
  for name, win of configuration.windows
    do (name, win) ->
      if typeof(win.commands) == 'string'
        win.commands = [win.commands]  

      win.commands = win.commands || []

      command = "tmux new-window -n '#{name}' -t #{configuration.name}"
      win.commands.unshift "cd #{win.dir}" if win.dir
      command += " \"#{win.commands.join('; ')}\""
      
      promise = promise
      .then( ->
        exec_tmux(command)
      )

  promise
  .catch((e) -> 
    console.error "ERROR CREATING WINDOWS" 
    console.error e
    throw e
  )

path = require 'path'

cli = ->

  program
    .version('0.0.1')
    .usage('[options] <pmux-configuration>')
    .description('start a pmux session')
    .option('-v, --verbose', "More talkative")
    .parse(process.argv);

  #Extracting Arguments

  configuration = require path.join(process.cwd(), program.args[0])
  global.VERBOSE = program.verbose

  console.log JSON.stringify(configuration, null , 2)

  do_pre_commands(configuration)
  .then( ->
    start_tmux(configuration)
  )
  .then( ->
    create_windows(configuration)
  )

module.exports = cli