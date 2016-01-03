require 'minitest/autorun'
require 'minitest/pride'
require_relative 'event_reporter'

class EventReporterTest < Minitest::Test
  def test_load_data
    sample_data = 'fixtures/event_attendee_fixture.csv'
    event_reporter = EventReporter.new
    expected = [{
                 "last_name" => "Nguyen",
                 "first_name" => "Allison",
                 "email" => "arannon@jumpstartlab.com",
                 "zipcode" => "20010",
                 "city" => "Washington",
                 "state" => "DC",
                 "address" => "3155 19th St NW",
                 "phone" => "6154385000"
               }]
    assert_equal expected, event_reporter.load_csv(sample_data)
  end

  def test_queue_count_is_zero_without_loading_data
    event_reporter = EventReporter.new
    assert_equal 0, event_reporter.queue_count
  end

  def test_find_last_name_changes_queue_count
    event_reporter = EventReporter.new

    event_reporter.load_csv
    assert_equal 0, event_reporter.queue_count

    event_reporter.find("first_name", "Mary")
    assert_equal 16, event_reporter.queue_count
  end

  def test_find_city_changes_queue_count
    event_reporter = EventReporter.new

    event_reporter.load_csv
    event_reporter.find("city", "Salt Lake City")
    assert_equal 13, event_reporter.queue_count
  end

  def test_find_state_changes_queue_count
    event_reporter = EventReporter.new

    event_reporter.load_csv
    event_reporter.find("state", "MD")
    assert_equal 294, event_reporter.queue_count
  end

  def test_queue_clear_clears_queue
    event_reporter = EventReporter.new

    event_reporter.load_csv
    event_reporter.find("first_name", "Mary")
    assert_equal 16, event_reporter.queue_count

    event_reporter.queue_clear
    assert_equal 0, event_reporter.queue_count
  end

  def test_queue_changes_after_second_find_call
    event_reporter = EventReporter.new

    event_reporter.load_csv
    event_reporter.find("first_name", "Mary")
    assert_equal 16, event_reporter.queue_count

    event_reporter.find("first_name", "Meaghan")
    assert_equal 2, event_reporter.queue_count
  end

  def test_queue_print
    event_reporter = EventReporter.new

    event_reporter.load_csv
    event_reporter.find("first_name", "Meaghan")

    assert_equal 2, event_reporter.queue_count

    expected = "LAST NAME\tFIRST NAME\tEMAIL\tZIPCODE\tCITY\tSTATE\tADDRESS\tPHONE\nCiolino\tMeaghan\tflhne3ml@jumpstartlab.com\t04879\tyes\tSD\t3 no\t8608739000\nCunningham\tMeaghan\tnjompsonswartz@jumpstartlab.com\t20016\tWashington\tDC\t3825 Wisconsin Avenue NW\t3016545000"
    assert_equal expected, event_reporter.queue_print
  end

  def test_queue_print_by_phone_number
    event_reporter = EventReporter.new

    event_reporter.load_csv
    event_reporter.find("first_name", "Meaghan")

    expected = "LAST NAME\tFIRST NAME\tEMAIL\tZIPCODE\tCITY\tSTATE\tADDRESS\tPHONE\nCunningham\tMeaghan\tnjompsonswartz@jumpstartlab.com\t20016\tWashington\tDC\t3825 Wisconsin Avenue NW\t3016545000\nCiolino\tMeaghan\tflhne3ml@jumpstartlab.com\t04879\tyes\tSD\t3 no\t8608739000"
    assert_equal expected, event_reporter.queue_print_by("phone")
  end

  def test_queue_save_to
    event_reporter = EventReporter.new

    event_reporter.load_csv
    event_reporter.find("first_name", "Meaghan")

    event_reporter.queue_save_to("test.csv")
    expected = "LAST NAME, FIRST NAME, EMAIL, ZIPCODE, CITY, STATE, ADDRESS, PHONE\nCiolino, Meaghan, flhne3ml@jumpstartlab.com, 04879, yes, SD, 3 no, 8608739000\nCunningham, Meaghan, njompsonswartz@jumpstartlab.com, 20016, Washington, DC, 3825 Wisconsin Avenue NW, 3016545000\n"

    assert_equal expected, File.read("test.csv")
  end

  def test_queue_save_to_after_sorting_queue
    event_reporter = EventReporter.new

    event_reporter.load_csv
    event_reporter.find("first_name", "Meaghan")
    event_reporter.queue_print_by("phone")

    event_reporter.queue_save_to("test_sorted.csv")
    expected = "LAST NAME, FIRST NAME, EMAIL, ZIPCODE, CITY, STATE, ADDRESS, PHONE\nCunningham, Meaghan, njompsonswartz@jumpstartlab.com, 20016, Washington, DC, 3825 Wisconsin Avenue NW, 3016545000\nCiolino, Meaghan, flhne3ml@jumpstartlab.com, 04879, yes, SD, 3 no, 8608739000\n"

    assert_equal expected, File.read("test_sorted.csv")
  end

  def test_find_last_name_emptiness
    event_reporter = EventReporter.new

    event_reporter.load_csv
    event_reporter.find("last_name", "Secor")
    assert_equal 0, event_reporter.queue_count
    assert_equal "", event_reporter.queue_print
  end

  def test_emptiness
    event_reporter = EventReporter.new

    event_reporter.find("last_name", "Secor")
    assert_equal 0, event_reporter.queue_count
    assert_equal "", event_reporter.queue_print
    assert_equal "", event_reporter.queue_print_by("last_name")

    event_reporter.queue_save_to("test_empty.csv")
    expected = "LAST NAME, FIRST NAME, EMAIL, ZIPCODE, CITY, STATE, ADDRESS, PHONE\n"

    assert_equal expected, File.read("test_empty.csv")
  end

  def test_receive_correct_messages_help
    event_reporter = EventReporter.new

    assert_equal "Available commands:\nload\nhelp\nqueue count\nqueue clear\nqueue print\nqueue print by\nqueue save to\nfind\nquit", event_reporter.message("help")
    assert_equal "Erases any loaded data and parses the specified file. If no filename is given, defaults to event_attendees.csv", event_reporter.message("help load")
    assert_equal "Outputs how many records are in the current queue.", event_reporter.message("help queue count")
    assert_equal "Empties the queue.", event_reporter.message("help queue clear")
    assert_equal "Prints out a tab-delimited data table.", event_reporter.message("help queue print")
    assert_equal "Prints the data table sorted by the specified attribute.", event_reporter.message("help queue print by")
    assert_equal "Exports the current queue to the specified filename as a CSV.", event_reporter.message("help queue save to")
    assert_equal "Loads the queue with all records matching the criteria for the given attribute.", event_reporter.message("help find")
    assert_equal "Exits event reporter.", event_reporter.message("help quit")
  end
end
