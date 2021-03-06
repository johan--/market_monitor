module CharMarketOrders
	def self.update_char_orders(api_id)
		#Assemble a hash for use in updating existing orders.
		@updatehash = {"vol_remaining" => nil, "order_state" => nil, "escrow" => nil, "price" => nil}

		#Extract the active status from the database.
		@active = Api.find_by_id(api_id).active

		#Check for activity to ensure dead APIs aren't hammered.
		if @active == 1

			#Assemble the API for the EVE Gem.
			api = Eve::API.new(:key_id => Api.find_by_id(api_id).key_id, :v_code => Api.find_by_id(api_id).v_code)

			#Load Characters to retrieve character IDs
			result = api.account.characters

			#select the user from the API assocation
			#@user = User.find_by_id(Api.find_by_id(id).user_id)
				
			#Build and make the API Call
			#Iterate through each character accessible on the API
			result.characters.each do |c|

				#Build and make the API Call
				api.set( :character_id => result.characters[c].character_id)
				result = api.character.market_orders

				#Iterate through each returnd order.
				result.orders.each do |o|

					#load the hash with the variables that change from query to query.
					@updatehash["vol_remaining"] = o.volRemaining
					@updatehash["order_state"] = o.orderState
					@updatehash["escrow"] = o.escrow
					@updatehash["price"] = o.price

					#Update the existing order.
					MarketOrder.find_by_order_id(o.orderID).update_attributes(@updatehash)
				end
			end
		end
		puts "Finished CharMarketOrders.update at #{DateTime.now}"
	end

	def self.input_char_orders(api_id, cache_time_id)
		#Assemble a hash for use in inserting into the database.
		@temphash = {"user_id" => nil, "api_id" => nil, "market_item_summary_id" => nil, "order_id" => nil, "char_id" => nil, "station_id" => nil, "vol_entered" => nil, "vol_remaining" => nil, "min_volume" => nil, "order_state" => nil, "type_id" => nil, "reach" => nil, "account_key" => nil, "duration" => nil, "escrow" => nil, "price" => nil, "bid" => nil, "issued" => nil }
		#puts "Built Temphash"
		#Extract the active status from the database.
		@active = Api.find_by_id(api_id).active

		#Check for activity to ensure dead APIs aren't hammered.
		if @active == 1
			#puts "API found to be active"
			#Assemble the API for the EVE Gem.
			api = Eve::API.new(:key_id => Api.find_by_id(api_id).key_id, :v_code => Api.find_by_id(api_id).v_code)

			#Load Characters to retrieve character IDs
			result = api.account.characters

			#select the user from the API assocation
			@user = User.find_by_id(Api.find_by_id(api_id).user_id)
				
			# Build and make the API Call
			#Iterate through each character accessible on the API
			result.characters.each do |c|

				#Build and make the API Call
				api.set(:character_id => c.character_id)
				charidresult = api.character.market_orders

				#Set the api_id variable before looping since it is static.
				@temphash["api_id"] = api_id

				#Iterate through each returnd order.
				charidresult.orders.each do |o|

					#Check for existing order, if found, update it with new data.
					#add an index to MarketOrder order_id to optimize this.
					if MarketOrder.find_by_order_id(o.orderID) != nil
						update_char_orders(id)
					else
						#Load each order attribute into a hash for easy database insertion.
						@temphash["order_id"] = o.orderID
						@temphash["char_id"] = o.charID
						@temphash["station_id"] = o.stationID
						@temphash["vol_entered"] = o.volEntered
						@temphash["vol_remaining"] = o.volRemaining
						@temphash["min_volume"] = o.minVolume
						@temphash["order_state"] = o.orderState
						@temphash["type_id"] = o.typeID
						@temphash["reach"] = o.range
						@temphash["account_key"] = o.accountKey
						@temphash["duration"] = o.duration
						@temphash["escrow"] = o.escrow
						@temphash["price"] = o.price
						@temphash["bid"] = o.bid
						@temphash["issued"] = o.issued

						#Insert into the database
						@order = @user.market_orders.build(@temphash)
						@order.save
					end
				end
			end

			#Create and save a new CacheTimes model based on the cachedUntil datetime 
			#returned by the API pulled in this invocation. This is executed regardless
			#of whether a new order is created or an existing order is updated.
			@newTimer = CacheTimes.new(user_id: @user.id, api_id: api_id, call_type: 4, cached_time: result.cachedUntil)
			@newTimer.save
		end

		#Delete the CacheTimes model that caused this method to be invoked.
		#This is called outside of the API's active check, so the first time an
		#API is called after being inactive, it is deleted.
		#CacheTimes.delete(cache_time_id)
		puts "Finished executing CharMarketOrders.input_orders at #{DateTime.now}"
	end
end
