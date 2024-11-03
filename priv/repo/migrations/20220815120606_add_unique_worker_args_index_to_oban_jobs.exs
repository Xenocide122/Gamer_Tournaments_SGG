defmodule Strident.Repo.Migrations.AddUniqueWorkerArgsIndexToObanJobs do
  use Ecto.Migration

  def change do
    create unique_index(:oban_jobs, [:worker, :args], name: :oban_jobs_unique_worker_args_index)
  end
end
