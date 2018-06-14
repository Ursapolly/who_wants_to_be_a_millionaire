FactoryGirl.define do
  factory :user do
    name { "Умник_#{rand(999)}" }
    sequence(:email) { |n| "email_#{n}@example.com" }
    is_admin false
    balance 0

    after(:build) { |u| u.password_confirmation = u.password = "123456" }
  end
end