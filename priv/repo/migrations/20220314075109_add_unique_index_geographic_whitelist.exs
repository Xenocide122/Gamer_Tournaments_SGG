defmodule Strident.Repo.Migrations.AddUniqueIndexGeographicWhitelist do
  use Ecto.Migration

  def change do
    create unique_index(
             :geographic_whitelists,
             [:country, :state, :feature],
             name: :country_state_feature_unique_idx
           )
  end
end
