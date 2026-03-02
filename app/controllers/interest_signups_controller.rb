class InterestSignupsController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    @interest_signup = InterestSignup.new
    @source = params[:source]
  end

  def create
    @interest_signup = InterestSignup.new(interest_signup_params)

    if @interest_signup.save
      redirect_to interest_signup_thanks_path, notice: 'You are on the list!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def thank_you
    # static thank-you page
  end

  private

  def interest_signup_params
    params.require(:interest_signup).permit(:name, :email, :phone, :source, :notes)
  end
end
