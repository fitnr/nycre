nycre
=====

Download and pre-process New York City real estate sales data.

The NYC Department of Finance maintains two real estate data sets:
* [Rolling Sales](http://www.nyc.gov/html/dof/html/property/rolling_sales_data.shtml): All sales for the last twelve months (usually running with a 2-3 month delay)
* [Annualized Sales](http://www.nyc.gov/html/dof/html/property/rolling_sales_data_annualized.shtml): Files with sales records for each year.
* [Summary Data](http://www.nyc.gov/html/dof/html/property/rolling_sales_data_annualized.shtml): Year-by-year summaries of average prices by neighborhood

## Requirements

* [NPM](http://nodejs.org/download/)
* [csvkit](https://github.com/onyxfish/csvkit)

Yes, it's annoying to require both Javascript and Python packages but csvkit is super-useful.

## Installing

```
$ git clone git@github.com:fitnr/nycre.git
$ make install
```

## Downloading data

The download tasks convert DOF's excel files to CSV, but don't do any cleaning or other processing.

### Sales

To download all the annual sales data, download or clone the repository and run:

````
$ make
````

This will create a `sales` folder with files named things like `2013-city.csv`.

### Summaries

````
make summary
````

This command will download DOF's annual neighborhood summary data (beginning in 2007) to the `summary` folder.

### Rolling Sales

The most recent sales data is in DOF's rolling data files. These files generally have sales for a year, up to two-three months ago.

Download the most recent rolling data to `rolling/raw/city.csv`:
````
make rolling
````

Download a specific month:
````
make rolling/2014-11-city.csv
````

## MySQL

The conversion to MySQL tries to split out the apartment number part of the address field, but doesn't do any other processing beside formatting prices and dates.

Load sales data into a MySQL database:

````
$ make mysql USER=username PASS=password
````

You can leave off the password, you'll be prompted several times to enter it. If your account doesn't have a password, I judge your security practices, but you can run: `make mysql USER=username PASSFLAG=`.

This will try to connect to `localhost` and create a database named `nycre`. You can customize the database name like so:

````
$ make mysql DATABASE=mydatabase
````

Tables named `sales`, `borough`, `building_class_category`, `building_class` and `tax_class` will be created.