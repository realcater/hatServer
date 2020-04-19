docker stop postgres
docker rm postgres
docker run --name postgres -e POSTGRES_DB=vapor \
  -e POSTGRES_USER=vapor -e POSTGRES_PASSWORD=vapor \
  -p 5432:5432 -d postgres
