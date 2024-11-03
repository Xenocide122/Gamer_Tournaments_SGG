defmodule Strident.ChatLive.DeadView do
  @moduledoc false
  use Phoenix.Component
  alias Strident.Accounts
  alias Strident.Accounts.User

  attr(:typing_usernames, :list, default: [])

  def typing_template(assigns) do
    ~H"""
    <div :if={Enum.any?(@typing_usernames)} class="flex mt-2 text-sm italic text-grey-light">
      <p :if={Enum.count(@typing_usernames) == 1}>
        <%= join_display_names(@typing_usernames) %> is typing
      </p>

      <p :if={Enum.count(@typing_usernames) > 1}>
        <%= join_display_names(@typing_usernames) %> are typing
      </p>

      <div :for={num <- 1..3} class={"delay-#{num * 333} duration-1000 animate-bounce"}>.</div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:user, User, required: true)
  attr(:type, :string, required: true)
  attr(:inactive?, :boolean, default: false)
  slot(:text)

  def chat_participant_template(assigns) do
    ~H"""
    <div id={@id} class={["flex items-center", if(@inactive?, do: "opacity-50")]}>
      <img
        src={Accounts.avatar_url(@user)}
        alt="User"
        width="15"
        height="15"
        class="object-scale-down mr-1 rounded-full"
      />
      <p :if={@type == "admin"} class="mr-0 text-primary">
        <%= Accounts.user_display_name(@user) %>
      </p>

      <p :if={@type == "player_0"} class="mr-0 text-grilla-pink">
        <%= Accounts.user_display_name(@user) %>
      </p>

      <p :if={@type == "player_1"} class="mr-0 text-grilla-blue">
        <%= Accounts.user_display_name(@user) %>
      </p>

      <p :if={@type == "admin"} class="mr-2 text-primary">
        <%= render_slot(@text) %>
      </p>

      <p :if={@type == "player_0"} class="mr-2 text-grilla-pink">
        <%= render_slot(@text) %>
      </p>

      <p :if={@type == "player_1"} class="mr-2 text-grilla-blue">
        <%= render_slot(@text) %>
      </p>
    </div>
    """
  end

  defp join_display_names([one]), do: one
  defp join_display_names([one, two]), do: "#{one} and #{two}"

  defp join_display_names(list) when length(list) < 4 do
    [last | base_list] = Enum.reverse(list)

    base_str =
      base_list
      |> Enum.reverse()
      |> Enum.join(", ")

    "#{base_str}, and #{last}"
  end

  defp join_display_names(_list), do: "Several people"
end
