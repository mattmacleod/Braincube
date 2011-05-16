class UserMailer < ActionMailer::Base
  default :from => "#{Braincube::Config::SiteTitle} <#{Braincube::Config::SiteEmail}>"
  
  def welcome_email(user)
    @user = user
    mail(:to => user.email, :subject => "Welcome to #{Braincube::Config::SiteTitle}")
  end
  
  def reset_password(user, new_password)
    @user = user
    @password = new_password
    mail(:to => user.email, :subject => "#{Braincube::Config::SiteTitle} password reset")
  end
  
end