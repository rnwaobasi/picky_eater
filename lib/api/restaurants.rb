require 'sinatra'
require 'sequel'
require_relative '../db/datastore'

get '/restaurants' do
    bad_params = params.to_h.reject {|k,v| k == 'cuisine' || k == 'grade'}
    if !bad_params.empty?
        halt 400
    end

    DB::DS.get_restaurants(params).to_json
end