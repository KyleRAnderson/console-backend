class Matchmake
  attr_reader :matches, :leftover

  def initialize(licenses, within: nil, between: nil, round_id: nil)
    @licenses = licenses
    @round_id = round_id
    if !within || within.empty?
      separate_between(between)
    else
      separate_within(within, between)
    end
  end

  def matchmake
    if @round_id.first.class == License
      @matches = matchmake_within
    elsif @licenses.first.class == Array
      @matches = matchmake_between
    elsif @licenses.first.class == Matchmake
      @matches = matchmake_children
    end
  end

  private

  # Matchmakes within the given licenses, returning the generated matches.
  # Sets the @leftovers variable to the one remaining license.
  def matchmake_within(licenses = @licenses)
    split_groups = licenses.shuffle.each_slice(@licenses.length / 2).to_a
    matches = matchmake_two(split_groups[0], split_groups[1])
    @leftover = [split_groups.fetch(2, [])]
    matches
  end

  # Machmakes between all the groupings of licenses present within the @licenses variable.
  # Returns the generated matches and sets the @leftovers variable to the one remaining license.
  def matchmake_between
    leftovers = []
    matches = @licenses.shuffle.each_slice(2).map do |groups|
      if groups.length >= 2
        current_matches = matchmake_two(groups[0], groups[1])
        leftovers += groups.first + groups.second
      else
        current_matches = matchmake_two(leftovers, groups.first)
        leftovers += groups.first
      end
      current_matches
    end
    # This method will set up the @leftovers variable, if that's needed.
    matches + matchmake_within(leftovers)
  end

  def matchmake_children
    @matches = @licenses.map(&:matchmake)
    leftover = @licenses.map(&:leftover)
    @matches += matchmake_within(leftover)
  end

  # Matchmakes between the two groups, returning the created matches.
  # Mutates the given arrays so that only the leftovers are left.
  # Thus, one or both of first_group and second_group will be empty afterward.
  def matchmake_two(first_group, second_group)
    smallest_length = [first_group.length, second_group.length].min
    sized_first = first_group.shift(smallest_length)
    sized_second = second_group.shift(smallest_length)
    sized_first.zip(sized_second).map { |licenses| Match.new(licenses: licenses, round_id: @round_id) }
  end

  def separate_licenses!(properties)
    @licenses = separate_licenses(properties)
  end

  def separate_licenses(properties)
    return if properties.empty?

    grouped = @licenses.group_by do |license|
      properties.map do |property|
        license.send(property)
      end
    end
    grouped.map do |key, licenses|
      if block_given?
        yield key, licenses
      else
        licenses
      end
    end
  end

  def separate_within(within_properties, between_properties = nil)
    return if within_properties.empty?

    separate_licenses!(within_properties) do |_, licenses|
      Matchmake.new(licenses, between: between_properties, round_id: @round_id)
    end
  end

  def separate_between(between_properties)
    separate_licenses!(between_properties)
  end
end
