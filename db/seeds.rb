require 'faker'

16.times do |i|
    user = User.create(
        username: Faker::Name.name,
        email: Faker::Internet.free_email
    )
    rand(1..5).times do |i|
        Roster.create(name: "#{user.username} roster #{i + 1}", user: user, participant_properties: i.times.collect { |i| Faker::Lorem.word })
    end
end