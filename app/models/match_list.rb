class MatchList < Array
  def save_all
    Match.transaction { each(&:save!) }
    true
  rescue ActiveRecord::ActiveRecordError
    false
  end
end
