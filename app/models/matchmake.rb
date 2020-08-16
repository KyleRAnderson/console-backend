class Matchmake
  attr_reader :matches, :leftover

  COMMON_PROPERTIES_ERROR_MESSAGE = 'Cannot have within and between containing same properties for matchmaking.'

  def initialize(licenses, within: [], between: [], round_id: nil)
    raise 'Cannot matchmake with no licenses.' if licenses.blank?

    @licenses = licenses
    @round_id = round_id

    within&.uniq!
    between&.uniq!

    if within && between && !within.intersection(between).empty?
      raise COMMON_PROPERTIES_ERROR_MESSAGE
    end

    if within.present?
      separate_within(within, between)
    elsif between.present?
      separate_between(between)
    end
  end

  def matchmake
    if @licenses.first.class == License
      @matches, @leftover = matchmake_within
    elsif @licenses.first.class == Array
      @matches, @leftover = matchmake_between
    elsif @licenses.first.class == Matchmake
      @matches, @leftover = matchmake_children
    end
    @matches = MatchList.new(@matches)
  end

  private

  # Matchmakes within the given licenses, returning the generated matches.
  # Sets the @leftovers variable to the one remaining license.
  def matchmake_within(licenses = @licenses)
    # Can't use safe navigation operator because of >=
    if licenses && licenses.size >= 2
      split_groups = licenses.shuffle.each_slice(licenses.size / 2).to_a
      matches = matchmake_two(split_groups[0], split_groups[1])
      leftover = split_groups[2] || []
    else
      matches = []
      leftover = licenses
    end
    [matches, leftover]
  end

  # Machmakes between all the groupings of licenses present within the @licenses variable.
  # Returns the generated matches and sets the @leftovers variable to the one remaining license.
  def matchmake_between(licenses = @licenses)
    leftovers = []
    matches = licenses.shuffle.each_slice(2).map do |groups|
      if groups.size >= 2
        current_matches = matchmake_two(groups[0], groups[1])
        leftovers += groups.first + groups.second
      else
        current_matches = matchmake_two(leftovers, groups.first)
        leftovers += groups.first
      end
      current_matches
    end
    more_matches, final_leftover = matchmake_within(leftovers)
    matches = matches.reduce(more_matches) { |total, match_group| total + match_group }
    [matches, final_leftover]
  end

  def matchmake_children
    matches = @licenses.reduce([]) { |total, matchmake| total + matchmake.matchmake }
    leftover = @licenses.reduce([]) { |total, matchmake| total + matchmake.leftover }
    extra_matches, leftover = matchmake_within(leftover)
    [matches + extra_matches, leftover]
  end

  # Matchmakes between the two groups, returning the created matches.
  # Mutates the given arrays so that only the leftovers are left.
  # Thus, one or both of first_group and second_group will be empty afterward.
  def matchmake_two(first_group, second_group)
    smallest_length = [first_group.size, second_group.size].min
    sized_first = first_group.shift(smallest_length)
    sized_second = second_group.shift(smallest_length)
    sized_first.zip(sized_second).map { |licenses| Match.new(licenses: licenses, round_id: @round_id) }
  end

  def separate_licenses!(properties, &block)
    @licenses = separate_licenses(properties, &block)
  end

  def separate_licenses(properties)
    return @licenses if properties.empty?

    grouped = @licenses.group_by do |license|
      properties.map do |property| # Since we're mapping by properties, order will always be the same.
        license.participant.extras[property]
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
