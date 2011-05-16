# Only load the SASS processor if we're an application. If we're an engine,
# the css is already generated and packaged. Leave everything else up to the
# front-end application (which may or may not use SASS)
if defined?( Braincube::Application )
  Sass::Plugin.options[:syntax] = :sass
  Sass::Plugin.options[:template_location] = File.join(Rails.root, 'app', 'sass')
  Sass::Plugin.options[:style] = Rails.env=="development" ? :expanded : :compressed
end