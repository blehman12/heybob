#foreman start -f Procfile.dev


# Start Redis first
sudo service redis-server start
# or
redis-server &

# Then start Rails
rails server
