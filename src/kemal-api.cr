require "kemal"
require "json"
require "pg"

DB_URL = "postgres://postgres:postgres@localhost/test_db"
db = PG.connect(DB_URL)

module Kemal::Api
  VERSION = "0.1.0"

  get "/people" do
    person = {first_name: "John", last_name: "Doe"}
    person.to_json
  end

  post "/people/:id" do |context|
    id = context.params.url["id"]?

    # Verifica se o corpo da requisição é nulo
    if context.request.body.nil?
      error = {message: "Request body cannot be nil"}
      halt context, status_code: 400, response: error.to_json
    end

    # Lê o corpo da requisição como uma string
    request_body = context.request.body.not_nil!.gets_to_end

    # Verifica se o corpo da requisição está vazio
    if request_body.empty?
      error = {message: "Request body cannot be empty"}
      halt context, status_code: 400, response: error.to_json
    end

    # Parse o corpo da requisição como JSON
    body_json = JSON.parse(request_body)
    first_name = body_json["first_name"]?
    last_name = body_json["last_name"]?

    if !first_name || !last_name
      error = {message: "Both first and last name must be given"}
      halt context, status_code: 403, response: error.to_json
    end

    {person: "Person with name #{first_name} #{last_name} and id #{id} created"}.to_json
  end

  post "/users" do |env|
    begin
      json_data = JSON.parse(env.request.body.not_nil!)

      name = json_data["name"].as_s
      email = json_data["email"].as_s

      db.exec("INSERT INTO users (name, email) VALUES ($1, $2)", name, email)

      env.response.print({message: "User created successfully"}.to_json)
    rescue ex : Exception
      env.response.print({error: ex.message}.to_json)
    end
  end

  get "/users" do |env|
    begin
      users = [] of Hash(String, String)

      result = db.query("SELECT name, email FROM users")
      result.each do
        user = {
          "name"  => result.read(String),
          "email" => result.read(String),
        }
        users << user
      end

      env.response.print(users.to_json)
    rescue ex : Exception
      env.response.print({error: ex.message}.to_json)
    end
  end

  Kemal.run
end
