ExUnit.start()

defmodule MockSocketModule do
  def start_link() do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def connect(_host, _port, _timeout) do
    case get() do
      [] -> {:error, :econnrefused}
      _ -> {:ok, :socket}
    end
  end

  def send_and_recv(_socket, command, _timeout) do
    case command do
      "version\n" ->
        {:ok, "VERSION 1.4.14\r\n"}

      "config get cluster\n" ->
        servers = get() |> Enum.join(" ")

        {:ok,
         "CONFIG cluster 0 #{String.length(servers)}\r\n1\n#{servers}\n\r\nEND\r\n"}
    end
  end

  def get() do
    Agent.get(__MODULE__, fn servers -> servers end)
  end

  def update(servers) do
    Agent.update(__MODULE__, fn _ -> servers end)
    send(Memcachir.HealthCheck, :check)
    # wait for it to be picked up
    Process.sleep(200)
  end
end

MockSocketModule.start_link()
