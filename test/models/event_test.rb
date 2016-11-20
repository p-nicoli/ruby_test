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

  # Works when using Enum for openings but makes the database field change to int type
  #test "Event should only create openings and appointments" do
  #  #Given
  #
  #  #When
  #  Event.create kind: 'opening'
  #  Event.create kind: 'appointment'
  #
  #  #Then
  #  assert_raise ArgumentError do
  #    Event.create kind: 'lunch-break'
  #  end
  #end

  test "availabilities should return an array of 7 elements" do
    #When
    availabilities = Event.availabilities

    #Then
    assert_equal 7, availabilities.length
  end

  test("availabilities should return an array of hashes where keys correspond to week following request") do
    #When
    availabilities = Event.availabilities DateTime.parse("2016-05-23")

    #Then
    assert_equal Date.parse("2016-05-23"), availabilities[0][:date]
    assert_equal Date.parse("2016-05-24"), availabilities[1][:date]
    assert_equal Date.parse("2016-05-25"), availabilities[2][:date]
    assert_equal Date.parse("2016-05-26"), availabilities[3][:date]
    assert_equal Date.parse("2016-05-27"), availabilities[4][:date]
    assert_equal Date.parse("2016-05-28"), availabilities[5][:date]
    assert_equal Date.parse("2016-05-29"), availabilities[6][:date]
  end

  test("availabilities should return slots of 30 minutes openings") do
    #Given
    create_event('opening', "2016-05-23 9:30", "2016-05-23 10:30", false)

    #When
    availabilities = Event.availabilities DateTime.parse("2016-05-20")

    #Then
    assert_equal ["9:30","10:00"], availabilities[3][:slots]
  end

  test("availabilities should return slots of 30 minutes openings over the next 7 days of request") do
    #Given
    create_event('opening', "2016-04-01 9:30", "2016-05-23 10:30", false)
    create_event('opening', "2016-05-23 9:30", "2016-05-23 10:30", false)
    create_event('opening', "2016-05-25 9:00", "2016-05-25 10:30", false)
    create_event('opening', "2016-05-28 9:30", "2016-05-28 10:30", false)

    #When
    availabilities = Event.availabilities DateTime.parse("2016-05-20")

    #Then
    assert_equal ["9:30","10:00"], availabilities[3][:slots]
    assert_equal ["9:00","9:30","10:00"], availabilities[5][:slots]
  end

  test("availabilities should return weekly recurring openings") do
    #Given
    create_event("opening", "2016-04-01 09:30", "2016-04-01 12:00", true)

    #When
    availabilities = Event.availabilities DateTime.parse("2016-05-20")

    #Then
    (1..6).each { |i| assert_equal [], availabilities[i][:slots] }
    assert_equal ["9:30","10:00","10:30","11:00","11:30"], availabilities[0][:slots]
  end

  test("availabilities should exclude appointments") do
    #Given
    create_event('opening', "2016-04-01 10:00", "2016-04-01 12:00", false)
    create_event('appointment', "2016-04-01 10:30", "2016-04-01 11:00", false)

    #When
    availabilities = Event.availabilities DateTime.parse("2016-04-01")

    #Then
    assert_equal ["10:00","11:00","11:30"], availabilities[0][:slots]
  end

  test "availabilities should not return duplicate slots" do
    #Given
    create_event('opening', "2016-02-28 12:00", "2016-02-28 13:30", true)
    create_event('opening', "2016-02-28 12:00", "2016-02-28 13:30", false)

    #When
    availabilities = Event.availabilities DateTime.parse("2016-02-28")

    #Then
    assert_equal Date.new(2016, 2, 28), availabilities[0][:date]
    assert_equal ["12:00", "12:30", "13:00"], availabilities[0][:slots]
  end

  test "availabilities should never ignore appointments even if openings are made after making appointments" do
    #Given
    create_event('opening', "2016-02-28 10:00", "2016-02-28 14:00", true)
    create_event('appointment', "2016-02-28 12:00", "2016-02-28 13:30", false)
    create_event('opening', "2016-02-28 12:00", "2016-02-28 13:30", false)

    #When
    availabilities = Event.availabilities DateTime.parse("2016-02-28")

    #Then
    assert_equal Date.new(2016, 2, 28), availabilities[0][:date]
    assert_equal ["10:00", "10:30", "11:00", "11:30", "13:30"], availabilities[0][:slots]
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
