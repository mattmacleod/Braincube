Factory.define :user do |f|
  f.sequence(:email) { |n| "test_email_#{n}@example.com" }
  f.name "Test user"
  f.password "password"
  f.password_confirmation "password"
  f.verification_key "0000"
  f.verified true # For test purposes
end

Factory.define :admin_user, :parent=>:user do |f|
  f.role "ADMIN"
end