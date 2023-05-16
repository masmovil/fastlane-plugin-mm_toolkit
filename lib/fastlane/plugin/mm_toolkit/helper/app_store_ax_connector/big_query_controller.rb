require "google/cloud/bigquery"

class BigQueryController
  attr_reader :credentials, :project_id, :dataset_id, :table_id, :bigquery
#credentials related with BQ
#project_id related with BQ
#dataset_id related with BQ
#table_id related with BQ
def initialize(credentials, project_id, dataset_id, table_id)
    @credentials = credentials
    @project_id = project_id
    @dataset_id = dataset_id
    @table_id = table_id
    @bigquery = nil
    @dataset = nil
    @table = nil
    setup
end

#ENV["GOOGLE_APPLICATION_CREDENTIALS"] =  "#{__dir__}/#{credentials}"

def setup
  @bigquery = Google::Cloud::Bigquery.new(project: @project_id, credentials: @credentials)
  @dataset = bigquery.dataset(@dataset_id)
  @table = @dataset.table(@table_id)
end

def insert(data)
  if !@dataset.exists?
    raise "Error dataset doesn't exist - #{result.error}"
  end

  if @table.exists?
    response = @table.insert data

    if response.success?
      puts "Inserted rows successfully"
    else
      raise "Failed to insert #{response.error_rows.count} rows"
    end
  else
    raise "Error table doesn't exist or the data to try insert in BBDD previously exists"
  end
end
end