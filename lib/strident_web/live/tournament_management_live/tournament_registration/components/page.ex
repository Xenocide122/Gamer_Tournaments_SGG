defmodule StridentWeb.TournamentRegistrationLive.Components.Page do
  @moduledoc false
  use Phoenix.Component

  import StridentWeb.Components.Containers

  alias Phoenix.Naming

  def progress(assigns) do
    ~H"""
    <div class="relative mb-2 md:w-96">
      <div class="sticky top-24">
        <.card colored class="flex flex-col card--glowing-two-tone p-0.5 h-fit">
          <ul class="w-full wizard-steps">
            <%= for page <- @pages do %>
              <li class={
                "xl:flex text-center items-center #{if page == @current_page or page in @steps_completed, do: "active"}"
              }>
                <%= Naming.humanize(page) %>
              </li>
            <% end %>
          </ul>
        </.card>
      </div>
    </div>
    """
  end

  attr(:id, :string)
  attr(:return_to, :string, default: "/")
  attr(:next, :atom, default: nil)
  attr(:previous, :atom, default: nil)
  attr(:current_page, :atom, default: nil)
  attr(:terms_and_conditions, :boolean, default: false)

  def terms_and_conditions(assigns) do
    ~H"""
    <div class="p-0 m-0">
      <.card colored id="terms-and-conditions" class="card--glowing-two-tone p-0.5">
        <div class="px-8">
          <h3 id="heading" class="w-full py-2 mb-4 text-left text-white uppercase">
            Terms and Conditions
          </h3>
          <div class="justify-start mx-2 mb-8 text-base font-light text-grey-800">
            <div class="mb-4 overflow-auto h-96">
              <StridentWeb.Components.TermsOfUse.tournament_registration_terms />
            </div>
          </div>
          <div class="flex font-semibold text-secondary uppercase border p-6 rounded-md border-secondary mx-2 mb-8">
            <p>I am 13 years or older.</p>
          </div>
          <div class="flex justify-end mx-2 mb-8 text-base font-light align-middle text-grey">
            <div class={
              "flex items-center justify-center flex-shrink-0 w-10 h-10 mr-2 bg-transparent border-2 #{if(@terms_and_conditions, do: "border-primary", else: "border-grey-light")}"
            }>
              <input
                class="absolute w-10 h-10 opacity-0"
                type="checkbox"
                id="terms-and-conditions-check"
                phx-click="clicked-terms"
                checked={@terms_and_conditions}
              />
              <svg
                class="hidden w-10 h-10 transition pointer-events-none fill-primary"
                viewBox="0 0 20 20"
              >
                <path d={StridentWeb.Common.SvgUtils.path(:solid_check)} />
              </svg>
            </div>
            <div class={
              "mt-1 text-xl " <>
                if(@terms_and_conditions, do: "text-primary", else: "text-white")
            }>
              I have read and accepted the terms & agreements
            </div>
          </div>
        </div>
      </.card>
      <.navigation
        current_page={@current_page}
        next={@next}
        previous={@previous}
        return_to={@return_to}
        terms_and_conditions={@terms_and_conditions}
      />
    </div>
    """
  end

  attr(:id, :string)
  attr(:terms_and_conditions, :boolean, default: false)
  attr(:return_to, :string, default: "/")
  attr(:next, :atom, default: nil)
  attr(:previous, :atom, default: nil)
  attr(:current_page, :atom, default: nil)
  attr(:party, :any)
  attr(:tournament, :any)

  def accept(assigns) do
    ~H"""
    <div class="p-0 m-0">
      <.card colored id="accept-party-invite" class="card--glowing-two-tone p-0.5">
        <div class="px-8">
          <h3 id="heading" class="w-full py-2 mb-4 text-left text-white uppercase">
            Party Registration
          </h3>
          <div class="justify-start mx-2 mb-8 text-base font-light text-grey-800">
            Accept an invitation to join <%= @party.name %> and play in the <%= @tournament.title %> tournament
          </div>
        </div>
      </.card>
      <.navigation
        current_page={@current_page}
        next={@next}
        previous={@previous}
        return_to={@return_to}
      />
    </div>
    """
  end

  attr(:next, :atom, default: nil)
  attr(:previous, :atom, default: nil)
  attr(:return_to, :string, default: "/")
  attr(:current_page, :atom, default: nil)
  attr(:terms_and_conditions, :boolean, default: false)
  attr(:template_id, :string, default: "")
  attr(:persona_environment, :string, default: "")
  attr(:identified, :boolean)
  attr(:current_user, :any)
  attr(:verified?, :boolean)

  def navigation(assigns) do
    ~H"""
    <div>
      <div class="flex justify-between mt-10 xl:flex-row gap-x-6 gap-y-6">
        <%= if is_nil(@previous) do %>
          <button
            id="back-button"
            type="button"
            class="font-bold px-2 md:px-8 py-3 text-base !no-underline uppercase border-white border-2 rounded-lg btn--primary font-display md:text-3xl text-center align-center"
            phx-click="cancel"
            phx-value-to={@return_to}
            phx-hook="ScrollToTop"
          >
            Cancel
          </button>
        <% else %>
          <button
            id="back-button"
            type="button"
            class="ffont-bold px-2 md:px-8 py-3 text-base !no-underline uppercase border-white border-2 rounded-lg btn--primary font-display md:text-3xl text-center align-center"
            phx-click="back"
            phx-value-current_page={@current_page}
            phx-hook="ScrollToTop"
          >
            Back
          </button>
        <% end %>

        <%= case @current_page do %>
          <% :terms -> %>
            <button
              type="button"
              id={"#{@next}-button"}
              class="font-normal tracking-wide btn btn--wide btn--primary disabled:opacity-50 px-10 py-1.5"
              phx-click="next"
              phx-value-current_page={@current_page}
              disabled={not @terms_and_conditions}
              phx-hook="ScrollToTop"
            >
              Next
            </button>
          <% :accept -> %>
            <button
              type="button"
              id="accept-party-invite-button"
              class="font-normal tracking-wide btn btn--wide btn--primary disabled:opacity-50 px-10 py-1.5"
              phx-click="accept-party-invitation"
              phx-value-current_page={@current_page}
              phx-hook="ScrollToTop"
            >
              Accept invitation
            </button>
          <% _ -> %>
            <button
              type="button"
              id={"#{@next}-button"}
              class="font-normal tracking-wide btn btn--wide btn--primary disabled:opacity-50 px-10 py-1.5"
              phx-click="next"
              phx-value-current_page={@current_page}
              phx-hook="ScrollToTop"
            >
              Next
            </button>
        <% end %>
      </div>
    </div>
    """
  end
end
