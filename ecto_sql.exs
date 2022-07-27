# Credit: https://github.com/wojtekmach/mix_install_examples/blob/main/ecto_sql.exs

Mix.install([
  {:ecto_sql, "~> 3.7.0"},
  {:postgrex, "~> 0.15.0"}
])

Application.put_env(:app, Repo, database: "mix_install_examples")

defmodule Repo do
  use Ecto.Repo,
    adapter: Ecto.Adapters.Postgres,
    otp_app: :app
end

defmodule Migration0 do
  use Ecto.Migration

  def change do
    create table("posts") do
      add(:title, :string)
      timestamps(type: :utc_datetime_usec)
    end

    create table("comments") do
      add(:text, :string)
      add(:post_id, references(:posts, on_delete: :delete_all))
    end
  end
end

defmodule Post do
  use Ecto.Schema

  schema "posts" do
    field(:title, :string)
    timestamps(type: :utc_datetime_usec)
    has_many(:comments, Comment)
  end
end

defmodule Comment do
  use Ecto.Schema

  schema "comments" do
    field(:text, :string)
    belongs_to(:post, Post)
  end
end

defmodule Main do
  import Ecto.Query

  def main do
    children = [
      Repo
    ]

    _ = Repo.__adapter__().storage_down(Repo.config())
    :ok = Repo.__adapter__().storage_up(Repo.config())

    {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)

    Ecto.Migrator.run(Repo, [{0, Migration0}], :up, all: true)

    insert_data()
    query_data()
  end

  def insert_data do
    post = %Post{title: "Hello, World!"} |> Repo.insert!()
    %Comment{post_id: post.id, text: "A comment"}  |> Repo.insert!()
  end

  def query_data do
    query = from Post, preload: [:comments]
    IO.inspect(Repo.all(query))
  end
end

Main.main()
