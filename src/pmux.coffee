bb = require 'bluebird'
cp = require('child_process')
exec = (command) ->
  bb.try( -> cp.execSync(command).toString())

program = require('commander');

start_tmux = (configuration, verbose) ->
  command = "tmux list-sessions"
  console.log command
  exec(command).then( (out) ->
    console.log out
    if out.indexOf(configuration.platform_name) != -1
      command = "tmux kill-session -t #{configuration.platform_name}"
      console.log command
      exec(command)
    else
      true
  )
  .then( (out) ->
    console.log out
    command = "tmux -2 new-session -d -s #{configuration.platform_name}"
    console.log command
    exec(command)
  ).then( (out) ->
    console.log out
    command = "tmux set -t #{configuration.platform_name} set-remain-on-exit on"
    console.log command
    exec(command) #for debugging
  )

do_pre_commands = (configuration, verbose) ->
  promise = bb.try( -> )
  configuration.pre_commands = configuration.pre_commands || []

  for command in configuration.pre_commands
    do (command) ->
      promise = promise.then(-> 
        console.log command
        exec(command)
      ).then( (out) ->
        console.log out
      )
  promise

create_windows = (configuration, verbose) ->

  promises = []
  for name, win of configuration.windows
    do (name, win) ->
      win.commands = win.commands || []
      command = "tmux new-window -n '#{name}' -t #{configuration.platform_name}"
      win.commands.unshift "cd #{win.dir}" if win.dir
      command += " \"#{win.commands.join('; ')}\""
      
      delay = win.delay || 0
      promise = bb.delay(delay)
      .then( ->
        console.log command
        exec(command)
      )

      promises.push promise

  bb.all(promises)
  .then( (outs) ->
    console.log outs
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
  verbose = program.verbose

  console.log JSON.stringify(configuration, null , 2)

  start_tmux(configuration, verbose)
  .then( ->
    do_pre_commands(configuration, verbose)
  )
  .then( ->
    create_windows(configuration, verbose)
  )

module.exports = cli