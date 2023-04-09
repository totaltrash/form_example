defmodule MyApp.Grocery.Item do
  use Ash.Resource, data_layer: AshPostgres.DataLayer

  postgres do
    table "item"
    repo MyApp.Repo
  end

  actions do
    defaults([:create, :read, :update, :destroy])
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :amount, :integer, allow_nil?: false
  end

  relationships do
    belongs_to :order, MyApp.Grocery.Order do
      allow_nil? false
    end
  end
end
