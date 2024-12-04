defmodule MySupervisor do
  def start_link(children, strategy: :one_for_one) do
    pid = spawn_link(fn -> supervise(children) end)
    {:ok, pid}
  end

  def supervise(children) do
    children
    |> Enum.map(&start/1)
    |> Enum.zip(children)
    |> Enum.into(%{})
    |> loop()
  end

  def start({mod, args}) do
    {:ok, pid} = Kernel.apply(mod, :start_link, [args])
    ref = Process.monitor(pid)

    {pid, ref}
  end

  def loop(children) do
    receive do
      {:DOWN, ref, :process, pid, _reason} ->
        down = {pid, ref}
        mod_args = children |> Map.get(down)

        children
        |> Map.delete(down)
        |> Map.put(start(mod_args), mod_args)
        |> loop()
    end
  end
end
