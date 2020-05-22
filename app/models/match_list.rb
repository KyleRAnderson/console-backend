class MatchList < Array
  def save_all
    Match.transaction { each(&:save!) }
    true
  rescue Activerecord::ActiveRecordError
    false
  end
end
