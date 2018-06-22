# clip-dmenu

This tool executes commands with clipboard contents as argument.
It is meant to be used with clipboard manager that doesn't support performing actions on clipboard contents.

## Config file
`clip-dmenu` reads actions form file `~/.config/clip-dmenu/config`.
It's format is very simple:

```
action-1-name:	actions-1-command
action-2-name:	actions-2-command
```

`action-name` is displayed label to identify command.
`action-command` is a command that will be executed when this action will be selected from a menu. Any occurence of `%s` will be replaced with clipboard contents.
Name should be separated from a command by a tab.

See `config.sample` file for an example.

## Invocation
`clip-dmenu [OPTIONS]`
where OPTIONS may be:

	--file
	-f         specifies path to config file
	--background
	-b         run selected command in the background
	--command
	-c         specify command to run instead of `dmenu`
	--help
	-h         show help
	--version  show version information

## Dependencies
- perl
- dmenu (or equivalent, like rofi)
