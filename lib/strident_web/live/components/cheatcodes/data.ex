defmodule StridentWeb.Components.Cheatcodes.Data do
  @moduledoc false
  @key_codes_by_label %{
    "left" => 37,
    "up" => 38,
    "right" => 39,
    "down" => 40,
    "a" => 65,
    "b" => 66,
    "c" => 67,
    "i" => 73,
    "e" => 69,
    "k" => 75,
    "o" => 79,
    "slash" => 191
  }

  @hyu fn x ->
    Enum.map(x, &Map.get(@key_codes_by_label, &1))
  end

  @konami_code ["up", "up", "down", "down", "left", "right", "left", "right", "b", "a"]
  @clear_cookies_code [
    "up",
    "up",
    "down",
    "down",
    "left",
    "right",
    "left",
    "right",
    "c",
    "o",
    "o",
    "k",
    "i",
    "e"
  ]

  @konami_key_codes @hyu.(@konami_code)
  @clear_cookies_key_codes @hyu.(@clear_cookies_code)

  def key_codes(:konami), do: @konami_key_codes
  def key_codes(:clear_cookies), do: @clear_cookies_key_codes

  def key_codes,
    do: Enum.reduce([:konami, :clear_cookies], %{}, &Map.put(&2, &1, key_codes(&1)))
end
