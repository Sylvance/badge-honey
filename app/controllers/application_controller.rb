class ApplicationController < ActionController::Base
    include ApplicationHelper

    helper_method :current_user,
                    :logged_in?

    before_action :authenticate_request

    def current_user
        if session[:user_id]
            @current_user ||= User.find(session[:user_id])
        else
            @current_user = nil
        end
    end

    def logged_in?
        !current_user.nil?  
    end

    private

    def authenticate_request
        if !logged_in?
            redirect_to login_path, notice: "Log in first to get access!"
        end
    end
end
