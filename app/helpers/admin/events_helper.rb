module Admin::EventsHelper
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
