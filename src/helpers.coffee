fs = require 'fs'
rmdir = require 'rimraf'
fns = {}
_ = require 'underscore'

fns.git_clone = (configuration) ->
  #make
  root_dir = ".#{configuration.name}_repos"
  if fs.existsSync(root_dir)
    console.log "rm -rf #{root_dir}"
    rmdir.sync(root_dir)
  fs.mkdirSync(root_dir)
  
  gitcommands = ""
  for name, win of configuration.windows
    continue if not win.repo
    git_dir = "#{root_dir}/#{name}"
    win.dir = "#{process.cwd()}/#{git_dir}"

    git_command = "git clone "
    git_command += "-b #{win.branch} " if win.branch
    git_command += "#{win.repo} #{git_dir}"
    gitcommands += "#{git_command} & "
    

  pre_commands = configuration.pre_commands || []
  gitcommands += "wait  $(jobs -p)"
  pre_commands.push gitcommands
  
  configuration.pre_commands = pre_commands
  configuration

#git clone assuming the stuff has already been clones (for testing)
fns.git_clone_stub = (configuration) ->
  root_dir = ".#{configuration.name}_repos"
  for name, win of configuration.windows
    continue if not win.repo
    git_dir = "#{root_dir}/#{name}"
    win.dir = "#{process.cwd()}/#{git_dir}"
  configuration


fns.bundle_install = (configuration) ->
  pre_commands = configuration.pre_commands || []
  for name, win of configuration.windows
    continue if not win.gemfile
    rvm_version = win.rvm || configuration.rvm
    command = ""
    if rvm_version
      command += "source ~/.rvm/scripts/rvm; rvm use #{rvm_version}; "
    command += "bundle install --gemfile=#{win.dir}/#{win.gemfile} --jobs=3 --retry=3"
    command = "bash --login -c '#{command}'"

    pre_commands.push command

  configuration.pre_commands = pre_commands
  configuration

fns.git_checkout = (configuration) ->
  for name, win of configuration.windows
    continue if not win.branch
    win.commands.unshift("git checkout #{win.branch}")
    win.commands.unshift("git pull")

  configuration

fns.before = (configuration) ->
  for name, win of configuration.windows
    continue if not win.before
    if _.isArray(win.before)
      win.commands = win.before.concat(win.commands)
    else
      win.commands.unshift win.before

  configuration

fns.env = (configuration) ->
  for name, win of configuration.windows 
    win.commands.unshift "export #{win.env}" if win.env
    win.commands.unshift "export #{configuration.env}" if configuration.env

  configuration

fns.logging = (configuration) ->
  return configuration if not configuration.log_file
  pre_commands = configuration.pre_commands || []
  pre_commands.push "echo '' > #{configuration.log_file}"
  configuration.pre_commands = pre_commands

  for name, win of configuration.windows
    win.commands = win.commands.map( (command) -> if command.dont_log then command else "#{command} >> #{configuration.log_file} 2>&1") 

  configuration

fns.rvm = (configuration) ->
  #for individual windows
  for name, win of configuration.windows 
    version = win.rvm || configuration.rvm
    win.commands.unshift "source ~/.rvm/scripts/rvm; rvm use #{version}" if version

  configuration


module.exports = fns