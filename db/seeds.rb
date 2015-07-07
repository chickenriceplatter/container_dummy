city_attributes = [
{ name: "New York", state: "New York", year_of_incorporation: 1653 },
{ name: "Los Angeles", state: "California", year_of_incorporation: 1850 },
{ name: "Chicago", state: "Illinois", year_of_incorporation: 1833 },
{ name: "Houston", state: "Texas", year_of_incorporation: 1837 },
{ name: "Philadelphia", state: "Pennsylvania", year_of_incorporation: 1701 }
]

city_attributes.each do |city|
  City.find_or_create_by!(city)
end
