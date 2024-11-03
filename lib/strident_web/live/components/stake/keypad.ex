defmodule StridentWeb.Components.Stake.Keypad do
  @moduledoc false
  use StridentWeb, :live_component

  @zero_money Money.new(:USD, 0)
  @defaults %{
    buttons: [10, 20, 50, 100, 200, "OTHER"],
    class: "",
    max_amount: Money.new(:USD, "Inf"),
    min_amount: @zero_money,
    selected_amount: @zero_money,
    selected_button: nil,
    show_input_amount: false,
    active_button_attributes: "bg-grey-medium btn--primary text-primary"
  }

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  def maybe_set_selected_amount_as_remaining_stake_amount(socket) do
    socket =
      if socket.assigns.selected_button == "OTHER" do
        socket
        |> assign(:selected_amount, socket.assigns.max_amount)
      else
        socket
      end

    socket
  end

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(Map.merge(@defaults, assigns))
    |> assign_preset_buttons()
    |> assign_show_input_amount()
    |> maybe_set_selected_amount_as_remaining_stake_amount()
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("action", %{"button_value" => action}, socket) do
    socket =
      socket
      |> assign_open_input_amount()
      |> assign_selected_button(action)
      |> assign_selected_zero_amount()

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "set-amount",
        %{"amount" => %{"selected_amount" => %{"amount" => amount, "currency" => currency}}},
        socket
      ) do
    {:noreply, assign_selected_amount(socket, Money.new(currency, amount))}
  end

  @impl true
  def handle_event("set-amount", %{"amount" => amount, "currency" => currency}, socket) do
    socket =
      socket
      |> assign_close_input_amount()
      |> assign_selected_button(Money.new(currency, amount))
      |> assign_selected_amount(Money.new(currency, amount))

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "change-amount",
        %{"keypad_amount" => %{"selected_amount" => %{"amount" => ""}}},
        socket
      ) do
    {:noreply, assign_selected_zero_amount(socket)}
  end

  @impl true
  def handle_event(
        "change-amount",
        %{
          "keypad_amount" => %{"selected_amount" => %{"amount" => amount, "currency" => currency}}
        },
        socket
      ) do
    {:noreply, assign_selected_amount(socket, Money.new(currency, amount))}
  end

  def build_active_button(%{preset_button: button_value} = assigns)
      when is_binary(button_value) do
    ~H"""
    <button
      phx-value-button_value={@preset_button}
      phx-click="action"
      phx-target={@myself}
      class={
        "btn py-4 #{if(@selected_button in ["input", "OTHER"], do: @active_button_attributes, else: "bg-grey-medium border-none")}"
      }
    >
      <%= @preset_button %>
    </button>
    """
  end

  def build_active_button(%{preset_button: %Money{}} = assigns) do
    ~H"""
    <button
      phx-value-amount={@preset_button.amount}
      phx-value-currency={@preset_button.currency}
      phx-click="set-amount"
      class={
        "btn py-4 #{if(is_selected_button?(@selected_button, @preset_button), do: @active_button_attributes, else: "bg-grey-medium border-none")}"
      }
    >
      <%= @preset_button %>
    </button>
    """
  end

  @spec assign_show_input_amount(Socket.t()) :: Socket.t()
  def assign_show_input_amount(%{assigns: %{selected_button: nil}} = socket), do: socket
  def assign_show_input_amount(%{assigns: %{selected_button: %Money{}}} = socket), do: socket

  def assign_show_input_amount(socket) do
    assign_open_input_amount(socket)
  end

  @spec assign_open_input_amount(Socket.t()) :: Socket.t()
  def assign_open_input_amount(socket) do
    assign(socket, :show_input_amount, true)
  end

  @spec assign_close_input_amount(Socket.t()) :: Socket.t()
  def assign_close_input_amount(socket) do
    assign(socket, :show_input_amount, false)
  end

  @spec assign_selected_button(Socket.t(), any()) :: Socket.t()
  def assign_selected_button(socket, button) do
    assign(socket, :selected_button, button)
  end

  @spec assign_selected_zero_amount(Socket.t()) :: Socket.t()
  def assign_selected_zero_amount(socket) do
    assign(socket, :selected_amount, @zero_money)
  end

  @spec assign_selected_amount(Socket.t(), Money.t()) :: Socket.t()
  def assign_selected_amount(socket, amount) do
    assign(socket, :selected_amount, amount)
  end

  @spec assign_preset_buttons(Socket.t()) :: Socket.t()
  def assign_preset_buttons(%{assigns: %{buttons: buttons}} = socket) do
    assign_new(socket, :preset_buttons, fn -> Enum.map(buttons, &maybe_create_money/1) end)
  end

  @doc """
  If the number is integer creates Money struct out of it.
  """
  @spec maybe_create_money(integer() | binary()) :: Money.t() | binary()
  def maybe_create_money(value) when is_binary(value), do: value
  def maybe_create_money(value) when is_integer(value), do: Money.new(:USD, value)

  @doc """
  Checks if the button should be disabled.
  """
  @spec disable_button?(Money.t() | binary(), Money.t(), Money.t()) :: boolean()
  def disable_button?(other_value, max_amount, min_amount) when is_binary(other_value) do
    Money.compare(max_amount, min_amount) != :gt
  end

  def disable_button?(money, max_amount, min_amount) do
    Money.compare(money, max_amount) == :gt or Money.compare(money, min_amount) == :lt
  end

  @doc """
  Checks if the amount that is currently selected is from button
  """
  @spec is_selected_button?(nil | Money.t(), Money.t()) :: false | true
  def is_selected_button?(selected_amount, present_amount) when is_binary(selected_amount) do
    is_binary(present_amount) || false
  end

  def is_selected_button?(selected_amount, present_amount) do
    selected_amount && Money.compare(selected_amount, present_amount) == :eq
  end
end
