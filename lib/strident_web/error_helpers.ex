defmodule StridentWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  use Phoenix.HTML
  alias Ecto.Changeset
  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field, opts \\ []) do
    Enum.map(Keyword.get_values(form.errors, field), fn error ->
      if Keyword.get(opts, :always_show, false) do
        content_tag(:span, translate_error(error), class: "form-feedback--error invalid-feedback")
      else
        content_tag(:span, translate_error(error),
          class: "form-feedback--error invalid-feedback",
          phx_feedback_for: input_name(form, field)
        )
      end
    end)
  end

  @doc """
  Translates an error message using gettext.
  """
  @spec translate_error({binary(), any()}) :: String.t()
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(StridentWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(StridentWeb.Gettext, "errors", msg, opts)
    end
  end

  @spec translate_changeset_errors(Changeset.t()) :: %{atom() => [String.t()]}
  def translate_changeset_errors(changeset) do
    Changeset.traverse_errors(changeset, &translate_error/1)
  end

  @spec put_string_or_changeset_error_in_flash(Socket.t(), String.t() | Changeset.t(), [
          show_changeset_errors_opt()
        ]) :: Socket.t()
  def put_string_or_changeset_error_in_flash(socket, error, opts \\ [])

  def put_string_or_changeset_error_in_flash(socket, %Changeset{} = changeset, opts) do
    put_humanized_changeset_errors_in_flash(socket, changeset, opts)
  end

  def put_string_or_changeset_error_in_flash(socket, flash_message, _opts)
      when is_binary(flash_message) do
    LiveView.put_flash(socket, :error, flash_message)
  end

  @type show_changeset_errors_opt() :: {:exclude_field, boolean()}
  @doc """
  Puts all changeset errors in the socket's flash, in a readable format.
  """
  @spec put_humanized_changeset_errors_in_flash(Socket.t(), Changeset.t(), [
          show_changeset_errors_opt()
        ]) :: Socket.t()
  def put_humanized_changeset_errors_in_flash(socket, changeset, opts \\ []) do
    exclude_field = Keyword.get(opts, :exclude_field, false)

    changeset
    |> translate_changeset_errors()
    |> Enum.reduce(socket, fn {field, message}, socket ->
      humanized_field = humanize(field)
      flash_message = if exclude_field, do: message, else: "#{humanized_field} #{message}"
      LiveView.put_flash(socket, :error, flash_message)
    end)
  end

  @doc """
  Consistent error message for times when we really don't want to be helpful

  An good example where this is used is with the MatchesGraph,
  where the client technically has the necessary JS to send "mark winner"
  and "set score" events to the LiveView.
  In these cases, the `handle_event` function need to check the current user
  is actually allowed to do these things.
  For a normal user, this simply doesn't happen. The javascript only renders
  the necessary HTML elements if the LiveView determined the user is, e.g. staff.
  For a naughty javascript hacker kid, this could happen. We allow the
  server to berate them with a spicy Rick and Morty reference.
  """
  @spec berate_javascript_hacker_kid(Socket.t()) :: Socket.t()
  def berate_javascript_hacker_kid(socket) do
    LiveView.put_flash(socket, :error, "Get up on outta here with my eye holes!")
  end
end
