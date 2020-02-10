function love.load()
	love.window.setTitle("TwitchKlub")
	love.window.setMode(1280, 720, {resizable=false, vsync=false, minwidth=400, minheight=300})
	love.graphics.setBackgroundColor( 0, 0, 0, 1 )
	screenWidth = love.graphics.getWidth()
	screenHeight = love.graphics.getHeight()
	
	--Global Variables
	tick = 0
	pointTick = 0
	
	
	--Inbox for new chat messages
	inbox = {}
	
	--Outbox for outgoing messages
	outbox = {}
	
	database = {}
	
	
	--name, balance, rank, timeWatched, hat
	if love.filesystem.getInfo("database.save") then
		for line in love.filesystem.lines("database.save") do
			local pos = string.find(line,",")
			local usr = string.sub(tostring(line),1,pos-1)
			local left = string.sub(tostring(line),pos+1)
			pos = string.find(tostring(left),",")
			local bal = string.sub(tostring(left),1,pos-1)
			left = string.sub(tostring(left),pos+1)
			pos = string.find(tostring(left),",")
			local rank = string.sub(tostring(left),1,pos-1)
			left = string.sub(tostring(left),pos+1)
			pos = string.find(tostring(left),",")
			local timeWatched = string.sub(tostring(left),1,pos-1)
			local hat = string.sub(tostring(left),pos+1)
			database[#database+1] = {usr,tonumber(bal),tonumber(rank),tonumber(timeWatched),tonumber(hat)}
		end
		local success,message = love.filesystem.write("database.save","")
	end
	
	activeUsers = {}
end

function love.update(dt)
	if tick >= 100 then
		tick = tick - 100
		getChat()
		processInbox()
		sendChat()
		saveDatabase()
	end
	if pointTick >= 1000 then
		pointTick = pointTick - 1000
		activePoints(1)
	end
	pointTick = pointTick + 1
	tick = tick + 1
end

function love.draw()
	if #outbox > 0 then
		for i = 1,#outbox do
			love.graphics.print("Kanium: " ..firstToUpper(outbox[i][1])  .." " ..outbox[i][2],300,20*i)
		end
	end
end

function love.quit()
	saveDatabase()
end

function getChat()
	if love.filesystem.getInfo("Output.txt") then
		for line in love.filesystem.lines("Output.txt") do
			local pos = string.find(tostring(line),",")
			local username = string.sub(tostring(line),1,pos-1)
			local message = string.sub(tostring(line),pos+1)
			local chatline = {username,message}
			table.insert(inbox,{username,message})
		end
		local success,message = love.filesystem.write("Output.txt","")
	end
end

function processInbox()
	if #inbox > 0 then
		if #database > 0 then
			local found = 0
			for i = 1,#inbox do
				local tab = {inbox[i][1],inbox[i][2]}
				table.insert(outbox,tab)
				for j = 1,#database do
					if inbox[i][1] == database[j][1] then
						found = 1
						addActive(j)
						checkCommands(i,j)
					end
				end
				--if this name isn't in the database, add it.
				if found == 0 then
					newUser(inbox[i][1])
				end
			end
			inbox = {}
		else
			newUser(inbox[1][1])
		end
	end
end

function addActive(accountNumber)
	local found = 0
	if #activeUsers > 0 then
		for i = 1, #activeUsers do
			if database[activeUsers[i]][1] == database[accountNumber][1] then
				found = 1
			end
		end
	end
	if found == 0 then
		table.insert(activeUsers,accountNumber)
	end
end

function activePoints(pts)
	if #activeUsers > 0 then
		for i = 1,#activeUsers do
			database[activeUsers[i]][2] = database[activeUsers[i]][2] + pts
			database[activeUsers[i]][4] = database[activeUsers[i]][4] + 1
		end
	end
end

function checkCommands(inboxNum,dbNum)
	local msg = inbox[inboxNum][2]
	if string.find(msg,"!balance") then
		local tab = {inbox[inboxNum][1],"Your balance is " ..database[dbNum][2]}
		table.insert(outbox,tab)
	end
end

function newUser(username)
	--name, balance, rank, timeWatched, hat
	local user = {username,1000,1,0,0}
	database[#database+1] = user
	local tab = {username,"Welcome to the Server!"}
	table.insert(outbox,tab)
end

function saveDatabase()
	local success,msg = love.filesystem.write("database.save","")
	if #database > 0 then
		for i = 1,#database do
			local file = ""
			for j = 1,#database[i] do
				if j < #database[i] then
					file = file ..database[i][j] ..","
				else
					if i == #database then
						file = file ..database[i][j]
					else
						file = file ..database[i][j] .."\n"
					end
				end
			end
			local success,msg = love.filesystem.append("database.save",file)
		end
	end
end

function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

function sendChat()
	if #outbox > 0 then
		for i = 1, #outbox do
			local success,msg = love.filesystem.write("Outbox.txt",outbox[i][1] .."," ..outbox[i][2])
		end
	end
end