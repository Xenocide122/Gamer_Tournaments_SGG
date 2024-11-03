defmodule Strident.Repo.Local.Migrations.CreateTournamentsPageInfoCard do
  use Ecto.Migration

  def change do
    create table(:tournaments_page_info_card, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :header, :text
      add :body, :text
      add :background_image_url, :string
      add :button_text, :text
      add :button_url, :string
      add :hidden, :boolean, default: true
      add :sort_index, :integer, default: 0
    end
  end
end
