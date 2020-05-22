require 'faker'

16.times do
  user = User.new
  user.email = Faker::Internet.free_email
  user.password = '321Passwd$$$'
  user.password_confirmation = '321Passwd$$$'
  user.confirmed_at = DateTime.now
  user.save!
  rand(1..5).times do |j| # Creating rosters
    properties = ((j + 1).times.map { Faker::Lorem.word }).uniq
    roster = user.rosters.build(name: "#{user.email} roster #{j + 1}",
                                participant_properties: properties)
    roster.save!
    participant_properties_values = roster.participant_properties.to_h do |property|
      attribute_values = rand(3..5).times.map do
        Faker::Lorem.word
      end
      [property, attribute_values]
    end
    rand(10..75).times do # Creating participants.
      attributes = roster.participant_properties.to_h do |property|
        [property, participant_properties_values[property].sample]
      end
      roster.participants.build(first: Faker::Name.first_name,
                                last: Faker::Name.last_name,
                                extras: attributes).save!
    end

    rand(0..4).times do # Creating Hunts
      hunt = roster.hunts.build(name: Faker::Ancient.titan)
      hunt.save!

      roster.participants.each do |participant|
        hunt.licenses.build(participant: participant).save!
      end
    end
  end
end
