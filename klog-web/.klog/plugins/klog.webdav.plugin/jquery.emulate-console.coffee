$ ->

	window.console = {}
	console.logdiv = $ "#log"
	console.logdiv.css
		background: "black"
		color: "white"
		padding: 5
		
	console.log = (message)->
		try
		  if (typeof message).match /object|array/i
			  message = JSON.stringify(message).replace /,\s*"/g, ',\n"' # '
		catch e
			console.log e
		console.logdiv.html console.logdiv.html() + "\n" + message
		
