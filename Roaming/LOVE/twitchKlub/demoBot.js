const tmi = require('tmi.js');
const fs = require('fs');
const readline = require('readline');



var creds = []
loadCredentials();

// Define configuration options
const opts = {
  identity: {
    username: creds[0],
    password: creds[1]
  },
channels: [`${creds[2]}`]
};

var database = []

// Create a client with our options
const client = new tmi.client(opts);

// Register our event handlers (defined below)
client.on('message', onMessageHandler);
client.on('connected', onConnectedHandler);

// Connect to Twitch:
client.connect();

//Setup an output stream
var stream = fs.createWriteStream("Output.txt", {flags:'a'});

// Called every time a message comes in
function onMessageHandler (target, context, msg, self) {
  if (self) { return; } // Ignore messages from the bot
  
  //check the database file
  processLineByLine();
  
  let data = `${context.username},${msg}`;
   
  stream.write(data + "\n");
  
  // Remove whitespace from chat message
  const commandName = msg.trim();

  // If the command is known, let's execute it
  if (commandName === '!balance') {
	var num = 0;
	for (let i = 0; i< database.length; i++) {
		if (database[i][0] == context.username) {
			num = database[i][1]
		}
	}
	
	client.say(target, `Your balance is ${num}`);
	console.log(`* Executed ${commandName} command`);
  } else {
	console.log(`* Unknown command ${commandName}`);
  }
}
  
// Called every time the bot connects to Twitch chat
function onConnectedHandler (addr, port) {
	console.log(`* Connected to ${addr}:${port}`);
  
	fs.writeFile('Output.txt', "", (err) => { 
		if (err) throw err; 
	}) 
	
	
}

async function processLineByLine() {
  const fileStream = fs.createReadStream('database.save');

  const rl = readline.createInterface({
    input: fileStream,
    crlfDelay: Infinity
  });
  // Note: we use the crlfDelay option to recognize all instances of CR LF
  // ('\r\n') in input.txt as a single line break.

  for await (const line of rl) {
    // Each line in input.txt will be successively available here as `line`.
    var lineTab = []
	lineTab = line.split(",")
	database.push(lineTab)
  }
  //console.log(`* Line tab: ${database[0][0]}`);
}

async function loadCredentials() {
	fs.readFile('credentials.txt', (err, data) => {
		if (err) {
			console.error(err)
			return
		}
		var tab = [];
		var dataString = data.toString();
		tab = dataString.split(",")
		creds = tab
	})
}