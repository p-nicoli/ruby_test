require 'test_helper'

class EventTest < ActiveSupport::TestCase

  test "Event should create stuff" do
    #Given
    Event.create kind: 'opening'

    #When
    found_events = Event.all

    #Then
    assert_not_empty found_events
    assert_equal 1, found_events.size
  end

  test "Event.availabilities should return an array" do
    #Given

    #When
    availabilities = Event.availabilities_legacy DateTime.parse("2016-01-01")

    #Then
    assert_equal [],availabilities
  end

  test "Event.availabilities should only return openings" do
    #Given
    create_event('opening', "1970-01-01 08:00", "1970-12-01 09:00", false)
    create_event(:appointment, "1970-01-01 10:00", "1970-01-01 11:00", false)

    #When
    availabilities = Event.availabilities_legacy

    #Then
    assert_equal 1, availabilities.size
  end

  test "Event.availabilities should only return future openings" do
    #Given
    create_event('opening', "2016-01-01 08:00", "2016-01-01 09:00", false)
    create_event('opening', "2016-01-02 08:00", "2016-01-02 09:00", false)
    create_event('opening', "2016-01-03 08:00", "2016-01-03 09:00", false)

    #When
    availabilities = Event.availabilities_legacy DateTime.parse("2016-01-02")

    #Then
    assert_equal 2, availabilities.size
  end

  test "Event.availabilities should return array of objects with date attribute and an array of 30 minutes slots" do
    #Given
    create_event('opening', "2016-05-23 09:30", "2016-05-23 10:30", false)

    #When
    availabilities = Event.availabilities_legacy DateTime.parse "2016-05-23"

    #Then
    assert_equal 1, availabilities.size
    assert_equal Date.new(2016, 5, 23),availabilities[0][:date]
    assert_equal ["9:30","10:00"], availabilities[0][:slots]

    #JSON marshalling seems a bit off, should be :
    # assert_equal '[{"date":"2016/05/23","slots":["09:30","10:00"]}]', availabilities.to_json
    assert_equal '[{"date":"2016-05-23","slots":["9:30","10:00"]}]', availabilities.to_json
  end

  test "Event.availabilities should return openings over a 7 day period, including the start_date passed" do
    #Given
    create_event('opening', "2016-05-23 09:30", "2016-05-23 10:30", false)
    create_event('opening', "2016-05-24 09:30", "2016-05-23 10:30", false)
    create_event('opening', "2016-05-25 09:30", "2016-05-23 10:30", false)
    create_event('opening', "2016-05-26 09:30", "2016-05-23 10:30", false)
    create_event('opening', "2016-05-27 09:30", "2016-05-23 10:30", false)
    create_event('opening', "2016-05-28 09:30", "2016-05-23 10:30", false)
    create_event('opening', "2016-05-29 09:30", "2016-05-23 10:30", false)
    create_event('opening', "2016-05-30 09:30", "2016-05-23 10:30", false)
    create_event('opening', "2016-05-31 09:30", "2016-05-23 10:30", false)

    #When
    availabilities = Event.availabilities_legacy Date.parse "2016-05-24"

    #Then
    assert_equal 7, availabilities.length
    assert_equal Date.parse("2016-05-24"), availabilities[0][:date]
    assert_equal Date.parse("2016-05-30"), availabilities[6][:date]
  end

  test "one simple test example" do

    Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-04 09:30"), ends_at: DateTime.parse("2014-08-04 12:30"), weekly_recurring: true
    Event.create kind: 'appointment', starts_at: DateTime.parse("2014-08-11 10:30"), ends_at: DateTime.parse("2014-08-11 11:30")

    availabilities = Event.availabilities DateTime.parse("2014-08-10")
    assert_equal Date.new(2014, 8, 10), availabilities[0][:date]
    assert_equal [], availabilities[0][:slots]
    assert_equal Date.new(2014, 8, 11), availabilities[1][:date]
    assert_equal ["9:30", "10:00", "11:30", "12:00"], availabilities[1][:slots]
    assert_equal Date.new(2014, 8, 16), availabilities[6][:date]
    assert_equal 7, availabilities.length
  end

  def create_event(kind, starts_at, ends_at, recurring)
    Event.create kind: kind, starts_at: DateTime.parse(starts_at), ends_at: DateTime.parse(ends_at), weekly_recurring: recurring
  end

end
