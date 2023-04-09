defmodule MyApp.Grocery.Order do
  use Ash.Resource, data_layer: AshPostgres.DataLayer

  postgres do
    table "order"
    repo MyApp.Repo
  end

  actions do
    defaults([:read])

    create :create do
      primary? true
      argument :items, {:array, :map}
      change manage_relationship(:items, type: :create)
    end

    update :update do
      primary? true
      argument :items, {:array, :map}
      change manage_relationship(:items, type: :direct_control)
    end

    read :read_all do
      prepare build(load: [:items], sort: [:email])
    end

    read :get do
      get? true
      argument :id, :uuid, allow_nil?: false
      filter expr(id == ^arg(:id))
      prepare build(load: [:items])
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :email, :string, allow_nil?: false
  end

  relationships do
    has_many :items, MyApp.Grocery.Item do
      destination_attribute :order_id
    end
  end

  code_interface do
    define_for MyApp.Grocery
    define :get, get?: true, args: [:id]
    define :read_all
  end
end
