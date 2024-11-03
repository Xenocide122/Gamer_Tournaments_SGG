defmodule Strident.Repo.Migrations.UpdateColAndUniqueIndexGeographicWhitelist do
  use Ecto.Migration

  def change do
    drop_if_exists unique_index(
                     :geographic_whitelists,
                     [:country, :state, :feature],
                     name: :country_state_feature_unique_idx
                   )

    alter table(:geographic_whitelists) do
      remove :state
      remove :country
    end

    alter table(:geographic_whitelists) do
      add :region_code, :citext, null: true
      add :country_code, :citext, null: true
    end

    create unique_index(
             :geographic_whitelists,
             [:country_code, :region_code, :feature],
             name: :country_region_feature_unique_idx
           )
  end
end
