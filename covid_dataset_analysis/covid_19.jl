### A Pluto.jl notebook ###
# v0.12.4

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 10edf2d0-0bc3-11eb-3e2f-19a0b80f2e8f
begin
	using CSV
	using DataFrames
	using ZipFile
	using Shapefile
	using PlutoUI
	using Plots
	using Dates
end

# ╔═╡ 10d2bdce-0fa1-11eb-08db-1342838baab2
using Statistics

# ╔═╡ 3420dfb0-0bc3-11eb-3b53-1916d63caea3
md"# Covid dataset visualization"

# ╔═╡ 974ed8e0-0bc2-11eb-11a0-1ff111b7fbef
url = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv";

# ╔═╡ 31bc14ae-0bc3-11eb-207b-c98dba047d4f
download(url,"covid_data.csv")

# ╔═╡ 616d66a0-0bc3-11eb-1d14-49612ce0e294
begin
	covid_data = CSV.File("covid_data.csv")
	data = DataFrame(covid_data)
end

# ╔═╡ aeb4e0f2-0bc3-11eb-2d53-df8bbad7ac55
rename!(data,"Province/State" => :province,"Country/Region" => :country,"Lat" => :latitude,"Long"=> :longitude)

# ╔═╡ afd8d210-0bc4-11eb-0e84-d9c0835a287f
begin
	province = data.province
	all_countries = data.country
	indices = ismissing.(province)
	province[indices] = all_countries[indices]
end

# ╔═╡ 7c38c450-0bc5-11eb-2fbb-0514d019a444
begin
	shape_file_url = "https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/110m/cultural/ne_110m_admin_0_countries.zip"
	download(shape_file_url,"ne_110m_admin_0_countries.zip")
	r = ZipFile.Reader("ne_110m_admin_0_countries.zip")
	for f in r.files
		println("FileName:$(f.name)")
		open(f.name,"w") do io
		 write(io,read(f))
		end
	end
end

# ╔═╡ 50f621b0-0bc6-11eb-0f7e-f5a600b3b299
shp_countries = Shapefile.shapes(Shapefile.Table("./ne_110m_admin_0_countries.shp"))

# ╔═╡ 7fd7a07e-0bc6-11eb-03ec-7f5e234dab3e
plot(shp_countries,alpha=0.2)

# ╔═╡ e41d07ae-0bc6-11eb-0786-c7bc1ac81ef0
daily = max.(1,diff(Array(data[:,5:end]),dims=2))

# ╔═╡ 863ec470-0bc7-11eb-1bfe-edd3cc8fc52b
begin
	dates_str_arr = names(data)[5:end]
	date_format = Dates.DateFormat("m/dd/Y")
	dates = parse.(Date,dates_str_arr,date_format) .+ Year(2000)
end

# ╔═╡ 5747afe0-0bc9-11eb-1a4e-1901f2853e86
@bind current_day Slider(1:length(dates)-1,show_value=true)

# ╔═╡ 3b321df0-0bd2-11eb-0c68-17563ef106c3


# ╔═╡ 731ffba0-0bc9-11eb-2617-5d112989e8e2
dates[current_day]

# ╔═╡ f63c96b0-0bc9-11eb-36dc-999d134d8c31
world_plot = begin
	plot(shp_countries,alpha=0.2)
	scatter!(data.longitude,data.latitude,leg=false,ms = 2*log10.(daily[:,current_day]))
	xlabel!("Longitude")
	ylabel!("Latitude")
	title!("Daily Cases")
end

# ╔═╡ a7e73960-0bca-11eb-0301-b5c68cdf9c1c
world_plot

# ╔═╡ 4b61c700-0bd9-11eb-120f-23b0a7d4b997
gd_data = groupby(data, :country)

# ╔═╡ 756dc8ee-0bd9-11eb-24aa-2711dff50860
data_by_country = combine(gd_data,names(data)[5:end] .=> sum);

# ╔═╡ 98d62b70-0bde-11eb-29b8-29266d92604c
countries = unique(all_countries)

# ╔═╡ 48073bf2-0fab-11eb-2363-09f6c00283d1
all_countries

# ╔═╡ c3a68ed0-0bde-11eb-1504-2ba11396878e
@bind Country_Selector Select(countries)

# ╔═╡ 91d99df0-0be0-11eb-07ea-1d6bcbd33f71
begin
	country_data = data_by_country[data_by_country.country .== Country_Selector,
			2:end]
	country_data_vec = Vector(country_data[1,:])
	scatter(dates,country_data_vec,label=Country_Selector,leg=:topleft)
	xlabel!("date")
	ylabel!("cumulative cases")
end

# ╔═╡ d5fe4f60-0be2-11eb-02e4-d56475a09ae2
typeof(Country_Selector)

# ╔═╡ 481a0a7e-0be3-11eb-3b7c-e72440775ab3
country_data_daily = diff(country_data_vec)

# ╔═╡ 659b79a0-0fd9-11eb-0c5a-594fd6ddbb31
sum(country_data_daily[end-13:end])

# ╔═╡ 5a7dd5d0-0be3-11eb-2041-a92ccdf7e1c2
begin
	plot(dates[1:end-1],country_data_daily,label=Country_Selector,leg=false)
	scatter!(dates[1:end-1],country_data_daily,label=Country_Selector,leg=:topleft)
	ylabel!("Daily Cases")
end

# ╔═╡ 1e91f3b0-0be5-11eb-0a93-efafac13da30
country_data_daily[end-10:end]

# ╔═╡ 58c4f000-0fb9-11eb-1fe4-a7f749152609
running_average_7day_cases = [mean(country_data_daily[i-6:i]) for i = 7:length(country_data_daily)]

# ╔═╡ fff3b460-0fb9-11eb-25c2-5b28125340ce
begin
	plot(dates[8:end],running_average_7day_cases,label=Country_Selector,leg=false)
	scatter!(dates[8:end],running_average_7day_cases,label=Country_Selector,leg=:topleft)
	ylabel!("Daily Cases - 7 days running average")
end

# ╔═╡ d0606b30-0f8c-11eb-2a51-218337116b2b
covid_deaths_url = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv"

# ╔═╡ f2b728e2-0f8c-11eb-35e5-ada588a52c4f
download(covid_deaths_url,"covid19_deaths_global.csv");

# ╔═╡ 1c637ea0-0f8d-11eb-3e7f-d5226699dab6
begin
	covid19_deaths_csv_data = CSV.File("covid19_deaths_global.csv");
	covid19_deaths_df = DataFrame(covid19_deaths_csv_data);
	
end

# ╔═╡ f20c4d70-0f8d-11eb-1e98-69b599afe5fa
rename!(covid19_deaths_df,1=> :province,2 => :country,3 => :latitude,4 => :longitude);

# ╔═╡ 425e6fb0-0f8e-11eb-11f2-b1b500c8ec12
gd_deaths_data = groupby(covid19_deaths_df, :country);

# ╔═╡ 74e07860-0f8f-11eb-3206-7957472a1c35
by_country_deaths_data = combine(gd_deaths_data,names(gd_deaths_data)[5:end] .=>sum);

# ╔═╡ f2f82220-0f8f-11eb-04ba-e736702e76ef
@bind Country_Selector2 Select(countries)

# ╔═╡ 0ee8d7e0-0f90-11eb-2acc-63b7b0b26cf6
begin
	country_deaths_data = by_country_deaths_data[by_country_deaths_data.country .== Country_Selector2,
			2:end]
	country_deaths_data_vec = Vector(country_deaths_data[1,:])
	scatter(dates,country_deaths_data_vec,label=Country_Selector2,leg=:topleft)
	xlabel!("date")
	ylabel!("cumulative deaths")
end

# ╔═╡ e91082a0-0f91-11eb-1efc-ad38205b7dca
country_deaths_data_daily = diff(country_deaths_data_vec);

# ╔═╡ fc6a6dc0-0f91-11eb-0343-496438286be6
begin
	plot(dates[1:end-1],country_deaths_data_daily,label=Country_Selector2,leg=false)
	scatter!(dates[1:end-1],country_deaths_data_daily,label=Country_Selector2,leg=:topleft)
	ylabel!("Daily Deaths")
end

# ╔═╡ fe920480-0f98-11eb-30f5-9d69e57e725a
country_deaths_data_daily[end-10:end]

# ╔═╡ 59191762-0fa1-11eb-03b1-71b474807dc5
seven_day_running_avg_covid_deaths = [mean(country_deaths_data_daily[i-6:i]) for i=7:length(country_deaths_data_daily)]

# ╔═╡ 11f24220-0fa2-11eb-2e38-5b19d556c844
length(seven_day_running_avg_covid_deaths)

# ╔═╡ 5df8b0f0-0fa2-11eb-057a-1b23d08eca5e
length(dates[7:end])

# ╔═╡ 19250ff0-0fa2-11eb-2bbd-ff593c87f164
begin
	plot(dates[8:end],seven_day_running_avg_covid_deaths,label = Country_Selector2,leg=false)
	scatter!(dates[8:end],seven_day_running_avg_covid_deaths,label=Country_Selector2,leg=:topleft)
	ylabel!("Daily Deaths - 7 day running average")
end

# ╔═╡ 94730e2e-0fa9-11eb-319c-af0932d0daba
seven_day_running_avg_covid_deaths

# ╔═╡ Cell order:
# ╠═10edf2d0-0bc3-11eb-3e2f-19a0b80f2e8f
# ╟─3420dfb0-0bc3-11eb-3b53-1916d63caea3
# ╠═974ed8e0-0bc2-11eb-11a0-1ff111b7fbef
# ╠═31bc14ae-0bc3-11eb-207b-c98dba047d4f
# ╠═616d66a0-0bc3-11eb-1d14-49612ce0e294
# ╠═aeb4e0f2-0bc3-11eb-2d53-df8bbad7ac55
# ╠═afd8d210-0bc4-11eb-0e84-d9c0835a287f
# ╠═7c38c450-0bc5-11eb-2fbb-0514d019a444
# ╠═50f621b0-0bc6-11eb-0f7e-f5a600b3b299
# ╠═7fd7a07e-0bc6-11eb-03ec-7f5e234dab3e
# ╠═e41d07ae-0bc6-11eb-0786-c7bc1ac81ef0
# ╠═863ec470-0bc7-11eb-1bfe-edd3cc8fc52b
# ╠═5747afe0-0bc9-11eb-1a4e-1901f2853e86
# ╠═3b321df0-0bd2-11eb-0c68-17563ef106c3
# ╠═731ffba0-0bc9-11eb-2617-5d112989e8e2
# ╠═f63c96b0-0bc9-11eb-36dc-999d134d8c31
# ╠═a7e73960-0bca-11eb-0301-b5c68cdf9c1c
# ╠═4b61c700-0bd9-11eb-120f-23b0a7d4b997
# ╠═756dc8ee-0bd9-11eb-24aa-2711dff50860
# ╠═98d62b70-0bde-11eb-29b8-29266d92604c
# ╠═48073bf2-0fab-11eb-2363-09f6c00283d1
# ╠═c3a68ed0-0bde-11eb-1504-2ba11396878e
# ╠═91d99df0-0be0-11eb-07ea-1d6bcbd33f71
# ╠═d5fe4f60-0be2-11eb-02e4-d56475a09ae2
# ╠═481a0a7e-0be3-11eb-3b7c-e72440775ab3
# ╠═659b79a0-0fd9-11eb-0c5a-594fd6ddbb31
# ╠═5a7dd5d0-0be3-11eb-2041-a92ccdf7e1c2
# ╠═1e91f3b0-0be5-11eb-0a93-efafac13da30
# ╠═58c4f000-0fb9-11eb-1fe4-a7f749152609
# ╠═fff3b460-0fb9-11eb-25c2-5b28125340ce
# ╠═d0606b30-0f8c-11eb-2a51-218337116b2b
# ╠═f2b728e2-0f8c-11eb-35e5-ada588a52c4f
# ╠═1c637ea0-0f8d-11eb-3e7f-d5226699dab6
# ╠═f20c4d70-0f8d-11eb-1e98-69b599afe5fa
# ╠═425e6fb0-0f8e-11eb-11f2-b1b500c8ec12
# ╠═74e07860-0f8f-11eb-3206-7957472a1c35
# ╠═f2f82220-0f8f-11eb-04ba-e736702e76ef
# ╠═0ee8d7e0-0f90-11eb-2acc-63b7b0b26cf6
# ╠═e91082a0-0f91-11eb-1efc-ad38205b7dca
# ╠═fc6a6dc0-0f91-11eb-0343-496438286be6
# ╠═fe920480-0f98-11eb-30f5-9d69e57e725a
# ╠═10d2bdce-0fa1-11eb-08db-1342838baab2
# ╠═59191762-0fa1-11eb-03b1-71b474807dc5
# ╠═11f24220-0fa2-11eb-2e38-5b19d556c844
# ╠═5df8b0f0-0fa2-11eb-057a-1b23d08eca5e
# ╠═19250ff0-0fa2-11eb-2bbd-ff593c87f164
# ╠═94730e2e-0fa9-11eb-319c-af0932d0daba
