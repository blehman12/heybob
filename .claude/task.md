## Task: #9 Event Lifecycle Status

Working directory: /mnt/c/evm1
Rails 7.1 app. Ruby 3.3.3. PostgreSQL.

Add a `lifecycle_status` field to events with four states:
- `draft` (0) — being set up, not publicly visible
- `published` (1) — live and visible (DEFAULT — keeps existing events working)
- `archived` (2) — past/closed, read-only
- `cancelled` (3) — cancelled

---

### Step 1: Migration

Generate and run:
```
bundle exec rails generate migration AddLifecycleStatusToEvents lifecycle_status:integer
```

Then edit the generated migration file to set default and null constraint:
```ruby
add_column :events, :lifecycle_status, :integer, default: 1, null: false
add_index :events, :lifecycle_status
```
(Remove the auto-generated line and replace with these two.)

Run: `bundle exec rails db:migrate`

---

### Step 2: Event model (app/models/event.rb)

Add the enum after the existing `event_type` enum:
```ruby
enum lifecycle_status: { draft: 0, published: 1, archived: 2, cancelled: 3 }
```

Update `rsvp_available?` to also require published status:
```ruby
def rsvp_available?
  hosted? && rsvp_open? && published?
end
```

Add a scope for the public-facing query (below existing scopes):
```ruby
scope :publicly_visible, -> { where(lifecycle_status: :published) }
```

---

### Step 3: Admin events controller (app/controllers/admin/events_controller.rb)

Add `lifecycle_status` to the permitted params in the `event_params` private method.

Add a `update_status` action after the `destroy` action:
```ruby
def update_status
  @event = Event.find(params[:id])
  if @event.update(lifecycle_status: params[:lifecycle_status])
    redirect_to admin_event_path(@event), notice: "Event status updated to #{@event.lifecycle_status.humanize}."
  else
    redirect_to admin_event_path(@event), alert: "Could not update status."
  end
end
```

---

### Step 4: Routes (config/routes.rb)

Inside the admin namespace events resources block, add a member route:
```ruby
member do
  patch :update_status
end
```

---

### Step 5: Admin index view (app/views/admin/events/index.html.erb)

In the table header row, add a "Status" column header after the event name/date columns.

In each table row, add a status badge cell:
```erb
<td>
  <span class="badge <%= lifecycle_status_badge_class(event) %>">
    <%= event.lifecycle_status.humanize %>
  </span>
</td>
```

---

### Step 6: Admin show view (app/views/admin/events/show.html.erb)

Near the top of the page (next to the event name/title area), add a status badge:
```erb
<span class="badge <%= lifecycle_status_badge_class(@event) %> fs-6">
  <%= @event.lifecycle_status.humanize %>
</span>
```

Below that, add quick-change status buttons (only show statuses different from current):
```erb
<div class="mt-2 mb-3">
  <small class="text-muted me-2">Change status:</small>
  <% Event.lifecycle_statuses.keys.reject { |s| s == @event.lifecycle_status }.each do |status| %>
    <%= button_to status.humanize,
        update_status_admin_event_path(@event),
        params: { lifecycle_status: status },
        method: :patch,
        class: "btn btn-sm btn-outline-secondary me-1",
        data: { confirm: "Change status to #{status.humanize}?" } %>
  <% end %>
</div>
```

---

### Step 7: Admin form (app/views/admin/events/_form.html.erb)

Add a status select field near the top of the form (after the event type selector):
```erb
<div class="mb-3">
  <%= form.label :lifecycle_status, "Lifecycle Status", class: "form-label" %>
  <%= form.select :lifecycle_status,
      Event.lifecycle_statuses.keys.map { |s| [s.humanize, s] },
      {},
      class: "form-select" %>
  <div class="form-text">Draft = not visible publicly. Published = live. Archived/Cancelled = closed.</div>
</div>
```

---

### Step 8: Helper method (app/helpers/application_helper.rb or events_helper.rb)

Add this helper method:
```ruby
def lifecycle_status_badge_class(event)
  case event.lifecycle_status
  when 'draft'      then 'bg-secondary'
  when 'published'  then 'bg-success'
  when 'archived'   then 'bg-warning text-dark'
  when 'cancelled'  then 'bg-danger'
  else 'bg-secondary'
  end
end
```

---

### Step 9: Public events controller (app/controllers/public_events_controller.rb)

In the `show` action, after finding the event by slug, add a check:
```ruby
redirect_to root_path, alert: "Event not found." and return unless @event.published?
```

---

### Step 10: Specs

Create or add to spec/models/event_spec.rb:

```ruby
describe 'lifecycle_status' do
  it 'defaults to published' do
    event = build(:event)
    expect(event.lifecycle_status).to eq('published')
  end

  it 'has the correct statuses' do
    expect(Event.lifecycle_statuses.keys).to match_array(%w[draft published archived cancelled])
  end

  it 'rsvp_available? is false when draft' do
    event = build(:event, event_type: :hosted, rsvp_deadline: 1.day.from_now, lifecycle_status: :draft)
    expect(event.rsvp_available?).to be false
  end

  it 'rsvp_available? is true when published and rsvp open' do
    event = build(:event, event_type: :hosted, rsvp_deadline: 1.day.from_now, lifecycle_status: :published)
    expect(event.rsvp_available?).to be true
  end
end
```

Run: `bundle exec rspec spec/models/event_spec.rb --format documentation`

Report full output. If tests fail, fix before proceeding.
