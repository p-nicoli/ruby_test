class Event < ActiveRecord::Base

  validates_inclusion_of :kind, :in => ['opening', 'appointment']

  TIME = "%k:%M"
  DATE = "%Y/%m/%d"
  OPENING_DURATION = 30.minutes
  MAX_LENGTH = 7

  def self.availabilities(from_date=DateTime.parse("1970-01-01"))
    request_interval = from_date..from_date+6.days

    openings = Event.where(kind: "opening", starts_at: request_interval) + recurring_openings(from_date)
    appointments = Event.where(kind: "appointment", starts_at: request_interval)

    (request_interval).collect do |day|
      availability = Hash.new
      availability[:date] = day
      availability[:slots] = (make_slots(day, openings)-make_slots(day, appointments)).uniq
      availability
    end

  end

  def self.make_slots(day, openings)
    openings.select { |opening| opening.starts_at.to_date == day }.collect do |opening|
      get_slots(opening.starts_at, opening.ends_at)
    end.flatten
  end

  def self.recurring_openings(from_date)
    recurring_openings = Event.where("kind = ? and weekly_recurring = ?", 'opening', true)

    repeated_openings = []
    (from_date..from_date+6.days).each do |day|
      same_day_openings = recurring_openings.select { |opening| opening.starts_at.wday == day.wday}
      same_day_openings.each do |opening|
        new_starts_at = opening.starts_at + (day - opening.starts_at.to_date).days
        new_ends_at = opening.ends_at + (day - opening.ends_at.to_date).days
        new_event = Event.new kind: opening.kind, starts_at: new_starts_at, ends_at: new_ends_at
        repeated_openings << new_event
      end
    end
    repeated_openings
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
