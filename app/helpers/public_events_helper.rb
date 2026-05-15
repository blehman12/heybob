module PublicEventsHelper
  def vendor_pin_popover(ve)
    html = "<strong>#{h ve.vendor.name}</strong><br>"
    html += "<span class='text-muted small'>Booth #{h ve.booth_number} &middot; #{h ve.category_label}</span><br>"
    html += "<a href='#{public_vendor_path(ve.vendor)}' class='btn btn-sm btn-outline-primary mt-1'>View Profile</a>"
    html
  end

  def pin_hex_color(category)
    case category.to_s
    when 'dealer'       then '#0d6efd'
    when 'artist_alley' then '#e6a817'
    when 'sponsor'      then '#198754'
    when 'exhibitor'    then '#0dcaf0'
    when 'panelist'     then '#6c757d'
    else '#0d6efd'
    end
  end

  def pin_color_class(category)
    case category.to_s
    when 'dealer'       then 'pin-dealer'
    when 'artist_alley' then 'pin-artist-alley'
    when 'sponsor'      then 'pin-sponsor'
    when 'exhibitor'    then 'pin-exhibitor'
    when 'panelist'     then 'pin-panelist'
    else 'pin-dealer'
    end
  end
end
