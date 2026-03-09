class Admin::InterestSignupsController < Admin::BaseController
  def index
    @signups = InterestSignup.recent.page(params[:page]).per(50)
    @total      = InterestSignup.count
    @with_email = InterestSignup.with_email.count
    @with_phone = InterestSignup.with_phone.count

    respond_to do |format|
      format.html
      format.csv do
        all_signups = InterestSignup.recent
        send_data generate_csv(all_signups),
                  filename: "interest-signups-#{Date.today}.csv",
                  type: 'text/csv'
      end
    end
  end

  def destroy
    @signup = InterestSignup.find(params[:id])
    @signup.destroy
    redirect_to admin_interest_signups_path, notice: 'Signup removed.'
  end

  private

  def generate_csv(signups)
    require 'csv'
    CSV.generate(headers: true) do |csv|
      csv << ['Name', 'Email', 'Phone', 'Source', 'Notes', 'Signed Up']
      signups.each do |s|
        csv << [s.name, s.email, s.phone, s.source, s.notes,
                s.created_at.strftime('%Y-%m-%d')]
      end
    end
  end
end
