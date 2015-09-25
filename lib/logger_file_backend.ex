defmodule LoggerFileBackend do
  use GenEvent

  @type path      :: String.t
  @type file      :: :file.io_device
  @type inode     :: File.Stat.t
  @type format    :: String.t
  @type level     :: Logger.level
  @type metadata  :: [atom]


  @default_format "$date $time $metadata[$level] $message\n"
  @default_check_interval 10 * 1000 * 1000

  def init({__MODULE__, name}) do
    {:ok, configure(name, [])}
  end


  def handle_call({:configure, opts}, %{name: name}) do
    {:ok, :ok, configure(name, opts)}
  end


  def handle_call(:path, %{path: path} = state) do
    {:ok, {:ok, path}, state}
  end


  def handle_event({level, _gl, {Logger, msg, ts, md}}, %{level: min_level} = state) do
    if is_nil(min_level) or Logger.compare_levels(level, min_level) != :lt do
      log_event(level, msg, ts, md, state)
    else
      {:ok, state}
    end
  end


  # helpers

  defp log_event(_level, _msg, _ts, _md, %{path: nil} = state) do
    {:ok, state}
  end

  defp log_event(level, msg, ts, md, %{path: path, io_device: nil} = state) when is_binary(path) do
    case open_log(path) do
      {:ok, io_device, inode} ->
        log_event(level, msg, ts, md, %{state | io_device: io_device, inode: inode, last_check: :erlang.timestamp()})
      _other ->
        {:ok, state}
    end
  end

  defp log_event(level, msg, ts, md, %{
    path: path, io_device: io_device, inode: inode, last_check: last_check, check_interval: check_interval} = state) when is_binary(path) do
    if !is_nil(inode) and inode == check_inode(path, inode, last_check, check_interval) do
      IO.write(io_device, format_event(level, msg, ts, md, state))
      {:ok, state}
    else
      log_event(level, msg, ts, md, %{state | io_device: nil, inode: nil})
    end
  end


  defp open_log(path) do
    case (path |> Path.dirname |> File.mkdir_p) do
      :ok ->
        case File.open(path, [:append, {:encoding, :utf8}]) do
          {:ok, io_device} -> {:ok, io_device, inode(path)}
          other -> other
        end
      other -> other
    end
  end


  defp format_event(level, msg, ts, md, %{format: format, metadata: metadata}) do
    Logger.Formatter.format(format, level, msg, ts, Dict.take(md, metadata))
  end


  defp check_inode(path, old_inode, last_check, check_interval) do
    diff = :timer.now_diff(:erlang.timestamp(), last_check)
    if diff > check_interval do
      inode(path)
    else
      old_inode
    end
  end

  defp inode(path) do
    case File.stat(path) do
      {:ok, %File.Stat{inode: inode}} -> inode
      {:error, _} -> nil
    end
  end


  defp configure(name, opts) do
    env = Application.get_env(:logger, name, [])
    opts = Keyword.merge(env, opts)
    Application.put_env(:logger, name, opts)

    level    = Keyword.get(opts, :level)
    metadata = Keyword.get(opts, :metadata, [])
    format   = Keyword.get(opts, :format, @default_format) |> Logger.Formatter.compile
    path     = Keyword.get(opts, :path)
    interval = Keyword.get(opts, :check_interval, @default_check_interval)

    %{
      name: name, 
      path: path, 
      io_device: nil, 
      inode: nil, 
      format: format, 
      level: level, 
      metadata: metadata,
      check_interval: interval,
      last_check: :erlang.timestamp(),
    }
  end
end
