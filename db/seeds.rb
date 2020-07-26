require 'faker'

16.times do |i|
  user = User.create!(email: "#{i}#{Faker::Internet.free_email}",
                      password: '321Passwd$$$', confirmed_at: DateTime.now)
  rand(1..5).times do |j| # Creating rosters
    properties = ((j + 1).times.map { Faker::Lorem.word }).uniq
    # Careful with construction of rosters, cannot use create here for instance.
    roster = user.rosters.build(name: "#{user.email} roster #{j + 1}",
                                participant_properties: properties,
                                permissions: [user.permissions.build])
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

# Special roster useful for testing Instant Print
user = User.create!(email: 'instant-print.test@test.com', password: '321Passwd$$$', confirmed_at: DateTime.now)
roster = Roster.create!(name: 'Instant Print Test', participant_properties: %w[homeroom teacher], permissions: [user.permissions.build])
participants = 8.times.map { |num| roster.participants.build(first: "First #{num}", last: "Last #{num}") }
participants[0..2].each { |p| p.update(extras: { 'homeroom' => '905', 'teacher' => 'Burns' }) }
participants[3..4].each { |p| p.update(extras: { 'homeroom' => '1011', 'teacher' => 'Troy' }) }
participants[6].update(extras: { 'homeroom' => '1210', 'teacher' => 'Khan' })
participants.values_at(5, 7).each { |p| p.update(extras: { 'homeroom' => '1210', 'teacher' => 'Dubee Dubé' }) }
participants.each(&:save!)
hunt = roster.hunts.create!(name: 'IPT')
licenses = participants.map { |p| hunt.licenses.create!(participant: p) }
licenses.values_at(4, 7).each { |l| l.update!(eliminated: true) }
round1 = hunt.rounds.create!
round1.matches.create!(licenses: licenses.values_at(0, 6))
round1.matches.create!(licenses: licenses.values_at(1, 7))
round1.matches.create!(licenses: licenses.values_at(2, 3))
