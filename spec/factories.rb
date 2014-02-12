FactoryGirl.define do
  
  sequence :vegetable_id do |n| n end
  sequence :soup_id do |n| n end
    
  sequence :vegetable_peice_size  do
    ['tiny', 'small', 'medium', 'large', 'whole'].sample
  end

  sequence :vegetable_name do
    ['carrot', 'cabbage', 'celery', 'onion', 'corn'].sample
  end

  factory :vegetable do
    id  { generate(:vegetable_id) }
    name { generate(:vegetable_name) }
    peice_size { generate(:vegetable_peice_size) }
    expires_at Time.parse('2014-06-02 08:40:33')
  end

  factory :soup do
    id  { generate(:soup_id) }
    name 'vegetable soup'
    temperature 100
    status 'boiling on stove'
  end
end
# 
# sequence :email_address do |n|
#   "testy#{n}@example.com"
# end
# 
# sequence :user_id do
#   (10000...10005).to_a.sample
# end
# 
# sequence :agent_fee_sales_session_status do
#   ['active', 'dead'].sample
# end
# 
# factory :agent_fee_sales_session do
#   agent
#   status { generate(:agent_fee_sales_session_status) }
#   assigned_to { generate(:user_id) }
#   assigned_at Time.parse('2013-12-02 08:40:33')
#   expires_at Time.parse('2014-06-02 08:40:33')
#   follow_up Time.parse('2013-12-17 06:00:00')
#   hot '1'
#   priority 'high'
#   created_at Time.parse('2013-11-18 14:36:05')
#   updated_at Time.parse('2013-12-17 11:31:08')
#   factory :null_follow_up_agent_fee_sales_session do
#     follow_up nil
#   end
# end
# 
# factory :agent do
#   after(:build) { |agent| agent.class.skip_callback(:save, :after, :notate_changes) }
#   user
#   company
#   status 'active'
#   name_on_license 'Testy'
#   license_type 'Salesperson'
#   license_number '111111'
#   license_state 'CA'
#   broker_name 'Ali'
#   years_in_real_estate '12 years'
# end
# 
# factory :company do
#   name 'Flywheel'
#   address '233 Post st.'
#   city 'San Francisco'
#   state 'CA'
#   zip '94104' 
# end
# 
# factory :user do
#   after(:build) { |user| user.class.skip_callback(:save, :after, :notate_changes) }
#   email { generate(:email_address) }
#   login { |u| u.email }
#   password '1234567'
#   first_name 'Testy'
#   last_name 'Testerson'
#   phone_office '415-555-5555'
#   factory :agent_user do
#     user_type 'agent'
#   end
# end
