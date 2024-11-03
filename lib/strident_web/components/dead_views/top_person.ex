defmodule StridentWeb.DeadViews.TopPersons do
  @moduledoc """
  Top Persons Dead View renders a given list of
  given Users as a standard componet to use in the project.
  """
  use Phoenix.Component
  import StridentWeb.DeadViews.Header
  alias Strident.Accounts
  alias StridentWeb.Endpoint
  alias StridentWeb.Router.Helpers, as: Routes

  attr(:id, :string, default: nil)
  attr(:header_text, :string, required: true)
  attr(:top_persons, :list, default: [])

  def top_persons(assigns) do
    ~H"""
    <div id={@id}>
      <.underline_header text={@header_text} />

      <p :if={Enum.empty?(@top_persons)} class="mt-2 text-xs text-grey-light">
        No contributors yet, be the first and support this tournament!
      </p>

      <div :if={Enum.any?(@top_persons)} class="relative grid grid-cols-5 gap-4 mt-2 mb-12">
        <div :for={{person, index} <- Enum.with_index(@top_persons, 1)} id={"top-person-#{person.id}"}>
          <div class="flex content-center space-x-2 justify-left">
            <div>
              <h4 class="text-muted mb-0.5"><%= pad_num(index) %></h4>
              <div class="staker-underline" />
            </div>
            <img src={Accounts.avatar_url(person)} alt="avatar" class="rounded-full w-9 h-9" />
          </div>
          <div>
            <.link
              navigate={Routes.user_show_path(Endpoint, :show, person.slug)}
              class="mt-1 no-underline text-primary"
            >
              <%= person.display_name %>
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp pad_num(number) do
    number
    |> Integer.to_string()
    |> String.pad_leading(2, "0")
  end
end
