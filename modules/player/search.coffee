options = ['🇦','🇧', '🇨','🇩','🇪','🇫','🇬','🇭','🇮','🇯']

class PlayerSearch
  constructor: (@playerModule)->
    { @util } = @playerModule
    @pending = {}

  doSearch: (msg, l, query)->
    @pending[msg.id] = search = { msg, query, l }
    search.results = await @util.getInfo("ytsearch10:#{query}")
    if search.results.partial
      await @updateResults(msg.id)
      search.results.on('video', => @updateResults(msg.id))
      search.results.on('done', => @updateResults(msg.id))
      r = await search.rmsg.awaitReactions (r, u) =>
        r.emoji.name in options and u.id is msg.author.id
      , max: 1
      try await search.rmsg.delete()
      delete @pending[msg.id]
      video = search.results.items[options.indexOf(r.first().emoji.name)]
      # Make sure the video exists
      throw new Error(l.generic.error) unless video
      return video
    else
      delete @pending[msg.id]
      return search.results.items[0]

  updateResults: (id)->
    return unless @pending[id]
    { l, results, rmsg } = @pending[id]
    embed =
      author:
        name: if results.partial then l.player.hud.searching else l.player.hud.results
        icon_url: if results.partial then 'https://d.thebitlink.com/wheel.gif'
      description: ''
    for item, i in results.items
      embed.description += "#{options[i]} [#{item.title.replace(/\]/, '\\]')}]"
      embed.description += "(#{item.webpage_url.replace(/\]/, '\\]')})"
      embed.description += " (#{@util.displayTime item.duration})\n"
      if rmsg then try await rmsg.react(options[i])
    if rmsg then try
      await rmsg.edit('', { embed })
      return rmsg
    else try
      return @pending[id].rmsg = await @pending[id].msg.channel.send '', { embed }

module.exports = PlayerSearch
