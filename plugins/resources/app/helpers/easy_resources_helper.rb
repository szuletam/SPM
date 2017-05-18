module EasyResourcesHelper

  def easy_resources_js_button(text, options={})
    if text.is_a?(Symbol)
      text = l(text, :scope => [:easy_resources, :button])
      options[:title] ||= l(text, :scope => [:easy_resources, :title], :default => text)
    end
    options[:class] = "gantt_button #{options[:class]}"
    options[:class] << ' button button-2' unless options.delete(:no_button)
    if (icon = options.delete(:icon))
      options[:class] << " icon #{icon}"
    end
    link_to(text, options[:url] || 'javascript:void(0)', options)
  end

  def easy_resources_help_button(*args)
    options = args.extract_options!
    feature = args.shift
    text = args.shift

    options[:class] = "gantt-help-button #{options[:class]}"
    options[:icon] ||= 'icon-help'
    options[:id] = feature.to_s + '_help'
    easy_resources_js_button(text || '&#8203;'.html_safe, options) + %Q(
    <div id="#{feature}_help_modal" style="display:none">
      <h3 class="title">#{raw l(:heading, :scope => [:easy_resources, :popup, feature]) }</h3>
      <p>#{raw l(:text, :scope => [:easy_resources, :popup, feature]) }</p>
     </div>
    ).html_safe
  end
end
