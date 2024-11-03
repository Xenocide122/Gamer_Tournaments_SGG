defmodule StridentWeb.LiveComponentHelpers do
  @moduledoc """
  Useful functions accessible in any LiveComponent
  """
  alias Phoenix.Component
  alias Phoenix.LiveView.Socket

  @default_parent_assigns_to_copy [
    :current_user,
    :anonymous_user_id,
    :timezone,
    :locale,
    :user_return_to,
    :can_stake,
    :can_stake,
    :can_play,
    :can_wager,
    :is_using_vpn,
    :show_vpn_banner,
    :ip_location
  ]
  @doc """
  A convenience function for components to copy assigns
  from their parent
  """
  @spec copy_parent_assigns(Socket.t(), map()) :: Socket.t()
  def copy_parent_assigns(socket, assigns) do
    Component.assign(socket, Map.take(assigns, @default_parent_assigns_to_copy))
  end
end
