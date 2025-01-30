## -----------------------------------------------------------------------
##           AutoTalk.TCL ver 1.0 Disign by: (-=�razyFire=-)                               
## -----------------------------------------------------------------------
## FOR MORE INFORMATION VISIT OUR CHANNEL (bot home #Djebel) 
## my email : crazy@link.bg
## AutoTalk.TCL V1.0
## by: (-=�razyFire=-)
## 
## All newsheadlines parsed by this script are (C) AutoTalk`eggdrop`team 
## 
## AutoTalk Version History:1 Command    V1.0  - Public command like (botnick) (command) 
##                        2 protection   v1.0  - This script i just made medium protection
##                                              if some one flood color or say bad word or what on channel
##                                              the bot will lock channel for a moment (mode +mi).
##                                              ( i have been tried it on Channel #Djebel)                                       
##                        3 entertainment v1.0 - Auto speak and respon :).
##                                        v1.1 - Auto speak when some one change they nickname
##                                        v1.2 - Auto speak when some get kick or join channel.          
## The author takes no responsibility whatsoever for the usage and working of this script !
## 

## ----------------------------------------------------------------
## Set global variables and specificic
## ----------------------------------------------------------------

## =[ SPEAK ]= Set the next line as the channels you want to run in
## for all channel just type "*" if only for 1 channel or 2 chnnel just
## type "#channel1 #channel2"
set speaks_chans "*"

# Set you want in XXX minute you bot always talk on minute 
set speaks_time 60

## =[ Hello ]= Set the next line as the channels you want to run in
## for all channel just type "*" if only for 1 channel or 2 chnnel just
## type "*"
set hello_chans "*"

## =[ BRB ]= Set the next line as the channels you want to run in
## for all channel just type "*" if only for 1 channel or 2 chnnel just
## type "*"
set brb_chans "*"

## =[ BYE ]= Set the next line as the channels you want to run in
## for all channel just type "*" if only for 1 channel or 2 chnnel just
## type "*"
set bye_chans "*"

## =[ PING ]= Set the next line as the channels you want to run in
## for all channel just type "*" if only for 1 channel or 2 chnnel just
## type "*"
set ping_chans "*"


## ----------------------------------------------------------------
## --- Don't change anything below here if you don't know how ! ---
## ----------------------------------------------------------------

######################################################################
##--------------------------------------------------------------------
##--- F O R     ---   E N T E R T A I N M E N T  ---    CHANNEL   ----
##--------------------------------------------------------------------
######################################################################         
### SPEAK ###
set spoken.v "Auto talk"
# Set the next lines as the random speaks msgs you want to say
set speaks_msg {
		{"Why didn't the chef season the chicken? He didn't have enough thyme."}
		{"Did you hear about the girl who got fired from the calendar factory? She took a day off."}
		{"Why don't physicists trust atoms? Because they make up everything."}
		{"What's the best way to catch a fish? Ask someone to throw it to you."}
		{"When is a door not a door? When it's ajar."}
		{"I couldn't figure out why the baseball kept getting larger and larger. Then it hit me."}
		{"What do computers eat for lunch? Microchips."}
		{"What's the hottest part of any room? The corner, because it's always 90 degrees."}
		{"How many dance instructors does it take to change a lightbulb? Five ... six ... seven ... eight!"}
		{"Why does a chicken coop only have two doors? If it had four it would be a sedan."}
		{"Why do sweaters stick together? Because they're close-knit."}
		{"Did you hear about the octopus that held up a convenience store? It was an armed-robbery."}
		{"Two fish are in a tank. One turns to the other and says, "Any idea how to drive this thing?""}
		{"Why do ducks have tails? To hide their butt-quacks."}
		{"Did you about the stolen dog collar? Police are looking for leads."}
		{"I'm wasn't a fan of facial hair, but eventually it grew on me."}
		{"Have you ever played quiet tennis? It's the same as regular tennis, but without the racket."}
		{"What did the mummy say after getting detention? "This sphinx!""}
		{"I used to be addicted to the Hokey Pokey, but then I turned myself around."}
		{"Two guys walked into a bar. The third one ducked."}
		{"Did you hear about the guy giving away dead batteries? They were free of charge."}
		{"What do lawyers wear under their pants? Briefs."}
		{"Did you hear about the equestrian that got laryngitis? Now she's a hoarse whisperer."}
		{"Why did the invisible man quit his job? He couldn't see himself doing it."}
		{"There are three kinds of people in the world. Those who can do math and those who can't."}
		{"Why did the author get married? She found Mr. Write."}
		{"Why don't skeletons skydive? They don't have the guts to do it."}
		{"Where do cucumbers go on date night? The salad bar."}
		{"Did you hear about the pine tree that got a timeout? It was being knotty."}
		{"What do you say to a cow that gets in your way? "Moooo-ve!""}
		{"I met a giant once. I didn't know what to say, so I just used big words."}
		{"Did you hear about the dolphin romance? They really clicked."}
		{"A horse walks into a diner. The host says, "Hey!" The horse says, "You read my mind!""}
		{"How did people see in the dark during medieval times? They used knight lights."}
		{"Why aren't there a lot of jokes about peaches? Because most of them are pit-iful."}
		{"What's the best way to catch a squirrel? Act like a nut."}
		{"Did you hear about math book that got a therapist? It had a lot of problems."}
		{"What's worse than raining cats and dogs? Hailing taxis."}
		{"What do you call a cow with only two legs? Lean beef."}
		{"Why shouldn't you play poker in the jungle? Too many cheetahs."}
		{"Did you hear about the cat that aced the test? It got a purr-fect score."}
		{"Why is the ocean so clean? It has mer-maids."}
		{"Why did the king go to the dentist? He needed a crown."}
		{"Did you hear about the archeologist who got fired? His career was in ruins."}
		{"I'd tell you a construction joke, but I'm still working on it."}
		{"Why don't lions eat clowns? Because they taste funny."}
		{"Where do boats go when they're sick? To the dock-tor."}
		{"Did you hear about the ghost that joined a soccer team? It wanted to be a ghoulie."}
		{"Why did the potato leave the bar? All eyes were on him."}
		{"What do you get when you cross a guitar, drums and a car tire? A rubber band."}
		{"Why did the golfer bring two pairs of pants to the course? In case he got a hole in one."}
		{"Why did the boy wear his coat to dinner? Because chili was on the menu."}
		{"Did you hear about the baseball player who got arrested? He stole second base."}
		{"Why aren't kids allowed to see pirate movies? They're all rated arrrrr."}
		{"How much does it cost to hire a deer? A buck."}
		{"How did police catch the thief who robbed an Apple store? There was an iWitness."}
		{"Why did the coffee cup file a police report? It got mugged."}
		{"Did you hear about the kidnapping at school? Thankfully, someone woke her up."}
		{"What kind of scientists avoid the sun? Paleontologists."}
		{"Why did the financial planner quit his job? He was losing interest."}
		{"Did you hear about the guy who decided to hang mirrors for a living? It's something he could see himself doing."}
		{"Why do frogs like playing baseball? They're good at catching fly balls."}
		{"How did Noah sail his ark at night? Using floodlights."}
		{"How do lumberjacks know how many trees they've cut down? They keep a log."}
		{"Why are sports stadiums so chilly? Too many fans."}
		{"Where do cows get their clothes? From cattle-logs."}
		{"What kind of socks should you buy a bear? None. They prefer to go barefoot."}
		{"How do honeybees get to school? On the buzz."}
		{"Why did Darth Vader go to the dermatologist? He had Star Warts."}
		{"Did you hear about the light that got arrested? It went to prism."}
		{"Why did the beach get embarrassed? Because it noticed the sea weed."}
		{"I'm obsessed with telling airport jokes. My doctor says it's a terminal problem."}
		{"I was going to tell you a joke about sodium, but then I thought, "Na.""}
		{"What's a pirate's favorite subject in school? Arrrr-t."}
		{"Did you hear about the killer whale that learned to play the flute? He wanted to be in the orca-stra."}
		{"What do you call a crocodile that's always causing trouble? An insta-gator."}
		{"I think I'm addicted to cheese. Don't worry, it's only mild."}
		{"What kind of shoes do breadsticks wear? Loafers."}
		{"Why shouldn't you trust trees? They can be a little shady."}
		{"Why didn't the skeleton go skydiving? He didn't have the guts."}
		{"If you find out when fishing season begins, let minnow!"}
		{"What's the best way to make an octopus laugh? With ten-tickles."}
		{"Why did the frog take the bus to work? His car got toad."}
		{"Why did the man name his puppy "Timex"? He wanted a watchdog."}
		{"Why did the pony eat a cough drop? It was a little horse."}
		{"What do mermaids wear under their shirts? Algae-bras."}
		{"What did the salmon say after hitting a wall? "Dam!""}
		{"How do you stop a bull from charging? Take away his credit card."}
		{" Did you hear about the gardener who was excited for spring? She wet her plants."}
		{"What gift did the dentist get upon retiring? A little plaque."}
		{"Why are barbers always on time? They know a lot of shortcuts."}
		{"What do bananas wear around the house? Slippers."}
		{"Why did the spoon quit his job? He was going stir-crazy."}
		{"I told a bad chemistry joke once. It didn't get much of a reaction."}
		{"What did the pirate say at his 80th birthday party? Aye, Matey!"}
		{"How do trees get on the Internet They log in."}
		{"What do computers like to eat Chips."}
		{"What do you call a space magician A flying saucerer."}
		{"What is a computer's first sign of old age Loss of memory."}
		{"What does a baby computer call his father Instead of Da-da it says Da-ta."}
		{"What is an astronaut's favorite control on the computer keyboard The space bar."}
		{"What happened when the computer fell on the floor It slipped a disk."}
		{"How does a boy cell phone propose to his girlfriend He gives her a ring, of course."}
		{"Why was there a bug in the computer It was looking for a byte to eat."}
		{"What is a computer virus A terminal illness."}
		{"How did the mouse get out of the Roman Cathedral He clicked on an icon and opened a window."}
		{"What kind of doctor fixes broken websites A URLologist."}
		{"Have you heard about the Disney virus It makes everything on your computer go Goofy."}
		{"What happened when a dragon breathed on several Macintosh computers He wound up with baked Apples!"}
		{"Why did the chicken cross the Web To get to the other site."}
		{"Why did the computer go to a doctor It thought it had a terminal illness."}
		{"How do you know if a vampire is unwell? Because he'll be coffin."}
		{"Where do pirates get their hooks? Second hand shops."}
		{"Why did the bicycle collapse? It was too tyred."}
		{"What kind of music do bubbles hate? Pop."}
		{"Why did the hairdresser win the race? He knew a shortcut."}
		{"How did the picture end up in prison? It was framed."}
		{"What do solicitors wear to work? Lawsuits."}
		{"Why did the bullet lose its job? It got fired."}
		{"Why can't a toe be 12 inches long? Then it'd be a foot."}
		{"Want to hear a joke about a roof? The first one's on the house."}
		{"What does a house wear? Address!."}
		{"What did one wall say to the other? I'll meet you at the corner."}
		{"Why is grass so dangerous? It's full of blades."}
		{"What's orange and sounds like a carrot? A parrot."}
		{"Why do French people eat snails? They don't like fast food."}
		{"Where do hamburgers and hot dogs go dancing? A meatball."}
		{"How do trees get online? They just log on!"}
		{"How do billboards talk? Sign language."}
		{"What's America's favourite soda? Mini soda."}
		{"Why shouldn't you trust atoms? Because they make up everything."}
		{"How was Rome split in two? With a pair of Caesars."}
		{"Why can't you give Elsa a balloon? She'll let it go."}
		{"What kind of music do planets like? Neptunes."}
		{"What did one hat say to the other? You stay here. I'll go on ahead."}
		{"Why is Peter Pan always flying? He neverlands."}
		{"How do you follow a book? You track their footnotes."}
		{"What's the biggest problem with snow boots? They melt."}
		{"What tree can fit in your hand? A palm tree."}
		{"Why are astronauts so clean? They take meteor showers."}
		{"Why are ghosts bad liars? They're totally see through."}
		{"Why did the bike fall over? It was two tired."}
		{"Where can you buy soup in bulk? The stock market."}
		{"What's brown and sticky? A stick."}
		{"Why do bees have sticky hair? They use honeycombs."}
		{"Sea monsters have been known to eat what? Fish and ships."}
		{"What do you call a vicar who becomes a lawyer? A father-in-law."}
		{"What kind of cheese doesn't belong to you? Nacho cheese."}
		{"How did the phone propose to his girlfriend? He gave her a ring."}
		{"Which month of the year has 28 days? Um all of them."}
		{"Why was the broom late to work? It over-swept."}
		{"What does a pig use in the shower? Hog wash."}
		{"So why don't ants get sick? They have anty-bodies."}
		{"What did the drummer call his daughters? Anna 1, Anna 2."}
		{"Why do computers overheat? They need to vent."}
}

if {![string match "*time_speaks*" [timers]]} {
  timer $speaks_time time_speaks
}

proc time_speaks {} {
  global speaks_msg speaks_chans speaks_time
  if {$speaks_chans == "*"} {
    set speaks_temp [channels]
    } else {
    set speaks_temp $speaks_chans
  }
  foreach chan $speaks_temp {
    set speaks_rmsg [lindex $speaks_msg [rand [llength $speaks_msg]]]
    foreach msgline $speaks_rmsg {
      puthelp "PRIVMSG $chan :[subst $msgline]"
    }
  }
  if {![string match "*time_speaks*" [timers]]} {
    timer $speaks_time time_speaks
  }
}



##  PING PONG ##
set Reponden2.v "Ping Respon"
bind pub - "rakia" ping_speak 
bind pub - "rakiq" ping_speak
bind pub - "bira" ping_speak
bind pub - "biri" ping_speak
bind pub - "piem" ping_speak
bind pub - "vodka" ping_speak
bind pub - "vodki" ping_speak
bind pub - "piq" ping_speak

set ranping {
  "Mabilis kang matuto.??? -ha Bagay sa 'yo 'yan.:o)))"
  "Ang ganda ng ngiti mo....  ouuuu...!!! -a Masipag ka at mahusay.:o)))"
  "vodka vodka...  ouuuu...!!! -a Gusto ko 'yang sinabi mo. :o)))"
  "Ipagpatuloy mo lang 'yan. 
  "Da best ka talaga!"
  "Ang sarap mong magluto.
  "Mapagkakatiwalaan ka talaga. :)))"
  "Ang bait mo talaga. - Cute ka.
  "Mukhang maganda 'yan... :)))"
  "Ang sarap mong kasama.
  "Nakakabilib ang tyaga mo.
  "Nakakabilib ka. ;o)"
  "Maganda ka.
  "aee... Pakiabot ng ulam. :)))"
  "Anong gusto mong inumin?"
  "Umorder ka kahit ano. Sagot ko...mmmm"
}

proc ping_speak {nick uhost hand chan text} {
  global botnick ping_chans ranping
  if {(([lsearch -exact [string tolower $ping_chans] [string tolower $chan]] != -1) || ($ping_chans == "*"))} {
    set pings [lindex $ranping [rand [llength $ranping]]]
    putserv "PRIVMSG $chan :$nick $pings"
  }
} 

##  hello ##
set Reponden3.v "hello Respon"
bind pub - "hello" hello_speak 
bind pub - "alo" hello_speak 
bind pub - "zdr" hello_speak 
bind pub - "hai" hello_speak 
bind pub - "hi" hello_speak 

set ranhello {
  "Mabuhay!"
  "Magandang araw ^_^"
  "Magandang umaga"
  "helooooooooo"
  "Kumusta ka naman?"
  "Musta na u?"
  "Anong bago?"
  "Hi there"
  ":) Tagal na nating hindi nagkita!"
  "Ayos lang.  
  "yeah, yeah hi HI"
  "Walang ano man!!!"
  "Ingat!"
  "hi asl pls?"
  "how do you do? i'm happy to meet you"
  "Taga saan ka??"
  "Saan ka pupunta? ?"
  "Saan ito papunta?"
  "Uwi na ako :>>"
  "Paalam ?"
  "Sa uulitin! _!_"
}

proc hello_speak {nick uhost hand chan text} {
  global botnick hello_chans ranhello
  if {(([lsearch -exact [string tolower $hello_chans] [string tolower $chan]] != -1) || ($hello_chans == "*"))} {
    set helos [lindex $ranhello [rand [llength $ranhello]]]
    putserv "PRIVMSG $chan :$nick $helos"
  }
} 

##  Brb  ##
set Reponden4.v "Brb Respon"
bind pub - "brb" brb_speak 
set ranbrb {
  "Magkano ang pamasahe?"
  "Hindi ko alam!?"
  "Pabili po!"
  "Magkano lahat?! ;)"
  "Pwede pong tumawad?"
}

proc brb_speak {nick uhost hand chan text} {
  global botnick brb_chans ranbrb
  if {(([lsearch -exact [string tolower $brb_chans] [string tolower $chan]] != -1) || ($brb_chans == "*"))} {
    set brbs [lindex $ranbrb [rand [llength $ranbrb]]]
    putserv "PRIVMSG $chan :$nick $brbs"
  }
} 

##  Bye  ##
set Reponden5.v "Bye respon"
bind pub - "bye" bye_speak 
bind pub - "4ao" bye_speak 
bind pub - "chao" bye_speak 
set ranbye {
  "Gutom na ako!"
  "oki bye:-):P~~ Gusto ko nang kumain!"
  "oki bye:-):P~~ Masarap!"
  "ok Kain ka pa! :)"
  "good bye.. Busog na ako! :)"
  "Ayaw ko na.
  "Wala na akong gana.
  "Magdasal tayo!"
  "Saan ako pwedeng umupo?:PPP~~~~~"
  "Bahala ka na! ?:)))"
  "Gusto kitang makasama habang buhay.:-)"
  "Walang iba, ikaw lang.:-)))"
  "Andito ako lagi para sa 'yo. sq:P~~"
  "eee Ikaw ang mundo ko. :-)"
  "Binago mo ang buhay ko. :))"
  "Pinagaganda mo ang araw ko.
  "mahai sa ma ufca"
  "In love ako sa 'yo"
  "fiiiiuuuuuu----... Mahal na mahal kita.
}

proc bye_speak {nick uhost hand chan text} {
  global botnick bye_chans ranbye
  if {(([lsearch -exact [string tolower $bye_chans] [string tolower $chan]] != -1) || ($bye_chans == "*"))} {
    set byes [lindex $ranbye [rand [llength $ranbye]]]
    putserv "PRIVMSG $chan : $nick $byes"
  }
} 


## -----------------------------------------------------------------------
#putlog "-=-=   ENTERTAINMENT  PROSES   =-=-=-=-=-"
#putlog "Entertainment Channel (auto/respon) Ver 1.0:"
#putlog "1.${spoken.v},2.${Reponden2.v},3.${Reponden3.v}"
#putlog "4.${Reponden4.v},5.${Reponden5.v}"
putlog "AutoTalk bY dJ_TEDY Loaded. \002[join $speaks_chans ", "]\002"
##------------------------------------------------------------------------
##                      ***    E N D   OF  ENT1.0.TCL ***
## -----------------------------------------------------------------------
