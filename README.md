# Picky Eater
A library that ingests NYC Restaurant Inspection Results data (courtesy of data.cityofnewyork.us), and provides and web endpoint to query against the ingested data.

## Preview
Currently, the web endpoint is currently hosted on Heroku. Check it out: https://quiet-ravine-73694.herokuapp.com/restaurants

## Getting Started
### Prerequisites
* In order to run the code, please make sure you have a Ruby runtime installed on your machine and a Postgres server available.

### Installing
Download this project. Then run `bundle install` within the project directory from the command line.

## How To Run ETL
Within the lib/workers directory, run:
```
ruby etl.rb
```
NOTE:
* You will need to have the DATABASE_URL environment variable set, and access to a running Postgres server.
* The tables of the restaurant inspection data model will have to already exist. To create them, you can run something like `ruby setup_tables.rb` where setup_tables.rb looks something like this:
```ruby
# setup_tables.db

require 'pg'
require 'sequel'

db = Sequel.connect(ENV['DATABASE_URL'])

db.create_table :restaurants do
    String      :camis, primary_key: true
    String      :dba, null: false
    String      :phone, null: false
    String      :cuisine
    String      :grade, index: true, null: false
    Date        :grade_date, null: false
end

db.create_table :locations do
    Integer     :id, primary_key: true
    String      :building, null: false
    String      :street, null: false
    String      :boro, null: false
    String      :zipcode, null: false
end

db.create_table :restaurant_locations do
    foreign_key :restaurant_camis, :restaurants, unique: true, type: String
    foreign_key :location_id, :locations, index: true, type: Integer
end

db.disconnect
```

Once the database is populated, you should be able to run queries against it, such as:
```sql
SELECT r.*,l.building, l.street, l.boro, l.zipcode
FROM restaurants r
INNER JOIN restaurant_locations rl on rl.restaurant_camis = r.camis
INNER JOIN locations l on rl.location_id = l.id
WHERE r.grade <= 'B' AND r.cuisine LIKE '%Thai%';
```
Which will return all restaurants that serve Thai food and have an inspection grade that is B or higher.

## How To Run Web Endpoint
To get a local webserver running that will serve the ingested data, run the following the the root of the project directory:
```
rackup config.ru
```

Once the webserver and Postgres server are running, you should be able to run request such as:
```
curl https://localhost:9292/restaurants?cuisine=Thai&grade=B
```
Which will return all restaurants that serve Thai food and have an inspection grade that is B.

## Design Considerations
* I chose the three table schema (restaurants, restaurant_locations, locations) because doing so reduces the amount of redundant location data. Multiple restaurants can share the same location, such as those that reside in a food court. If the ingested data were kept as one table, there would be a large number of duplicated location information.
* Loading the database overwrites the existing data, instead of appending to it. This has a couple of advantages:
  * We don't have to worry about checking against pre-existing data or managing data association during the load, which would slow it down.
  * We don't have to worry about keeping stale data in the database. The API that provides the NYC Restaurant Inspection Results data is update daily, and it only keeps data going as far back as 3 years prior to the most recent inspection. Therefore, assuming we running the ETL periodically, any restaurants that have closed will eventually be removed from our database.

## TODOS
* The ETL implemented here goes through the stages sequentially. I would like to explore concurrent approaches that would improve performace, such as transformring the data as it's being validated, instead of waiting for the extraction phase to complete.
* Better logging mechanism.
* Make use of a message queueing service like AWS SQS to better decouple workers and remove setup logic from etl.rb.
* Leverage an external storage service like AWS S3 to store intermediate files
* Improve test coverage. There are some tests, but there could be more, including integration tests.

## Author
Richard Nwaobasi

