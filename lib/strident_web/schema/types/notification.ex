defmodule StridentWeb.Schema.Types.Notification do
  @moduledoc false

  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  @desc "A User within our system, meant for private consumption."
  object :notification do
    field(:id, non_null(:string))
    field(:user, non_null(:user), resolve: dataloader(:data))
    field(:level, non_null(:level_type))
    field(:data, non_null(:json))
    field(:is_unread, non_null(:boolean))
    field(:deleted_at, :naive_datetime)
    field(:inserted_at, non_null(:naive_datetime))
    field(:updated_at, non_null(:naive_datetime))
  end

  enum :level_type do
    value(:info)
    value(:urgent)
  end
end
