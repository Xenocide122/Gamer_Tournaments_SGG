defmodule StridentWeb.Schema.Middleware.MaxQueryDepth do
  @moduledoc """
  Prevents deep nested queries


  This query is very expensive:

  ```graphql
    participants {
      tournamentParticipant {
        nextMatch {
    participants {
      tournamentParticipant {
        nextMatch {
    participants {
      tournamentParticipant {
        nextMatch {
    participants {
      tournamentParticipant {
        nextMatch {
    participants {
      tournamentParticipant {
        nextMatch {
        }
      }
    }
        }
      }
    }
        }
      }
    }
        }
      }
    }
        }
      }
    }
  ```

  Don't attempt to keep resolving a query when it is too deep (expensive).
  """
  require Logger
  alias Absinthe.Blueprint.Document.Field
  alias Absinthe.Blueprint.Document.Fragment.Spread

  @allowed_max_depth 10

  @error_message "Too deeeeeeeeeep...max depth is #{@allowed_max_depth}"

  def call(resolution, _) do
    max_depth = max_depth(resolution.definition)

    if max_depth > @allowed_max_depth do
      Logger.warning("Erroring too-deep query resolution. Is at least #{max_depth} deep.")
      result = {:error, [{:message, @error_message}, {:status_code, 400}]}
      Absinthe.Resolution.put_result(resolution, result)
    else
      resolution
    end
  end

  defp max_depth(resolution), do: depth_of_deepest_selection(resolution.selections)

  @type depth :: non_neg_integer
  @type selection :: Field.t() | Spread.t()

  @spec depth_of_deepest_selection([selection], depth, depth) :: depth
  defp depth_of_deepest_selection(selections, depth \\ 0, acc \\ 0)
  defp depth_of_deepest_selection([], _, acc), do: acc
  defp depth_of_deepest_selection(_, depth, _) when depth > @allowed_max_depth, do: depth
  defp depth_of_deepest_selection(_, _, acc) when acc > @allowed_max_depth, do: acc

  defp depth_of_deepest_selection(selections, depth, acc) do
    Enum.reduce_while(selections, acc, fn selection, acc ->
      if acc > @allowed_max_depth do
        {:halt, acc}
      else
        next_depth = depth + 1
        next_acc = max(next_depth, acc)

        case selection do
          %Field{selections: selections} ->
            if next_acc > @allowed_max_depth do
              {:cont, next_acc}
            else
              {:cont, depth_of_deepest_selection(selections, next_depth, next_acc)}
            end

          %Spread{} ->
            {:cont, next_acc}

          unanticipated_type_of_selection ->
            Logger.info(
              "Unanticapted query selection type #{inspect(unanticipated_type_of_selection)}"
            )

            Logger.warning("Unanticapted query selection type")
            {:cont, next_acc}
        end
      end
    end)
  end
end
