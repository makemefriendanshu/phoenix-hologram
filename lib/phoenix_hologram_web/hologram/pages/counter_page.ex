defmodule PhoenixHologramWeb.Hologram.Pages.CounterPage do
  use Hologram.Page

  route "/hologram"

  layout PhoenixHologramWeb.Hologram.Layouts.DefaultLayout

  def init(_params, component, _server) do
    put_state(component, :count, 0)
  end

  def template do
    ~HOLO"""
    <h1>Hologram is wired up</h1>
    <p>
      This page is served through the Phoenix endpoint, but rendered and made
      interactive by Hologram — the click handler below runs Elixir compiled
      to JavaScript, with no separate JS framework involved.
    </p>
    <button id="increment" $click="increment">Increment</button>
    <p>Count: <strong id="count">{@count}</strong></p>
    """
  end

  def action(:increment, _params, component) do
    put_state(component, :count, component.state.count + 1)
  end
end
