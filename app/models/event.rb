class Event < ActiveRecord::Base
  validates_inclusion_of :kind, :in => %w(opening appointment)

  public
  RANGE_OF_SEARCH = 6.days

  def self.availabilities(from_date=DateTime.now)
    request_interval = from_date..from_date+RANGE_OF_SEARCH

    openings = Event.where(kind: 'opening', starts_at: request_interval) + recurring_openings(from_date)
    appointments = Event.where(kind: 'appointment', starts_at: request_interval)

    (request_interval).collect do |day|
      compose_availability(day, openings, appointments)
    end
  end

  private
  TIME = '%k:%M'
  OPENING_DURATION = 30.minutes

  def self.compose_availability(day, openings, appointments)
    {
        date: day,
        slots: get_available_slots(day, openings, appointments)
    }
  end

  def self.get_available_slots(day, openings, appointments)
    (make_slots_from_events(openings, day)-make_slots_from_events(appointments, day)).sort! do |x, y|
      Time.parse(x) <=> Time.parse(y)
    end
  end

  def self.recurring_openings(from_date)
    recurring_openings = Event.where('kind = ? and weekly_recurring = ?', 'opening', true)

    repeated_openings = []
    (from_date..from_date+RANGE_OF_SEARCH).each do |day|
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

  def self.make_slots_from_events(events, day)
    events.select { |event| event.starts_at.to_date == day }.collect do |opening|
      get_slots(opening.starts_at, opening.ends_at)
    end.flatten.uniq
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
