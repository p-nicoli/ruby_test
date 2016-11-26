require 'test_helper'

class EventTest < ActiveSupport::TestCase

  test 'Event should create stuff' do
    #Given
    create_event('opening', '2016-05-10 09:00', '2016-05-10 12:00', false)

    #When
    found_events = Event.all

    #Then
    assert_not_empty found_events
    assert_equal 1, found_events.size
  end

  test 'Event should only create openings and appointments' do
    #Given
    create_event('opening', '2016-05-10 09:00', '2016-05-10 12:00', false)
    create_event('appointment', '2016-05-10 09:00', '2016-05-10 12:00', false)
    create_event('lunch break', '2016-05-10 09:00', '2016-05-10 12:00', false)

    #When
    found_events = Event.all

    #Then
    assert_not_empty found_events
    assert_equal 2, found_events.size
  end

  test 'Event should only create appointments that are not recurring weekly' do
    #Given
    create_event('opening', '2016-05-10 09:00', '2016-05-10 12:00', false)
    create_event('opening', '2016-05-15 09:00', '2016-05-10 12:00', true)
    create_event('appointment', '2016-05-10 09:00', '2016-05-10 12:00', false)
    create_event('appointment', '2016-05-17 09:00', '2016-05-10 12:00', true)

    #When
    found_events = Event.all

    #Then
    assert_not_empty found_events
    assert_equal 3, found_events.size
  end

  test 'availabilities should return an array of 7 elements' do
    #When
    availabilities = Event.availabilities

    #Then
    assert_equal 7, availabilities.length
  end

  test 'availabilities should return an array of hashes where keys correspond to week following request' do
    #When
    availabilities = Event.availabilities DateTime.parse('2016-05-23')

    #Then
    assert_equal Date.parse('2016-05-23'), availabilities[0][:date]
    assert_equal Date.parse('2016-05-24'), availabilities[1][:date]
    assert_equal Date.parse('2016-05-25'), availabilities[2][:date]
    assert_equal Date.parse('2016-05-26'), availabilities[3][:date]
    assert_equal Date.parse('2016-05-27'), availabilities[4][:date]
    assert_equal Date.parse('2016-05-28'), availabilities[5][:date]
    assert_equal Date.parse('2016-05-29'), availabilities[6][:date]
  end

  test 'availabilities should return slots of 30 minutes openings' do
    #Given
    create_event('opening', '2016-05-23 9:30', '2016-05-23 10:30', false)

    #When
    availabilities = Event.availabilities DateTime.parse('2016-05-20')

    #Then
    assert_equal %w(9:30 10:00), availabilities[3][:slots]
  end

  test 'availabilities should return slots of 30 minutes openings over the next 7 days of request' do
    #Given
    create_event('opening', '2016-04-01 9:30', '2016-05-23 10:30', false)
    create_event('opening', '2016-05-23 9:30', '2016-05-23 10:30', false)
    create_event('opening', '2016-05-25 9:00', '2016-05-25 10:30', false)
    create_event('opening', '2016-05-28 9:30', '2016-05-28 10:30', false)

    #When
    availabilities = Event.availabilities DateTime.parse('2016-05-20')

    #Then
    assert_equal %w(9:30 10:00), availabilities[3][:slots]
    assert_equal %w(9:00 9:30 10:00), availabilities[5][:slots]
  end

  test 'availabilities should return weekly recurring openings' do
    #Given
    create_event('opening', '2016-04-01 09:30', '2016-04-01 12:00', true)

    #When
    availabilities = Event.availabilities DateTime.parse('2016-05-20')

    #Then
    (1..6).each { |i| assert_equal [], availabilities[i][:slots] }
    assert_equal %w(9:30 10:00 10:30 11:00 11:30), availabilities[0][:slots]
  end

  test 'availabilities should exclude appointments' do
    #Given
    create_event('opening', '2016-04-01 10:00', '2016-04-01 12:00', false)
    create_event('appointment', '2016-04-01 10:30', '2016-04-01 11:00', false)

    #When
    availabilities = Event.availabilities DateTime.parse('2016-04-01')

    #Then
    assert_equal %w(10:00 11:00 11:30), availabilities[0][:slots]
  end

  test 'availabilities should not return duplicate slots' do
    #Given
    create_event('opening', '2016-02-28 12:00', '2016-02-28 13:30', true)
    create_event('opening', '2016-02-28 12:00', '2016-02-28 13:30', false)

    #When
    availabilities = Event.availabilities DateTime.parse('2016-02-28')

    #Then
    assert_equal Date.new(2016, 2, 28), availabilities[0][:date]
    assert_equal %w(12:00 12:30 13:00), availabilities[0][:slots]
  end

  test 'availabilities should never ignore appointments even if openings are made after making appointments' do
    #Given
    create_event('opening', '2016-02-28 10:00', '2016-02-28 14:00', true)
    create_event('appointment', '2016-02-28 12:00', '2016-02-28 13:30', false)
    create_event('opening', '2016-02-28 12:00', '2016-02-28 13:30', false)

    #When
    availabilities = Event.availabilities DateTime.parse('2016-02-28')

    #Then
    assert_equal Date.new(2016, 2, 28), availabilities[0][:date]
    assert_equal %w(10:00 10:30 11:00 11:30 13:30), availabilities[0][:slots]
  end

  test 'availabilities should correctly return an empty array of slots if all openings are taken by appointments' do
    #Given
    create_event('opening', '2016-02-28 10:00', '2016-02-28 14:00', true)
    create_event('appointment', '2016-02-28 10:00', '2016-02-28 14:30', false)

    #When
    availabilities = Event.availabilities DateTime.parse('2016-02-28')

    #Then
    assert_equal Date.new(2016, 2, 28), availabilities[0][:date]
    assert_equal [], availabilities[0][:slots]
  end

  test 'availabilities should correctly merge openings' do
    #Given
    create_event('opening', '2016-05-10 10:00', '2016-05-10 12:00', false)
    create_event('opening', '2016-05-10 11:30', '2016-05-10 13:00', false)

    #When
    availabilities = Event.availabilities DateTime.parse('2016-05-10')

    #Then
    assert_equal Date.new(2016, 5, 10), availabilities[0][:date]
    assert_equal %w(10:00 10:30 11:00 11:30 12:00 12:30), availabilities[0][:slots]
  end

  test 'availabilities should correctly merge recurring openings and keep them ordered' do
    #Given
    create_event('opening', '2016-05-10 09:00', '2016-05-10 12:00', true)
    create_event('opening', '2016-05-10 11:30', '2016-05-10 12:30', true)
    create_event('opening', '2016-05-24 11:30', '2016-05-24 13:00', false)

    #When
    availabilities = Event.availabilities DateTime.parse('2016-05-24')

    #Then
    assert_equal Date.new(2016, 5, 24), availabilities[0][:date]
    assert_equal %w(9:00 9:30 10:00 10:30 11:00 11:30 12:00 12:30), availabilities[0][:slots]
  end

  test 'Events should only be created at 00 minutes or 30 minutes' do
    #Given
    create_event('opening', '2016-05-23 9:31', '2016-05-23 10:30', false)

    #When
    found_events = Event.all

    #Then
    assert_empty found_events
  end

  test 'Recurring openings should not work in the past' do
    #Given
    create_event('opening', '2016-05-23 9:30', '2016-05-23 12:00', true)

    #When
    availabilities = Event.availabilities DateTime.parse('2016-05-07')

    #Then
    assert_equal DateTime.parse('2016-05-09'), availabilities[2][:date]
    assert_equal DateTime.parse('2016-05-23').wday, availabilities[2][:date].wday
    availabilities.each do |availability|
      assert_equal [], availability[:slots]
    end
  end

  test 'Edge case: an appointment ending just when an opening slot begins' do
    #Given
    create_event('appointment', '2016-05-23 8:00', '2016-05-23 9:00', false)
    create_event('appointment', '2016-05-23 9:00', '2016-05-23 10:30', false)
    create_event('opening', '2016-05-23 10:30', '2016-05-23 15:00', false)

    #When
    availabilities = Event.availabilities DateTime.parse('2016-05-20')

    #Then
    assert_equal DateTime.parse('2016-05-23'), availabilities[3][:date]
    assert_equal %w(10:30 11:00 11:30 12:00 12:30 13:00 13:30 14:00 14:30), availabilities[3][:slots]
  end

  test 'Edge case: an appointment beginning just when an opening slot ends' do
    #Given
    create_event('opening', '2016-05-23 8:00', '2016-05-23 11:00', false)
    create_event('appointment', '2016-05-23 11:00', '2016-05-23 11:30', false)

    #When
    availabilities = Event.availabilities DateTime.parse('2016-05-20')

    #Then
    assert_equal DateTime.parse('2016-05-23'), availabilities[3][:date]
    assert_equal %w(8:00 8:30 9:00 9:30 10:00 10:30), availabilities[3][:slots]
  end

  test 'Edge case: you should not be able to book the same appointment twice' do
    #Given
    create_event('appointment', '2016-05-23 9:30', '2016-05-23 10:30', false)
    create_event('appointment', '2016-05-23 9:30', '2016-05-23 10:30', false)

    #When
    events = Event.all

    #Then
    assert_equal 1, events.size
  end

  test 'Edge case: you should not be able to book an appointment ending inside another appointment' do
    #Given
    create_event('appointment', '2016-05-23 9:30', '2016-05-23 10:00', false)
    create_event('appointment', '2016-05-23 10:00', '2016-05-23 11:30', false)
    create_event('appointment', '2016-05-23 9:00', '2016-05-23 10:30', false)
    create_event('appointment', '2016-05-23 9:00', '2016-05-23 10:00', false)
    create_event('appointment', '2016-05-23 8:00', '2016-05-23 11:30', false)

    #When
    events = Event.all

    #Then
    assert_equal 2, events.size
  end

  test 'Edge case: you should not be able to book an appointment starting inside another appointment' do
    #Given
    create_event('appointment', '2016-05-23 9:30', '2016-05-23 10:30', false)
    create_event('appointment', '2016-05-23 10:30', '2016-05-23 12:00', false)
    create_event('appointment', '2016-05-23 10:00', '2016-05-23 15:00', false)
    create_event('appointment', '2016-05-23 9:30', '2016-05-23 15:00', false)
    create_event('appointment', '2016-05-23 10:30', '2016-05-23 15:00', false)

    #When
    events = Event.all

    #Then
    assert_equal 2, events.size
  end

  test 'Edge case: appointments can be successive' do
    #Given
    create_event('appointment', '2016-05-23 11:00', '2016-05-23 11:30', false)
    create_event('appointment', '2016-05-23 11:30', '2016-05-23 12:00', false)

    #When
    events = Event.all

    #Then
    assert_equal 2, events.size
  end

  test 'Edge case: full week of work' do
    #Given
    ## Some recurring openings (basic agenda)
    create_event('opening', '2016-11-28 10:00', '2016-11-28 14:30', true)
    create_event('opening', '2016-11-29 10:00', '2016-11-28 15:30', true)
    create_event('opening', '2016-11-30 9:30', '2016-11-30 14:30', true)
    create_event('opening', '2016-12-01 9:00', '2016-12-01 15:00', true)
    create_event('opening', '2016-12-02 9:00', '2016-12-02 12:00', true)
    ## Adding some specific opening slots on our tested week
    create_event('opening', '2017-01-09 16:00', '2017-01-09 18:00', false)
    create_event('opening', '2017-01-13 14:00', '2017-01-13 16:00', true)

    ## Booking appointments for the week
    create_event('appointment', '2017-01-09 10:30', '2017-01-09 12:00', false)
    create_event('appointment', '2017-01-09 12:30', '2017-01-09 14:30', false)
    create_event('appointment', '2017-01-09 15:00', '2017-01-09 17:00', false)

    create_event('appointment', '2017-01-10 10:00', '2017-01-10 12:00', false)
    create_event('appointment', '2017-01-10 12:00', '2017-01-10 14:00', false)
    create_event('appointment', '2017-01-10 14:00', '2017-01-10 15:30', false)

    ## Attempting to double-book will fail on this one
    create_event('appointment', '2017-01-09 11:30', '2017-01-09 12:30', false)

    #When
    availabilities = Event.availabilities DateTime.parse('2017-01-09')

    #Then
    assert_equal DateTime.parse('2017-01-09'), availabilities[0][:date]
    assert_equal %w(10:00 12:00 17:00 17:30), availabilities[0][:slots]

    assert_equal DateTime.parse('2017-01-10'), availabilities[1][:date]
    assert_equal [], availabilities[1][:slots]

    assert_equal DateTime.parse('2017-01-11'), availabilities[2][:date]
    assert_equal %w(9:30 10:00 10:30 11:00 11:30 12:00 12:30 13:00 13:30 14:00), availabilities[2][:slots]

    assert_equal DateTime.parse('2017-01-12'), availabilities[3][:date]
    assert_equal %w(9:00 9:30 10:00 10:30 11:00 11:30 12:00 12:30 13:00 13:30 14:00 14:30), availabilities[3][:slots]

    assert_equal DateTime.parse('2017-01-13'), availabilities[4][:date]
    assert_equal %w(9:00 9:30 10:00 10:30 11:00 11:30 14:00 14:30 15:00 15:30), availabilities[4][:slots]

    assert_equal DateTime.parse('2017-01-14'), availabilities[5][:date]
    assert_equal [], availabilities[5][:slots]

    assert_equal DateTime.parse('2017-01-15'), availabilities[6][:date]
    assert_equal [], availabilities[6][:slots]
  end

  #Leaving this one verbatim
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
