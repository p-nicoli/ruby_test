class Event < ActiveRecord::Base

  validates_inclusion_of :kind, :in => ['opening', 'appointment']

  TIME = "%k:%M"
  DATE = "%Y/%m/%d"
  OPENING_DURATION = 30.minutes
  MAX_LENGTH = 7

  def self.availabilities(from_date=DateTime.parse("1970-01-01"))
    request_interval = from_date..from_date+6.days

    openings = Event.where(kind: "opening", starts_at: request_interval)

    (request_interval).collect do |day|
      availability = Hash.new
      availability[:date] = day
      availability[:slots] = make_opening_slots(day, openings)
      availability
    end
  end

  def self.make_opening_slots(day, openings)
    openings.select { |opening| opening.starts_at.to_date == day }.collect do |opening|
      get_slots(opening.starts_at, opening.ends_at)
    end.flatten
  end


  def self.availabilities_legacy( from_date=DateTime.parse("1970-01-01") )
    availabilities = []
    future_openings = future_openings(from_date)
    recurring_openings = recurring_openings(from_date)

    openings = future_openings+recurring_openings

    openings.each do |opening|
      availabilities << get_opening(opening)
    end
    availabilities
  end

  def self.recurring_openings(from_date)
    recurring_openings = Event.where("kind = ? and weekly_recurring = ?", 'opening', true)

    repeated_openings = []
    (from_date..from_date+6.days).each do |day|
      same_day_openings = recurring_openings.select { |opening| opening.starts_at.wday == day.wday}
      same_day_openings.each do |opening|
        new_starts_at = opening.starts_at + (day - opening.starts_at.to_date)
        new_ends_at = opening.ends_at + (day - opening.ends_at.to_date)
        new_event = Event.new kind: opening.kind, starts_at: new_starts_at, ends_at: new_ends_at
        repeated_openings << new_event
      end
    end
    repeated_openings
  end

  def self.future_openings(from_date)
    openings = Event.where("kind = ? and starts_at > ? and starts_at < ? and weekly_recurring = ?", 'opening', from_date, from_date+7.days, false)
  end

  def self.get_opening(opening)
    availability = Hash.new
    availability[:date] = opening.starts_at.to_date
    availability[:slots] = get_slots(opening.starts_at, opening.ends_at)
    availability
  end

  def self.get_slots(start_datetime, end_datetime)
    slots = []
    start_time = start_datetime
    while start_time < end_datetime do
      slots << start_time.strftime(TIME).strip
      start_time += OPENING_DURATION
    end
    slots
  end

end
