class Time
  def round_down
    Time.gm(self.year, self.month, self.day)
  end

  alias round round_down
  alias start_of round_down

  def round_up
    Time.gm(self.year, self.month, self.day) + 1.day - 1.second
  end

  alias end_of round_up

  def self.today
    self.new.round_down
  end
end

