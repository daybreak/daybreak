class Date
  def first_day
    self.strftime('%m/1/%Y').to_date
  end

  def days_in_month
    d,m,y = mday,month,year
    d += 1 while Date.valid_civil?(y,m,d)
    d - 1
  end

  def last_day
    self.first_day + self.days_in_month - 1
  end

  def ordinal_day(ordinal, day) # ordinal_day(1, 'Monday')
    month_start = self.first_day
    month_end = self.last_day
    last_ordinal_day = nil
    dt = month_start
    count = 0
    begin
      if dt.strftime('%A') == day
        count += 1
        last_ordinal_day = dt if month_start.strftime
      end
      dt += 1
    end while dt <= month_end and count < ordinal
    last_ordinal_day
  end
end

