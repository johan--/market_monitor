class SessionsController < ApplicationController
	def new
		if signed_in?
			flash[:error] = "You are already signed in."
			redirect_to user_path(current_user)
		end
	end

	def create
		user = User.find_by_email(params[:session][:email].downcase)
		if user && user.authenticate(params[:session][:password])
			sign_in user
			redirect_to user
		else
			flash[:error] = "Invalid Credentials"
			render 'new'
		end
	end

	def destroy
		sign_out
		redirect_to root_url
	end
end
