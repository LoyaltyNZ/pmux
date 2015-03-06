bb = require 'bluebird'
exec = bb.promisify(require('child_process').exec)
program = require('commander');

start_tmux = (configuration, verbose) ->
  exec("tmux list-sessions").then( (out) ->
    out = out.join('')
    if out.indexOf(configuration.platform_name) != -1
      exec("tmux kill-session -t #{configuration.platform_name}")
    else
      true
  )
  .then( ->
    exec("tmux -2 new-session -d -s #{configuration.platform_name}")
  ).then( ->
    exec("tmux set -t #{configuration.platform_name} set-remain-on-exit on") #for debugging
  )

create_windows = (configuration, verbose) ->

  promises = []
  for name, win of configuration.windows
    do (name, win) ->
      command = "tmux new-window -n '#{name}' -t #{configuration.platform_name}"
      command += " -c #{win.dir}" if win.dir
      command += " \"#{win.command}\""
      
      delay = win.delay || 0
      promise = bb.delay(delay)
      .then( ->
        console.log command if verbose
        exec(command)
      )

      promises.push promise

  bb.all(promises)

cli = ->

  program
    .version('0.0.1')
    .usage('[options] <pmux-configuration>')
    .description('start a pmux session')
    .option('-v, --verbose', "More talkative")
    .parse(process.argv);

  #Extracting Arguments
  configuration = require program.args[0]
  verbose = program.verbose

  console.log JSON.stringify(configuration, null , 2) if verbose

  start_tmux(configuration, verbose)
  .then( ->
    create_windows(configuration, verbose)
  )

module.exports = cli