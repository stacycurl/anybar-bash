# AnyBar Bash: Control AnyBar from a Bash shell

This project contains helpers for controlling AnyBar from a bash shell

## Usage

Change colour:

```sh
anybar <colour>
```

Monitor a long running command (orange whilst running, green or red if successful)

```sh
anybar_monitor <some_command>
```

Monitor every command automatically

```sh
anybar_monitor_enable
```

Stop monitoring every command

```sh
anybar_monitor_disable
```


## Installation

Clone this repo

```sh
http://github.com/stacycurl/anybar-bash.git
```

Add to .bashrc

```sh
source <wherever_you_cloned>/anybar-bash/init.sh
anybar_monitor_enable
alias m=anybar_monitor
```

Add to .bash_profile

```sh
_anybar_relaunch
```
