class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def edit
    # Just render the form
  end

  def update
    if @user.update(user_params)
      redirect_to root_path, notice: 'Profile updated successfully!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :phone, :company, :text_capable)
  end
end
