# What
_\_HC1WDN4Sbot_ is a chat bot for Skype built on Lua and Skype4COM interface. This bot is made with extensibility in mind and thus can be extended with different functionality on the fly. I made this bot primarily to improve my programming skills and to see what I can do with Skype. On its own bot doesn't do much. All actual functionality of the bot lies in modules.

# How to use
Using the bot itself is quite trivial:
  - To call a command simply write _!commandname_ in the chat.
  - List of commands with descriptions (_that aren't written yet, sorry_) available via _!help_.
Everything else depend on modules.

Due to Microsoft being not very good bunch of people they are, adding bot to your group chat isn't as trivial:
  - In order for bot to work, your group chat has to be a p2p chat. Type _/get name_ into your chat. If your chat name starts with _\#skypename_ then skip the next step.
  - If your chat name starts with _19:_ then you have to create a new p2p group chat. To do that type _/createmoderatedchat_. This will create a new group chat with only you in it.
  - Now you can add the bot to your group. If you have your own instance of bot running add account that associated with that instance, otherwise add my instance hosted on _\_HC1WDN4Sbot_ Skype account.
  
If you want to host your own instance of bot:
  Currently _\_HC1WDN4Sbot_ available only on Windows due to reliance on COM interface. If you know how to get the bot to work on other systems let me know.
  
  - Get dependencies:
  
    - Lua 5.1.4
    - LuaCOM 1.4
    - Lua CJSON 2.1.0 (or analog)
    - Compat53
    - LuaLogging 1.2.0
    - LuaFileSystem 1.4.2
    
  Put them somewhere in LUA_(C)PATH or in lib (for compiled libraries) or lua (for libraries in Lua files) folders in main folder.
  You can get all of them with exception of Compat53 in a convenient package called [LuaForWindows](https://github.com/rjpcomputing/luaforwindows).

  - Start and Login into Skype instance. It is possible to have more than one Skype instance running on one system, but it is unclear which one bot will pick. I recommend to run bot on a separate system (either VM or dedicated server is your choice).

  - Launch bot by either double-clicking _main.lua_ or typing _lua main.lua_ in console.

  - After that you can shutdown bot and edit configs or just let it run on defaults.

# API documentation
_Coming soon._
  
# Misc.
If you have any questions or concerns feel free to contact me.