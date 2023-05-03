require "google/cloud/bigquery"

class BigQueryController
  attr_reader :project_id, :dataset_id, :table_id, :bigquery

#Proyect id related with BQ
#Dataset id related with BQ
#Table id related with BQ
def initialize(project_id, dataset_id, table_id)
    @project_id = project_id
    @dataset_id = dataset_id
    @table_id = table_id
    @bigquery = nil
    @dataset = nil
    @table = nil
    setup
end

# Assign route for credentials archive
ENV["GOOGLE_APPLICATION_CREDENTIALS"] =  "#{__dir__}/appstore-test-383407-6b07cf0b74a0.json"

def setup
  @bigquery = Google::Cloud::Bigquery.new(project: @project_id)
  @dataset = bigquery.dataset(@dataset_id)
  @table = @dataset.table(@table_id)
  puts 'Dataset and Table Loaded'
end

def insert(data)
  puts "To save #{data}"
  if !@dataset.exists?
    raise "Error dataset don't exist - #{result.error}"
  end

  #Check if the data for insert in table don't exists in.
  date_from_search_data = Date.today.prev_day
  #check = check_if_data_exist(date_from_search_data, "date")

  #if @table.exists? && check_if_data_exist(date_from_search_data, "date")
  if @table.exists?
    inserter = @table.insert_async do |result|
      if result.error?
        raise "Error when table try to insert data in BBDD - #{result.error}"
      else
        puts "inserted #{result.insert_count} rows " \
          "with #{result.error_count} errors"
      end
    end
    
    inserter.insert data
    
    inserter.stop.wait!
  else
    raise "Error table don't exist or the data to try insert in BBDD previously exists - #{result.error}"
  end

  def search(data, from_field)
    @bigquery.query("SELECT COUNT(*) as count FROM #{@table} WHERE #{from_field} = '#{data}'")
  end

  def deleteAll
    "DELETE FROM #{@table} WHERE 1=1"
  end

  def check_if_data_exist(data)
    result = search(data).first
    if result["count"] > 0
      puts "Data exist"
    else
      puts "Data don't exist"
    end
  end
end
end