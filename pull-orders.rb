require 'selenium-webdriver'
require 'io/console'
require 'ap'
require 'yaml'

# css selectors to parse the file
Flash_sale_selector = 'Blitzangebote'
returned_selector = /Rücksendung|Erstattet|Erstattung/
order_selector = { css: '#ordersContainer .a-box-group.order' }
order_date_selector = { css: '.order-info .a-box-inner .a-fixed-right-grid .a-fixed-right-grid-inner .a-fixed-right-grid-col.a-col-left .a-row .a-column.a-span4 .a-row.a-size-base' }
order_price_selector = { css: '.order-info .a-box-inner .a-fixed-right-grid .a-fixed-right-grid-inner .a-fixed-right-grid-col.a-col-left .a-row .a-column.a-span2 .a-row.a-size-base' }
order_shipments_selector = { css: '.a-box.shipment' }
shipment_status_selector = { css: '.a-box-inner .a-row.shipment-top-row.js-shipment-info-container' }
shipment_articles_selector = { css: '.a-box-inner .a-fixed-right-grid.a-spacing-top-medium .a-fixed-right-grid-inner.a-grid-vertical-align.a-grid-top .a-fixed-right-grid-col.a-col-left .a-row .a-fixed-left-grid .a-fixed-left-grid-inner' }
article_name_selector = { css: '.a-fixed-left-grid-col.a-col-right div:nth-of-type(1).a-row' }
article_price_selector = { css: '.a-fixed-left-grid-col.a-col-right div.a-row .a-size-small.a-color-price' }

# working with cents internally
def cur_to_int(value)
  return 0 if value == Flash_sale_selector
  value.split(' ')[1].to_s.gsub(',','').to_i
end

def int_to_cur(int)
  (int.to_f / 100).round(2).to_s.gsub('.', ',') # change this to fit your own locale
end

# get single year argument
years = Array ARGV[0] if ARGV[0]

# initialize driver for Firefox
driver = Selenium::WebDriver.for :firefox
driver.navigate.to 'https://amazon.de'

# load cookies from last session or wait for login
if File.exist? 'cookies.yml'
  puts 'Loading previous login cookies...'
  driver.manage.delete_all_cookies
  YAML::load(File.read('cookies.yml')).each { |cookie| driver.manage.add_cookie(cookie) }
  driver.navigate.refresh
else
  puts 'Please wait for Firefox to show up with the Amazon page, log in, click on "orders", (maybe) log in again and press the ANY key (in this console window) if you see some orders.'
  STDIN.getch

  # saving cookies to file, so you don't have to log in for every year
  File.write('cookies.yml', driver.manage.all_cookies.to_yaml)
end

total_sum = 0

# initialize csv file
csv_file = File.open("amazon-orders.csv", 'w')
csv_file.write("\"Date\";\"Shipment Status\";\"Article Count\";\"Article Name\";\"Single Price\";\"Total Price\";\"Tags\"\n")

#iterate through years
years = (Time.now.year).downto(2000).to_a unless years
years.each do |year|
  year = year.to_s
  puts 'STARTING ' + year

  article_offset = 0
  order_count = 0

  # iterate through pages, break after last page
  while article_offset == 0 || order_count == 10 do

    order_count = 0
    driver.navigate.to "https://www.amazon.de/gp/your-account/order-history?orderFilter=year-#{year}&startIndex=#{article_offset}"

    # iterate through orders
    driver.find_elements(order_selector).each do |order_element|
      order_count += 1
      order_article_prices_total = 0
      order_total_payed_after_returns = 0
      puts
      order_date = order_element.find_element(order_date_selector).text rescue 'order_date_selector error'
      print order_date + ', '
      order_price = cur_to_int(order_element.find_element(order_price_selector).text) rescue 0
      puts int_to_cur(order_price)

      # iterate through shipments
      order_element.find_elements(order_shipments_selector).each do |shipment_element|
        shipment_status = shipment_element.find_element(shipment_status_selector).text.split("\n").first rescue ''
        if shipment_status.match returned_selector
          puts "  " + shipment_status
          shipment_is_return = true
        else
          puts "  " + (shipment_status == '' ? 'no shipment status shown' : shipment_status)
        end

        # iterate through articles
        shipment_element.find_elements(shipment_articles_selector).each do |article_element|

          article_name = article_element.find_element(article_name_selector).text[0..50].gsub(';', ',') rescue 'article_name_selector error'
          puts '    ' + article_name.to_s

          # get and delete acticle count from article_name
          article_count_match = article_name.match(/^(\d+) von /)
          article_name = article_name.gsub(/^(\d+ von )/, '')

          # set article count
          article_count = 1
          article_count = article_count_match[1].to_i if article_count_match

          # get article prices
          article_price_text = article_element.find_element(article_price_selector).text
          article_single_price = cur_to_int(article_price_text)
          article_price = cur_to_int(article_price_text) * article_count

          # tag flash sale
          flash_sale = true if article_price_text == Flash_sale_selector

          # sum up articles in order
          order_article_prices_total = order_article_prices_total + article_price
          puts '    (' + article_count.to_s + ') ' + int_to_cur(article_price)

          # sum up order's articles without returns (to calculate shipment later)
          order_total_payed_after_returns += article_price unless shipment_is_return

          # write to csv
          csv_file.write( order_date + ';' +
                          shipment_status.to_s + ';' +
                          article_count.to_s + ';' +
                          article_name.to_s + ';' +
                          int_to_cur(article_single_price) + ';' +
                          int_to_cur((shipment_is_return || flash_sale) ? 0 : article_price) + ';' +
                          (flash_sale ? Flash_sale_selector : '') +
                          "\n"
                        )
        end
      end

      # calculate shipment
      puts 'order total payed after returns: ' + int_to_cur(order_total_payed_after_returns)
      order_shipment_costs = order_price - order_article_prices_total

      # it can happen that shipment cost get negative as voucher payments will not show up in amazon's order sum
      order_shipment_costs = 0 if order_shipment_costs < 0

      puts 'order total shipment costs: ' + int_to_cur(order_shipment_costs)

      # write calculated shipment fee to csv
      csv_file.write( order_date + ';' +
                      ';' +
                      '1;' +
                      'shipment;' +
                      int_to_cur(order_shipment_costs) + ';' +
                      int_to_cur(order_shipment_costs) + ';' +
                      '' +
                      "\n"
                    ) if order_shipment_costs > 0

      # calculate total sum for all orders
      total_sum += order_total_payed_after_returns
      total_sum += order_shipment_costs
    end

    # next page
    article_offset += 10
  end
  puts "\nTOTAL SUM NOW: " + int_to_cur(total_sum)
end

# close Firefox
driver.quit

csv_file.close
