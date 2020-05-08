require 'faker'

16.times do
  user = User.new
  user.email = Faker::Internet.free_email
  user.password = '321Passwd$$$'
  user.password_confirmation = '321Passwd$$$'
  user.confirmed_at = DateTime.now
  user.save!
  rand(1..5).times do |j|
    properties = j.times.collect { Faker::Lorem.word }
    roster = Roster.create(name: "#{user.email} roster #{j + 1}", user: user,
                           participant_properties: properties)
    rand(10..75).times do
      attributes = roster.participant_properties.to_h do |property|
        [property, Faker::Lorem.word]
      end
      roster.participants.build(first: Faker::Name.first_name,
                                last: Faker::Name.last_name,
                                extras: attributes).save!
    end
  end
end
