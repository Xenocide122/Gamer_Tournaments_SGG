defmodule StridentWeb.Components.ProgressBar do
  @moduledoc false
  use Phoenix.Component

  attr(:id, :string, required: true)
  attr(:procentage, :integer, required: true)
  attr(:height, :string, default: "2.5")
  attr(:color, :string, default: "bg-primary")

  def progress_bar(assigns) do
    ~H"""
    <div id={@id}>
      <div class={"flex h-#{@height} mb-1 overflow-hidden text-xs rounded-full bg-grey-medium"}>
        <div
          style={"width:#{@procentage}%"}
          class={"flex flex-col text-center whitespace-nowrap text-white justify-center #{ if(@procentage == 100, do: "gradient", else: @color)}"}
        >
        </div>
      </div>
    </div>
    """
  end
end
