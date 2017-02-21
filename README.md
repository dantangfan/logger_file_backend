LoggerFileBackend
=================

A simple `Logger` backend which writes logs to a file. By default, it does not handle log
rotation for you, but it does tolerate log file renames, so it can be
used in conjunction with external log rotation.

If you want a simple rotation by log size, config the following

* rotate - rotate mod, default false, if you want to rotate set true
* max_logsize - by default 1024\*1024\*1024 = 1G
* backlog - number of the backup logs, by default 30

**Note** The following of file renames does not work on Windows, because `File.Stat.inode` is used to determine whether the log file has been (re)moved and, on non-Unix, `File.Stat.inode` is always 0.

## Configuration

`LoggerFileBackend` supports the following configuration values:

* path - the path to the log file
* level - the logging level for the backend
* format - the logging format for the backend
* metadata - the metadata to include


### Runtime configuration for mutiple log files

```elixir
backends =[debug: [path: "/path/to/debug.log", format: ..., metadata: ...],
           error: [path: "/path/to/error.log", format: ..., metadata: ...]]

for {id, opts} <- backends do
  backend = {LoggerFileBackend, id}
  Logger.add_backend(backend)
  Logger.configure(backend, opts)
end
```

### Application config for multiple log files

```elixir
config :logger,
  backends: [{LoggerFileBackend, :info},
             {LoggerFileBackend, :error}]

config :logger, :info,
  path: "/path/to/info.log",
  level: :info

config :logger, :error,
  path: "/path/to/error.log",
  level: :error
```

