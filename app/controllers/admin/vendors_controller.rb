require 'csv'

class Admin::VendorsController < Admin::BaseController

  def index
    @vendors = Vendor.with_attached_hero_image.includes(:user, :events).order(:name).page(params[:page]).per(25)
  end

  def show
    @vendor = Vendor.includes(:vendor_events => :event).find(params[:id])
  end

  def new
    @vendor = Vendor.new
  end

  def create
    owner_email = vendor_params[:owner_email]
    owner, owner_error = find_or_create_owner(owner_email)

    if owner_error
      @vendor = Vendor.new(vendor_params.except(:owner_email))
      flash.now[:alert] = owner_error
      render :new, status: :unprocessable_entity
      return
    end

    @vendor = Vendor.new(vendor_params.except(:owner_email))
    @vendor.user = owner if owner
    if @vendor.save
      redirect_to admin_vendor_path(@vendor), notice: 'Vendor created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @vendor = Vendor.find(params[:id])
  end

  def update
    @vendor = Vendor.find(params[:id])
    if @vendor.update(vendor_params.except(:owner_email))
      redirect_to admin_vendor_path(@vendor), notice: 'Vendor updated.'
    else
      render :edit
    end
  end

  def destroy
    @vendor = Vendor.find(params[:id])
    @vendor.destroy
    redirect_to admin_vendors_path, notice: 'Vendor deleted.'
  end

  def send_password_reset
    @vendor = Vendor.find(params[:id])
    owner = @vendor.user
    if owner
      owner.send_reset_password_instructions
      redirect_to admin_vendor_path(@vendor), notice: "Password reset email sent to #{owner.email}."
    else
      redirect_to admin_vendor_path(@vendor), alert: "This vendor has no owner account."
    end
  end

  # GET /admin/vendors/import
  def import_form
  end

  # POST /admin/vendors/import
  def import
    unless params[:csv_file].present?
      redirect_to import_form_admin_vendors_path, alert: 'Please select a CSV file.'
      return
    end

    results = process_vendor_csv(params[:csv_file], params[:event_id])

    if results[:errors].any?
      flash[:alert] = "Import completed with #{results[:errors].count} error(s). " \
                      "Created #{results[:created]} vendors. " \
                      "Errors: #{results[:errors].first(3).join('; ')}"
    else
      flash[:notice] = "Successfully imported #{results[:created]} vendors!"
    end

    redirect_to admin_vendors_path
  end

  # GET /admin/vendors/export
  def export
    vendors = Vendor.includes(:user, :events).order(:name)

    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['name', 'description', 'hook_line', 'website',
              'owner_email', 'owner_first_name', 'owner_last_name',
              'owner_phone', 'event_name', 'booth_number', 'hall']

      vendors.each do |v|
        if v.vendor_events.any?
          v.vendor_events.each do |ve|
            csv << row_for(v, ve)
          end
        else
          csv << row_for(v, nil)
        end
      end
    end

    send_data csv_data,
              filename: "vendors_export_#{Date.current.strftime('%Y%m%d')}.csv",
              type: 'text/csv',
              disposition: 'attachment'
  end

  # GET /admin/vendors/template
  def template
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['name', 'description', 'hook_line', 'website',
              'owner_email', 'owner_first_name', 'owner_last_name',
              'owner_phone', 'event_name', 'booth_number', 'hall']
      csv << ['Acme Comics', 'Vintage and new comics', 'Find your next obsession',
              'https://acmecomics.com', 'owner@acmecomics.com', 'Jane', 'Smith',
              '206-555-1234', 'Sakuracon 2026', 'A101', 'Main Hall']
    end

    send_data csv_data,
              filename: 'vendor_import_template.csv',
              type: 'text/csv',
              disposition: 'attachment'
  end

  private

  def vendor_params
    params.require(:vendor).permit(:name, :description, :hook_line, :website, :owner_email,
                                   :participant_type, :instagram_handle, :twitter_handle,
                                   :tiktok_handle, :hero_image)
  end

  # Returns [user_or_nil, error_string_or_nil]
  def find_or_create_owner(email)
    return [nil, nil] if email.blank?

    existing = User.find_by(email: email.downcase)
    return [existing, nil] if existing

    # Email not found — auto-create a vendor_admin placeholder account
    new_user = User.new(
      email:      email.downcase,
      first_name: 'Vendor',
      last_name:  'Owner',
      phone:      '0000000000',
      company:    'TBD',
      password:   SecureRandom.hex(12),
      role:       :vendor_admin
    )

    if new_user.save
      [new_user, nil]
    else
      [nil, "Could not create owner account for #{email}: #{new_user.errors.full_messages.to_sentence}"]
    end
  end

  def process_vendor_csv(csv_file, event_id = nil)
    results = { created: 0, errors: [] }

    CSV.foreach(csv_file.path, headers: true, header_converters: :symbol) do |row|
      row_num = $.
      begin
        data = row.to_h.transform_keys { |k| k.to_s.strip.downcase.gsub(/\s+/, '_').to_sym }

        if data[:name].blank?
          results[:errors] << "Row #{row_num}: name is required"
          next
        end

        # Find or create owner user
        owner = if data[:owner_email].present?
          User.find_or_create_by!(email: data[:owner_email].downcase) do |u|
            u.first_name = data[:owner_first_name].presence || 'Vendor'
            u.last_name  = data[:owner_last_name].presence  || 'Owner'
            u.phone      = data[:owner_phone].presence      || '000-000-0000'
            u.company    = data[:name].presence             || 'Vendor'
            u.password   = SecureRandom.hex(12)
            u.role       = :vendor_admin
          end
        else
          User.find_by(email: 'admin@nwtg.com') || User.where(role: 1).first
        end

        vendor = Vendor.find_or_create_by!(name: data[:name], user: owner) do |v|
          v.description = data[:description]
          v.hook_line   = data[:hook_line]
          v.website     = data[:website]
        end

        # Link to event if specified
        event = if data[:event_name].present?
          Event.find_by('lower(name) LIKE ?', "%#{data[:event_name].downcase}%")
        elsif event_id.present?
          Event.find_by(id: event_id)
        end

        if event
          VendorEvent.find_or_create_by!(vendor: vendor, event: event) do |ve|
            ve.metadata = {
              'booth_number' => data[:booth_number],
              'hall'         => data[:hall]
            }.compact
          end
        end

        results[:created] += 1

      rescue ActiveRecord::RecordInvalid => e
        results[:errors] << "Row #{row_num}: #{e.message}"
      rescue => e
        results[:errors] << "Row #{row_num}: #{e.message}"
      end
    end

    results
  end

  def row_for(vendor, vendor_event)
    [
      vendor.name,
      vendor.description,
      vendor.hook_line,
      vendor.website,
      vendor.user&.email,
      vendor.user&.first_name,
      vendor.user&.last_name,
      vendor.user&.phone,
      vendor_event&.event&.name,
      vendor_event&.booth_number,
      vendor_event&.hall
    ]
  end
end
