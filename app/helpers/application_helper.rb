module ApplicationHelper
  include Pagy::Frontend

  def pagy_custom_nav(pagy)
    return "" unless pagy.pages > 1

    html = +%(<nav class="flex justify-center mt-8"><div class="flex items-center gap-2">)

    if pagy.prev
      html << link_to(raw("&laquo; Prev"), url_for(page: pagy.prev), class: "px-3 py-2 text-sm rounded-lg border border-gray-700 text-gray-300 hover:border-gold hover:text-gold transition-colors")
    end

    pagy.series.each do |item|
      case item
      when Integer
        html << link_to(item.to_s, url_for(page: item), class: "px-3 py-2 text-sm rounded-lg border border-gray-700 text-gray-300 hover:border-gold hover:text-gold transition-colors")
      when String
        html << %(<span class="px-3 py-2 text-sm rounded-lg bg-gold text-gray-950 font-semibold">#{item}</span>)
      when :gap
        html << %(<span class="px-2 py-2 text-gray-500">&hellip;</span>)
      end
    end

    if pagy.next
      html << link_to(raw("Next &raquo;"), url_for(page: pagy.next), class: "px-3 py-2 text-sm rounded-lg border border-gray-700 text-gray-300 hover:border-gold hover:text-gold transition-colors")
    end

    html << %(</div></nav>)
    html.html_safe
  end
end
