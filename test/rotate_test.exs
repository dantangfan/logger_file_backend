defmodule LoggerFileBackendTest.RotateTest do
  use ExUnit.Case, async: false
  require Logger

  @backend {LoggerFileBackend, :test}

  # add the backend here instead of `config/test.exs` due to issue 2649
  Logger.add_backend @backend

  setup do
    config [rotate: true, check_interval: 1, max_logsize: 1, backlog: 3, path: "test/logrotate/rotate.log"]
    on_exit fn ->
      path() && File.rm_rf!(Path.dirname(path()))
    end
  end

  test "rotate log file" do
    config format: "$message\n"

    Logger.debug "1111"
    assert ls() == ["rotate.log"]
    assert log() == "1111\n"

    Logger.debug "2222"
    assert ls() == ["rotate.log", "rotate.log.1"]
    assert log() == "2222\n"

    Logger.debug "3333"
    assert ls() == ["rotate.log", "rotate.log.1", "rotate.log.2"]
    assert log() == "3333\n"

    Logger.debug "4444"
    assert ls() == ["rotate.log", "rotate.log.1", "rotate.log.2", "rotate.log.3"]
    assert log() == "4444\n"
    assert File.read!(path() <> ".2") === "2222\n"

    Logger.debug "5555"
    assert File.read!(path() <> ".2") === "3333\n"

    Logger.debug "6666"
    assert ls() == ["rotate.log", "rotate.log.1", "rotate.log.2", "rotate.log.3"]
  end

  defp ls() do
    dir = Path.dirname(path())
    File.ls!(dir) |> :lists.sort
  end

  defp path do
    {:ok, path} = GenEvent.call(Logger, @backend, :path)
    path
  end

  defp log do
    File.read!(path())
  end

  defp config(opts) do
    Logger.configure_backend(@backend, opts)
  end
end
