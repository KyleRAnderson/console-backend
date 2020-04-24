require 'faker'

16.times do |i|
    user = User.new
    user.email = Faker::Internet.free_email
    user.password = '321Passwd$$$'
    user.password_confirmation = '321Passwd$$$'
    user.confirmed_at = DateTime.now
    user.save!
    rand(1..5).times do |i|
        Roster.create(name: "#{user.email} roster #{i + 1}", user: user, participant_properties: i.times.collect { |i| Faker::Lorem.word })
    end
end