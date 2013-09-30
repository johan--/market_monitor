class ApisController < ApplicationController
	#before_filter :signed_in_user

  def new
  	if signed_in?
  		@api = current_user.apis.build
  	else
  		flash[:error] = "You must be signed in to create an API."
  		redirect_to signin_path
  	end
  end

  def corporation
    if signed_in?
      @api = current_user.apis.build
    else
      flash[:error] = "You must be signed in to create an API."
      redirect_to signin_path
    end
  end

  def create
  	@api = current_user.apis.build(params[:api])
  	if @api.save
  		flash[:success] = "Api #{@api.key_id} Created"
  		redirect_to apilist_path
  	else
  		render 'new'
  	end
  end

  def show
    if signed_in?
      #@apis = current_user.apis.paginate(page: params[:page]) #doesn't appear to be necessary.
      render 'api_list'
    else
      flash[:error] = "You must be signed in to view this page."
      redirect_to signin_path
    end
  end
end
