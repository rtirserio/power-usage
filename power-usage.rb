require 'mechanize'

@mechanize = Mechanize.new

#Login
def login(username, password)
	login_page = @mechanize.get('https://www.dom.com/residential/dominion-virginia-power/sign-in')
	login_form = login_page.forms.first
	login_form['user'] = username
	login_form['password'] = password#
	query = {}
	login_form.fields.each {|field|
		query[field.name] = field.value
	}
	# They are using JS to do some stuff, so send a post directly to what they will (eventually) send the post to
	return @mechanize.post("https://mydom.dom.com/siteminderagent/forms/login.fcc", query)

end

# Gets the usage
def usage()
	usage_page_billing = @mechanize.get('https://mya.dom.com/Usage/ViewPastUsage')
	# There isnt a thead so get the 'second' row which is the first row of data
	billing_row = usage_page_billing.at('#billingAndPaymentsTable').at('tr[2]')
	bill_amount = billing_row.at('td[2]').text.strip
	bill_due_date = billing_row.at('td[3]').text.strip

	# Now change the view to the other data we need
	usage_page_usage = usage_page_billing.form_with(:id => 'frmStatementSearch') do |form|
		form.field_with(:id => 'ddlStatementTypeDropdownList').value = 4
	end.submit

	payment_row = usage_page_usage.at('#paymentsTable').at('tr[2]')
	end_date = payment_row.at('td[1]').text.strip
	start_date = Date.strptime(end_date, "%m/%d/%Y") - payment_row.at('td[2]').text.strip.to_i + 1
	kwh_usage = payment_row.at('td[5]').text.strip

	puts "Between #{start_date.strftime("%m/%d/%Y")} and #{end_date}, you have used #{kwh_usage}kWh."
	puts "You are required to pay the amount #{bill_amount} by #{bill_due_date}."
end

puts "Username"
user = STDIN.gets.strip

puts "Password"
pwd = STDIN.gets.strip

dashboard = login(user, pwd)
# if this is missing, the login failed
if dashboard.at('.currentUserPadding').nil?
	puts 'You credentials were invalid.'
	exit
end

usage()
