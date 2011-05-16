require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase

  # Metatests
  ############################################################################
  should_be_valid_with_factory
  
  
  # Class tests
  ############################################################################
  
  # Validations
  should validate_presence_of :email
  should validate_presence_of :auth_method
  should validate_presence_of :password_hash
  should validate_presence_of :role

  should validate_acceptance_of :terms
  should ensure_length_of(:password).is_at_least(5).is_at_most(40)
  
  # Don't allow broken emails
  should_validate_email :email
  
  # Protected attributes
  should_not allow_mass_assignment_of :auth_method
  should_not allow_mass_assignment_of :password_salt
  should_not allow_mass_assignment_of :password_hash
  should_not allow_mass_assignment_of :verification_key
  should_not allow_mass_assignment_of :role
  should_not allow_mass_assignment_of :accessed_at
  should_not allow_mass_assignment_of :created_at
  should_not allow_mass_assignment_of :updated_at
  
  # Associations
  should have_many :written_articles
  should have_many :comments
  should have_many :articles
  should have_many :pages
  should have_many :assets
  should have_many :versions
  should have_many :events
  should have_many :performances
  should have_many :venues
  should have_many :locks
  should have_many :authors
  should have_and_belong_to_many :sections

  
  context "An new user" do
    
    setup { @user = Factory(:user) }
    subject { @user }
    
    should validate_uniqueness_of :email
    
    should "have a correct parameter value" do
      assert_equal "1-test_user", @user.to_param
    end
    
    should "send a welcome email on creation" do
      assert !ActionMailer::Base.deliveries.empty?
      @sent = ActionMailer::Base.deliveries.last
      assert_equal [@user.email], @sent.to
      assert_equal "Welcome to #{Braincube::Config::SiteTitle}", @sent.subject
    end
    
    should "have a verification key" do
      assert @user.verification_key
    end
    
    should "have a password hash and salt" do
      assert @user.password_hash && @user.password_salt
    end
    
    should "be allowed to login" do
      assert_equal @user, User.authenticate(@user.email, "password")
    end

    # Try to change the password - check it can be done and that the results
    # are what is expected
    context "when the password is changed" do
      setup { @user.password = "newpass" }
      
      should "set the password_changed flag" do
        assert @user.send(:password_changed?)
      end
      
      should "update the password hash" do
        assert_equal @user.password_hash, 
                     User.salted_hash("newpass", @user.password_salt)
      end
      
      should "not save if confirmation does not match" do
        @user.password_confirmation = "This does not match"
        assert !@user.save
      end
      
      should "not be able to authenticate with new password" do
        @user.save
        assert !User.authenticate(@user.email, "newpass")
      end
      
      context "and confirmation matches password" do
        setup { @user.password_confirmation = "newpass" }
        
        should "be able to save record" do
          assert @user.save
        end
        
        should "be able to authenticate with new password" do
          @user.save
          @ruser = User.authenticate(@user.email, "newpass")
          assert_equal @user, @ruser
        end
        
      end
      
    end
    
    context "when password is reset" do
      setup do
        @sent = @user.reset_password!
        assert_not_nil @sent
      end
      
      should "send a reset email with the new password to user" do
        assert !ActionMailer::Base.deliveries.empty?
        assert_equal [@user.email], @sent.to
        assert_equal "#{Braincube::Config::SiteTitle} password reset", @sent.subject
        new_pass = $1 if Regexp.new("has been changed to (\\w+)") =~ @sent.encoded
        assert new_pass.to_s.length==6
        assert_equal @user, User.authenticate(@user.email, new_pass)
      end
      
    end
    
  end



  context "A user with the legacy password authentication mechanism" do
    setup do
      @user = Factory(:user)
      @user.update_attribute(:password_hash, "5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8")
      @user.update_attribute(:auth_method, User::AuthMethods[:hash])
    end
    subject { @user }
    
    should "be allowed to login" do
      assert_equal @user, User.authenticate(@user.email, "password")
    end
    
    context "when password is updated" do
      setup { @user.password = "newpass" }
      
      should "use the new authentication mechanism" do
        assert_equal @user.auth_method, User::AuthMethods[:salted_hash]
      end
      
      should "update the password hash" do
         assert_equal @user.password_hash, 
                      User.salted_hash("newpass", @user.password_salt)
       end
      
    end
    
  end
  
  context "a writer" do
    setup { @user = Factory(:user, :role=>"WRITER") }
    should "appear in the list of writers" do
      assert_equal [@user], User.writers
    end
  end

  context "an editor" do
    setup { @user = Factory(:user, :role=>"EDITOR") }
    should "appear in the list of editors" do
      assert_equal [@user], User.editors
    end
  end
  
  context "a subeditor" do
    setup { @user = Factory(:user, :role=>"SUBEDITOR") }
    should "appear in the list of subeditors" do
      assert_equal [@user], User.subeditors
    end
  end
  
  context "a publisher" do
    setup { @user = Factory(:user, :role=>"PUBLISHER") }
    should "appear in the list of publishers" do
      assert_equal [@user], User.publishers
    end
  end
  
  context "an administrator" do
    setup { @user = Factory(:user, :role=>"ADMIN") }
    should "appear in the list of administrators" do
      assert_equal [@user], User.administrators
    end
  end  

end