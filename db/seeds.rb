require 'faker'

16.times do |i|
    User.create(
        username: Faker::Name.name,
        email: Faker::Internet.free_email
    )
end