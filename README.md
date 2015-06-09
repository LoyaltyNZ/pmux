# pmux

pmux is a programmable multiplexer that takes either a JSON file or a node.js script that describes a series of commands to be executed in windows in a tmux session.

## Getting Started

Install pmux with:

```
npm install -g pmux
```

Execute pmux with:

```
pmux <path-to-configuration-file>
```

## Example

`basic_pmux_configuration.json`: 

```
{
  "name": "simple_example",
  "pre_commands": ["ls"],
  "windows": {
    "pwd": {
      "commands": ["pwd"],
      "dir" : "."
    }
  }
}
```

Calling `pmux examples/basic_pmux_configuration.json` will:

1. executes the `pre_commands` synchronously, so call `ls` to list the current directories content
2. creates a tmux session called `simple_example`, destroying any other session with that name
3. creates a window in the `simple_example` session called "pwd", starting in the directory `.` and then executing the commands in the `commands` array.


The node.js script version of this file `basic_pmux_configuration.js` is:

```
module.exports = {
  "name": "simple_example",
  "pre_commands": ["ls"],
  "windows": {
    "pwd": {
      "commands": ["pwd"],
      "dir" : "."
    }
  }
}
```

