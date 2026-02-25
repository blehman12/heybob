module ApplicationHelper
  include AdminHelper

  def lifecycle_status_badge_class(event)
    case event.lifecycle_status
    when 'draft'      then 'bg-secondary'
    when 'published'  then 'bg-success'
    when 'archived'   then 'bg-warning text-dark'
    when 'cancelled'  then 'bg-danger'
    else 'bg-secondary'
    end
  end
end
