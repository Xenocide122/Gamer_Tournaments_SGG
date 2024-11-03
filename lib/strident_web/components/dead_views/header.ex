defmodule StridentWeb.DeadViews.Header do
  @moduledoc """
  Common header component with an underline.
  """
  use Phoenix.Component

  attr(:text, :string, required: true)

  def underline_header(assigns) do
    ~H"""
    <div class="flex flex-col items-center md:items-start">
      <div class="w-fit">
        <h4 class="min-w-max">
          <%= @text %>
        </h4>
        <div class="mt-0.5 mb-2 mx-2 md:ml-0 md:mr-5 bg-primary rounded-full h-1"></div>
      </div>
    </div>
    """
  end
end
