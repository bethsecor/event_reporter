require 'csv'
require 'active_support/inflector'
require 'pry'

class EventReporter
  def initialize
    @data = []
    @queue = []
  end

  def repl
    puts "Welcome to Event Reporter!"
    loop do
      puts "->"
      request = gets.chomp
      puts message(request)
      process(request)
      break if request == "quit"
    end
  end

  def process(request)
    parsed_request = request.split(" ")
    if request.start_with?("load")
      parsed_request.length == 1 ? load_csv : load_csv(parsed_request.last)
      puts "Data loaded."
    elsif request.start_with?("queue")
      process_queue(request)
    elsif request.start_with?("find")
      find(parsed_request[1],parsed_request[2])
      puts "Records found."
    end
  end

  def process_queue(queue_request)
    queue_request = queue_request.sub("queue ", "")
    parsed_queue_request = queue_request.split(" ")
    case
    when queue_request.start_with?("count")
      puts "Queue record count is #{queue_count}."
    when queue_request.start_with?("clear")
      queue_clear
      puts "Queue cleared."
    when queue_request.start_with?("print by")
      puts queue_print_by(parsed_queue_request[2])
    when queue_request.start_with?("print")
      puts queue_print
    when queue_request.start_with?("save")
      queue_save_to(parsed_queue_request[2])
      puts "Data saved to #{parsed_queue_request[2]}"
    end
  end

  def message(request)
    case
    when request.start_with?("help")
      help_messages(request)
    when request.start_with?("load")
      "Loading data..."
    when request.start_with?("queue")
      queue_messages(request)
    when request.start_with?("find")
      "Finding records..."
    when request == "quit"
      "Thanks for using Event Reporter!"
    else
      "Please make a proper request. Type 'help' for a list of commands."
    end
  end

  def help_messages(help_request)
    help_request = help_request.split(" ")
    if help_request.length == 1
      "Available commands:\n#{command_descriptions.keys.join("\n")}"
    else
      command_descriptions[help_request.drop(1).join(" ")]
    end
  end

  def queue_messages(queue_request)
    queue_request = queue_request.sub("queue ", "")
    case
    when queue_request.start_with?("count")
      "Counting records..."
    when queue_request.start_with?("clear")
      "Clearing queue..."
    when queue_request.start_with?("print by")
      "Printing records..."
    when queue_request.start_with?("save")
      "Saving records..."
    end
  end

  def load_csv(data='event_attendees.csv')
    contents = CSV.open data, headers: true, header_converters: :symbol
    @data = contents.map do |row|
       {
          "last_name" => row[:last_name],
          "first_name" => row[:first_name],
          "email" => row[:email_address],
          "zipcode" => clean_zipcode(row[:zipcode]),
          "city" => row[:city],
          "state" => row[:state],
          "address" => clean_address(row[:street]),
          "phone" => clean_phone(row[:homephone])
        }
    end
  end

  def find(attribute, criteria)
    unless @data.empty?
      @queue = @data.select do |record|
        record[attribute].nil? ? false : record[attribute].strip.downcase == criteria.downcase
      end
    end
  end

  def queue_count
    @queue.count
  end

  def queue_clear
    @queue = []
  end

  def queue_print
    if @queue.empty?
      ""
    else
      formatted_records = @queue.map { |record| record.values.join("\t") }
      (table_header + formatted_records).join("\n")
    end
  end

  def queue_print_by(attribute)
    i = attributes.index(attribute)
    queue_a = @queue.map { |record| record.to_a }
    sorted_queue_a = queue_a.sort { |x,y| x[i][1] <=> y[i][1] }
    @queue = sorted_queue_a.map { |record| record.to_h }
    queue_print
  end

  def queue_csv
    formatted_records = @queue.map { |record| record.values.join(", ") }
    (table_header_csv + formatted_records).join("\n")
  end

  def queue_save_to(filename)
    File.open(filename,'w') do |file|
      file.puts queue_csv
    end
  end

  def clean_phone(phone_number)
    phone_number = phone_number.chars.select { |l| l =~ /[0-9]/ }.join
      if phone_number.length == 11 && phone_number.start_with?("1")
        phone_number = phone_number[1..-1]
      elsif phone_number.length == 10
        phone_number
      else
        phone_number = "0"*10
      end
  end

  def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5,"0")[0..4]
  end

  def clean_address(address)
    address.nil? ? nil : address.gsub(",", "")
  end

  def command_descriptions
    {
      "load" => "Erases any loaded data and parses the specified file. If no filename is given, defaults to event_attendees.csv",
      "help" => "Outputs a list of available commands. help <command> will give you a description of how to use the specific command.",
      "queue count" => "Outputs how many records are in the current queue.",
      "queue clear" => "Empties the queue.",
      "queue print" => "Prints out a tab-delimited data table.",
      "queue print by" => "Prints the data table sorted by the specified attribute.",
      "queue save to" => "Exports the current queue to the specified filename as a CSV.",
      "find" => "Loads the queue with all records matching the criteria for the given attribute.",
      "quit" => "Exits event reporter."
    }
  end

  def table_header
    ["LAST NAME\tFIRST NAME\tEMAIL\tZIPCODE\tCITY\tSTATE\tADDRESS\tPHONE"]
  end

  def table_header_csv
    ["LAST NAME, FIRST NAME, EMAIL, ZIPCODE, CITY, STATE, ADDRESS, PHONE"]
  end

  def attributes
    ["last_name","first_name","email","zipcode","city","state","address","phone"]
  end
end

if __FILE__ == $0
  EventReporter.new.repl
end
