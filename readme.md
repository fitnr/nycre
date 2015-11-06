nycre
=====

Download and pre-process New York City real estate transaction data, which is online in Excel files. This project downloads the data and tranforms it into usable csv files, and optionally loads it into a MySQL, PostgreSQL or SQLite database.

The NYC Department of Finance maintains two real estate data sets:
* [Rolling Sales](http://www.nyc.gov/html/dof/html/property/rolling_sales_data.shtml): All sales for the last twelve months (usually running with a 2-3 month delay)
* [Annualized Sales](http://www.nyc.gov/html/dof/html/property/rolling_sales_data_annualized.shtml): Files with sales records for each year.
* [Summary Data](http://www.nyc.gov/html/dof/html/property/rolling_sales_data_annualized.shtml): Year-by-year summaries of average prices by neighborhood

You might be interested in a related project, [avroll-download](https://github.com/fitnr/avroll-download), for downloading the City's assessed value database.

## Requirements
* [NPM](http://nodejs.org/download/) packages: [J](http://npmjs.com/package/j) and [sheetstack](https://www.npmjs.com/package/sheetstack)

## Installing
```
git clone git@github.com:fitnr/nycre.git
cd nycre
make install
```

This will work if you have [node and NPM installed](https://nodejs.org/en/download/).

## Downloading data

The download tasks convert DOF's excel files to CSV, but don't do any cleaning or other processing.

### Sales

To download all the annual sales data, download or clone the repository and run:
````
make
````

This will create a `sales` folder with files named things like `2013-city.csv`.

### Rolling Sales

The most recent sales data is in DOF's rolling data files. These files generally have sales for a year long period, up to two-to-three months ago.

Download the most recent rolling data to `rolling/raw/city.csv`:
````
make rolling
````

Download a specific month:
````
make rolling/2014-11-city.csv
````

To load this "rolling" data into your database, use a command in this format:
````
make rolling-database-YYYY-MM
````
e.g:
````
make rolling-mysql-2015-01
make rolling-sqlite-2015-02
make rolling-postgresql-2015-03
````

If you run the command on a period not currently covered by the rolling data you've downloaded, you'll get an empty result. So if you plan on running this regularly, you'll need to remove the downloaded "raw" data and download current data:
````
rm -r rolling/raw
make rolling
````
### Summaries

````
make summary
````

This command will download DOF's annual neighborhood summary data (beginning in 2007) to the `summary` folder.

## Limiting by year

To limit the download to only certain years, use the YEARS variable:
````
make YEARS="2010 2011 2012 2013 2014"
````

In this example, only transaction data from 2010-14 will be downloaded.

## Databases

Short version: run one of these commands to download the sales data and load it into a local database:

````
make mysql USER=me PASS=pass
make postgresql USER=me
make sqlite
````

Tables named `sales`, `borough`, `building_class_category`, `building_class` and `tax_class` will be created.

### MySQL

The conversion to MySQL tries to split out the apartment number part of the address field, but doesn't do any other processing beside formatting prices and dates.

Load sales data into a MySQL database:

````
make mysql USER=username PASS=password
````
This will try to connect to `localhost` and create a database named `nycre`. You can customize the database name and add any other mysql flags you might need like so:
````
make mysql DATABASE=mydatabase MYSQLFLAGS="-H myhost.com -P 5432"
````

You can leave off the password, you'll be prompted several times to enter it. If your account doesn't have a password, I judge your security practices, but you can run: `make mysql USER=username PASSFLAG=`.

### PostgreSQL

Tested with PostgreSQL v9.4, will likely work on lower versions.

Run:
````
make postgresql USER=myusername
````

This assumes that you don't require a password for access. If you do require a password, add the -W flag. You will be prompted to enter the password approximately 60 times (consider temporarily disabling the password requirement).
````
make postgresql USER=myusername PSQLFLAGS=-W
````

The data will be loaded into a new database named `nycre`. Customize this and add any additional flags like so: 
````
make postgresql DATABASE=mydatabase PSQLFLAGS="-h myhost.com -p 5432"
````

### SQLite

Requires SQLite v3.7.15 or higher.

The command `make sqlite` downloads all available sales data (2003-) and loads it into an SQLite file named `nycre.db`.

Due to the limitations of SQLite, addresses and apartment numbers are not as well parsed as in the MySQL commands.

## Bouncing back from errors

If there's a problem of some kind and your database is damaged, you might want to start over. Run one of these to completely delete the database:

````
make mysqlclean
make postgresqlclean
rm nycre.db # for sqlite
````
