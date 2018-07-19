# What this script does

This is a simple ruby script, capable of pulling all your articles
from your Amazon orders to csv. It will respect cancellations and
prints out shipping charges seperately. It does have an accuracy
nearly to 100 percent depending on your shopping behavior.
(See limitations below)

It is written to work on the German amazon.de site only. It should be
easily adaptable to other amazon sites, even if you don't have much
ruby knowledge. However - some experience with css selectors would
be fine.

# Where it does

It should run on all platforms. Due to the lack of other platforms,
I developed, tested (and described the installation) on Ubuntu only.

Also Firefox as engine is hardcoded at the moment.

# What it does not (yet)

- apps are not listed by name, but gets falsely included as shipment costs
- the prices for 'flash offers' are always zero (however - they get tagged, so the price can be corrected afterwards)
- german umlauts does not decode properly at older years. This seems to
  be an Amazon bug, as they don't show properly at the normal site also
- shipment fees will not show up as refunded if the order gets cancelled
- shipment fees from orders payed with a voucher card do not show up at all

# Installation

Be sure to have Firefox installed. Get the repo or download this files to some dir. Get some ruby > 2. For example:

`apt-install ruby2.3 ruby-dev`

Install ruby's selenium package:

`gem install selenium-webdriver`

Goto [https://github.com/mozilla/geckodriver/releases](https://github.com/mozilla/geckodriver/releases), get your fitting 'geckodriver' bin and extract it to the script dir. Make sure it is executable:

`chmod a+x geckodriver`

# Start

`./pull-orders.sh`

This will pull all years upto 2000. In older data there is no article
information anymore.

`./pull-orders.sh year`

If the script crashes - or for other reasons - you might want to get a single
year. The 'year' should have 4 digits, like '2018'

The script will ask you to log in to Amazon and open the 'orders' page,
then press the ANY key once to start. You should check the 'remember me'
button (in German 'angemeldet bleiben') while login if you want to pull
several years.

Your csv data will be stored in files like 'amazon-orders-2018.csv'.The script
will save your login credentials for further use.

# Troubleshooting

If you or Amazon messes with the login, simply delete the cookies.yml file
and the script will ask you to log in again.

# Disclaimer

I wrote this for personal use only, so don't bother me if it has ugly
code or bugs. However - I wrote some comments into the code if someone
likes to add some features.

Nevertheless you are welcome to report bugs (so I can mash them or add
them to this readme... ;)
