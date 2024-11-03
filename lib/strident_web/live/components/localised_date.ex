defmodule StridentWeb.Components.LocalisedDate do
  @moduledoc false
  import Phoenix.Component
  alias Strident.CldrUtils
  alias Strident.Extension.DateTime

  @type timezone :: String.t()
  @type localised_string :: String.t()
  @type type :: :date | :time | :datetime

  @default_locale Application.compile_env(:strident, :default_locale)
  @default_timezone Application.compile_env(:strident, :default_timezone)

  def localised_datetime(%{datetime: nil} = assigns) do
    ~H"""

    """
  end

  def localised_datetime(assigns) do
    assigns =
      assigns
      |> Map.update!(:datetime, &DateTime.from_naive!(&1, "Etc/UTC"))
      |> Map.put_new(:class, [])
      |> Map.put_new(:type, :datetime)
      |> Map.put_new(:locale, @default_locale)
      |> Map.put_new(:timezone, @default_timezone)

    ~H"""
    <time datetime={@datetime} class={@class}>
      <%= localise(@datetime, @type, @timezone, @locale) %>
    </time>
    """
  end

  def localised_date(assigns) do
    assigns =
      assigns
      |> Map.put_new(:class, [])
      |> Map.put_new(:type, :date)
      |> Map.put_new(:locale, @default_locale)
      |> Map.put_new(:timezone, @default_timezone)

    ~H"""
    <time datetime={@date} class={@class}>
      <%= localise_date(@date, @type, @locale) %>
    </time>
    """
  end

  @spec localise(DateTime.t(), type(), timezone(), CldrUtils.locale_name()) ::
          localised_string()
  defp localise(datetime, type, timezone, locale) do
    timezone = timezone || @default_timezone
    datetime = DateTime.shift_zone!(datetime, timezone)
    tz_code = Calendar.strftime(datetime, "%Z")
    build(datetime, locale, type, tz_code)
  end

  @spec build(DateTime.t(), CldrUtils.locale_name(), type(), timezone()) :: localised_string()
  defp build(datetime, "en-US", type, tz_code),
    do: build(datetime, "en", type, tz_code)

  defp build(datetime, locale, :date, _tz_code) do
    datetime
    |> DateTime.to_date()
    |> localise_date(:date, locale)
  end

  defp build(datetime, locale, :day_and_month, _tz_code) do
    datetime
    |> DateTime.to_date()
    |> localise_date(:day_and_month, locale)
  end

  defp build(datetime, locale, :time, tz_code) do
    datetime
    |> DateTime.to_time()
    |> Strident.Cldr.Time.to_string(locale: locale, format: :short)
    |> then(fn
      {:error, _} ->
        datetime
        |> DateTime.to_time()
        |> Strident.Cldr.Time.to_string(locale: @default_locale, format: :short)

      time ->
        time
    end)
    |> add_timezone(tz_code)
  end

  defp build(datetime, locale, :datetime, tz_code) do
    datetime
    |> Strident.Cldr.DateTime.to_string(locale: locale, format: :short)
    |> then(fn
      {:error, _} ->
        datetime
        |> Strident.Cldr.Time.to_string(locale: @default_locale, format: :short)

      time ->
        time
    end)
    |> add_timezone(tz_code)
  end

  @spec add_timezone({:ok, String.t()}, timezone()) :: localised_string()
  defp add_timezone({:ok, datetime_string}, tz_code) do
    "#{datetime_string} #{tz_code}"
  end

  defp localise_date(date, :date, locale) do
    case Strident.Cldr.Date.to_string(date, locale: locale, format: :short) do
      {:ok, datestring} ->
        datestring

      {:error, _} ->
        Strident.Cldr.Date.to_string(date, locale: @default_locale, format: :short)
        |> elem(1)
    end
  end

  defp localise_date(date, :day_and_month, locale) do
    format = "MMMM dd"

    case Strident.Cldr.Date.to_string(date, locale: locale, format: format) do
      {:error, _} ->
        date
        |> Strident.Cldr.Date.to_string(locale: @default_locale, format: format)
        |> elem(1)

      {:ok, date} ->
        date
    end
  end
end
