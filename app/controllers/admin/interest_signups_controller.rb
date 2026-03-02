class Admin::InterestSignupsController < Admin::BaseController
  def index
    @signups = InterestSignup.recent
                             .page(params[:page])
                             .per(50)
    @total   = InterestSignup.count
    @with_email = InterestSignup.with_email.count
    @with_phone = InterestSignup.with_phone.count
  end

  def destroy
    @signup = InterestSignup.find(params[:id])
    @signup.destroy
    redirect_to admin_interest_signups_path, notice: 'Signup removed.'
  end
end
