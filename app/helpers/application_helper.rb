# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def text_parser(text)
    #pat=/user:"([a-zA-Z0-9_]+)"/i
    #refs=pat.match(text)
    #text.sub(,'<img border="0" width="12" src="/images/icon.png" height="12"/> <a href="/users/iron">\1</a>  </span>')
    #logger.info(refs.to_a.inspect)
    #text=text.gsub(/user:"([a-zA-Z0-9_]+)"/i,'<span class="user"><img border="0" width="12" src="/images/icon.png" height="12"/> <a href="/users/\1">\1</a>  </span>')
    text=RedCloth.new(text).to_html
    return text
  end
end
