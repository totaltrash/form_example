defmodule MyAppWeb.GroceryLive do
  use MyAppWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Groceries
      <:actions>
        <.link patch={~p"/create"} class="text-sky-600 hover:text-sky-700 font-medium">
          Add Grocery Order
        </.link>
      </:actions>
    </.header>
    <.modal :if={@form} show id="form_modal" on_cancel={JS.patch(~p"/")}>
      <.simple_form for={@form} phx-change="validate" phx-submit="submit">
        <.input type="email" label="Email" field={@form[:email]} />
        <.inputs_for :let={item_form} field={@form[:items]}>
          <div class="flex flex-row gap-2">
            <div class="grow">
              <.input type="text" label="Item" field={item_form[:name]} />
            </div>
            <.input type="number" label="Amount" field={item_form[:amount]} />
            <.button
              type="button"
              class="h-10 mt-8 w-24"
              phx-click="remove_form"
              phx-value-path={item_form.name}
            >
              Remove
            </.button>
          </div>
        </.inputs_for>
        <.button class="w-full" type="button" phx-click="add_form" phx-value-path={@form[:items].name}>
          Add Item
        </.button>
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
    </.modal>
    <.table id="orders" rows={@orders}>
      <:col :let={order} label="ID">
        <.link patch={~p"/update/#{order.id}"} class="text-sky-600 hover:text-sky-700">
          <%= order.id %>
        </.link>
      </:col>
      <:col :let={order} label="Email">
        <%= order.email %>
      </:col>
      <:col :let={order} label="Items">
        <ul>
          <%= for item <- order.items do %>
            <li><%= item.name %> (<%= item.amount %>)</li>
          <% end %>
        </ul>
      </:col>
    </.table>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :orders, MyApp.Grocery.Order.read_all!())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, params, socket.assigns.live_action)}
  end

  defp apply_action(socket, _params, :index) do
    assign(socket, :form, nil)
  end

  defp apply_action(socket, _params, :create) do
    form =
      MyApp.Grocery.Order
      |> AshPhoenix.Form.for_create(:create,
        api: MyApp.Grocery,
        forms: [
          items: [
            type: :list,
            resource: MyApp.Grocery.Item,
            create_action: :create
          ]
        ]
      )
      |> AshPhoenix.Form.add_form([:items], params: %{"name" => "Melon", "amount" => 1})
      |> AshPhoenix.Form.add_form([:items], params: %{"name" => "Grapes", "amount" => 3})
      |> to_form()

    assign(socket, form: form)
  end

  defp apply_action(socket, %{"id" => id}, :update) do
    form =
      MyApp.Grocery.Order.get!(id)
      |> AshPhoenix.Form.for_update(:update,
        api: MyApp.Grocery,
        forms: [auto?: true]
      )
      |> to_form()

    assign(socket, form: form)
  end

  @impl true
  def handle_event("validate", %{"form" => params}, socket) do
    {:noreply, assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, params))}
  end

  def handle_event("submit", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
      {:ok, order} ->
        {:noreply,
         socket
         |> put_flash(:info, "Saved order for #{order.email}!")
         |> push_navigate(to: ~p"/")}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  def handle_event("add_form", %{"path" => path}, socket) do
    {:noreply, assign(socket, form: AshPhoenix.Form.add_form(socket.assigns.form, path))}
  end

  def handle_event("remove_form", %{"path" => path}, socket) do
    {:noreply, assign(socket, form: AshPhoenix.Form.remove_form(socket.assigns.form, path))}
  end
end
