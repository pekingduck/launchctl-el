# launchctl

## Introduction

![Screenshot](https://raw.githubusercontent.com/pekingduck/launchctl-el/master/screen.png)

*launchctl* is a major mode in Emacs that eases the loading and unloading of
services (user agents and system daemons) managed by *launchd* on Mac OS X.

*launchctl* interfaces with the command line tool `launchctl` under the hood.

## Installation
*Launchctl* is available from [MELPA](http://melpa.org/#/launchctl).

This package requires *tabulated-list-mode* which is only available for Emacs 24
and onwards.

If you install the package manually, put this in your dot emacs file:
```el
(require 'launchctl)
```

## Usage

Do `M-x launchctl` to enter *launchctl* mode.

Most commands are service-specific: you simply move the point to the corresponding
service and execute that command.

Note that some commands (namely edit, load, unload, enable and disable) require
users to supply the path to the corresponding service configuration file
(.plist).  *launchctl* will first look for *&lt;service-name&gt;.plist*
under the directories defined in ```launchctl-search-path```, and if the file
can't be found, prompt you for the path.

See **Customization** below on how to define your own search path.

### Commands
#### `g` **refresh**

Refresh the buffer.

#### `q` **quit window**

#### `t` **sort list**

Sort the buffer by service name.

#### `n` **create a new service configuration file**

You'll be prompted for a file name. See **customization** on how to customize the
configuration template.

Put the code below in your .emacs to have Emacs recognize plist files as XML files:

```el
(add-to-list 'auto-mode-alist '("\\.plist$" . nxml-mode))
```

#### `e` **edit configuration file.**

#### `v` **view configuration file in read-only mode.**

#### `l` **load service**

Equivalent to

```sh
bash$ launchctl load <service-configuration-file>
```

#### `u` **unload service**

Equivalent to

```sh
bash$ launchctl unload <service-configuration-file>
```

#### `r` **reload service**

Unload and then reload.

#### `d` **disable service permanently**

Once a service has been disabled, you won't be able to start or load it.

Equivalent to

```sh
bash$ launchctl unload -w <service-configuration-file>
```

#### `p` **enable service permanently**

To start or load a disabled service, you must enable it first.

Equivalent to:

```sh
bash$ launchctl load -w <service-configuration-file>
```

#### `s` **start service**

Equivalent to

```sh
bash$ launchctl start <service-name>
```

#### `o` **stop service**

Equivalent to

```sh
bash$ launchctl stop <service-name>
```

#### `a` **restart service**

Stop and then start the service.

#### `m` **remove service**

Equivalent to

```sh
bash$ launchctl remove <service-name>
```

#### `i` **display service info**

Display service info

Equivalent to:

```sh
bash$ launchctl list <service-name>
```

#### `*` **filter by regex**

You will be prompted for a regular expression. Only services whose names match
the expression will be shown.  See **Customization** below on how to set a
default value.

#### `$` **set environment variable**

Set an environment variable. You will be prompted for the variable name and its
value (separated by space), e.g. `SOME_VAR "SOME VALUE"`.

Equivalent to:

```sh
bash$ launchctl setenv SOME_VAR "SOME_VALUE"
```

#### `#` **unset environment variable**

Unset an environment variable. You will be prompted for the variable name.

Equivalent to:

```sh
bash$ launchctl unsetenv SOME_VAR
```

#### `h` **display help message**

Display a help message in the mini-buffer.

## Customization
You can `M-x customize-group` (group name: `launchctl`) to
customize *launchctl*.

#### `launchctl-search-path`

The directories to look for service configuration files. The default value
should be good for most people.

```el
;;; Default
("~/Library/LaunchAgents" "/System/Library/LaunchAgents" "/System/Library/LaunchDaemons")
```

#### `launchctl-configuration-template`

When you choose to create (`n`) a new configuration file, the corresponding
file buffer will be populated by this template.

#### `launchctl-filter-regex`

This regular expression will be used by *launchctl* to filter results . An
empty string (default) or `.` means no filtering will be done.

#### `launchctl-name-face`

Customize the appearance of the *Name* column.

#### `launchctl-name-width`, `launchctl-pid-width`, `launchctl-status-width`

Customize the widths of the columns

#### `launchctl-use-header-line`

Turn the header line on or off.

## Reference
[A launchd Tutorial](http://launchd.info/)

[launchctl.plist(5) manpage](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man5/launchd.plist.5.html)

[launchctl(1) manpage](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/launchctl.1.html#//apple_ref/doc/man/1/launchctl)

[launchd(8) manpage](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man8/launchd.8.html)
